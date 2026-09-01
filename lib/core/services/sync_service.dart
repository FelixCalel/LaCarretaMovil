import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../network/api_client.dart';
import '../services/logger_service.dart';
import '../database/app_database.dart';
import '../../features/pedidos/data/pedidos_local_datasource.dart';
import '../../features/pedidos/domain/catalog_models.dart';
import '../../features/pedidos/domain/pedido_model.dart';

enum SyncStatus { idle, syncing, success, error }

class SyncResult {
  final int syncedMutations;
  final int failedMutations;
  final String? error;

  SyncResult({
    this.syncedMutations = 0,
    this.failedMutations = 0,
    this.error,
  });
}

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final _apiClient = ApiClient();
  final _localDs = PedidosLocalDatasource(appDb: AppDatabase());
  
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  final _syncStatusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  DateTime? _lastCatalogSync;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  void initAutoSyncListener() {
    _connectivitySub?.cancel();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection = !results.contains(ConnectivityResult.none);
      if (hasConnection && !_isSyncing) {
        Log.i('[AUTO-SYNC] Conexión a Internet detectada. Iniciando sincronización...');
        syncAll(silent: false);
      }
    });
    Log.i('[AUTO-SYNC] Listener de sincronización automática inicializado.');
  }

  void dispose() {
    _connectivitySub?.cancel();
    _syncStatusController.close();
  }

  Future<SyncResult> syncAll({bool silent = false, bool forceCatalogs = false}) async {
    if (_isSyncing) {
      Log.i('[SYNC] Sincronización ya en curso. Omitiendo.');
      return SyncResult();
    }

    final conn = await Connectivity().checkConnectivity();
    if (conn.contains(ConnectivityResult.none)) {
      Log.i('[SYNC] Sin conexión a Internet. Sincronización cancelada.');
      return SyncResult(error: 'Sin conexión a Internet');
    }

    _isSyncing = true;
    _syncStatusController.add(SyncStatus.syncing);

    int successCount = 0;
    int errorCount = 0;

    try {
      Log.i('================ INICIANDO SINCRONIZACIÓN OFFLINE ================');

      // 1. Vaciar cola de mutaciones offline (sync_queue)
      final pendingQueue = await _localDs.getPendingSyncItems();
      Log.i('[SYNC] Ítems pendientes en cola: ${pendingQueue.length}');

      for (final item in pendingQueue) {
        final queueId = item['id'] as int;
        final action = item['action'] as String;
        final endpoint = item['endpoint'] as String;
        final payload = jsonDecode(item['payload_json'] as String) as Map<String, dynamic>;

        try {
          if (action == 'CREATE_PEDIDO') {
            final tempId = payload['tempId'] as int;
            final cleanData = Map<String, dynamic>.from(payload)..remove('tempId');

            final response = await _apiClient.dio.post(endpoint, data: cleanData);
            final realId = response.data['id'] as int;

            await _localDs.markSyncItemCompleted(queueId, tempId, realId);
            successCount++;
          } else if (action == 'REALIZAR_PEDIDO') {
            await _apiClient.dio.patch(endpoint, data: payload);
            final db = await AppDatabase().database;
            await db.delete('sync_queue', where: 'id = ?', whereArgs: [queueId]);
            successCount++;
          } else if (action == 'DELETE_PEDIDO') {
            try {
              await _apiClient.dio.delete(endpoint);
            } catch (_) {}
            final db = await AppDatabase().database;
            await db.delete('sync_queue', where: 'id = ?', whereArgs: [queueId]);
            successCount++;
          } else if (action == 'UPDATE_QTY') {
            await _apiClient.dio.put(endpoint, data: {'cantidad': payload['cantidad']});
            final db = await AppDatabase().database;
            await db.delete('sync_queue', where: 'id = ?', whereArgs: [queueId]);
            successCount++;
          } else if (action == 'DELETE_ITEM') {
            try {
              await _apiClient.dio.delete(endpoint);
            } catch (_) {}
            final db = await AppDatabase().database;
            await db.delete('sync_queue', where: 'id = ?', whereArgs: [queueId]);
            successCount++;
          } else if (action == 'ADD_ITEM') {
            await _apiClient.dio.post(endpoint, data: payload);
            final db = await AppDatabase().database;
            await db.delete('sync_queue', where: 'id = ?', whereArgs: [queueId]);
            successCount++;
          }
        } catch (itemErr) {
          Log.e('[SYNC-ERROR] Error procesando ítem $queueId', itemErr);
          await _localDs.markSyncItemFailed(queueId, itemErr.toString());
          errorCount++;
        }
      }

      // 2. Descargar y actualizar catálogos (con TTL de 30 minutos)
      final shouldSyncCatalogs = forceCatalogs ||
          _lastCatalogSync == null ||
          DateTime.now().difference(_lastCatalogSync!).inMinutes >= 30;

      if (shouldSyncCatalogs) {
        await _syncCatalogs();
        _lastCatalogSync = DateTime.now();
      } else {
        Log.i('[SYNC-CATALOGS] Catálogos vigentes en SQLite (TTL < 30 min).');
      }

      // 3. Descargar y actualizar listado de pedidos y detalles
      await _syncPedidos();

      Log.i('================ SINCRONIZACIÓN FINALIZADA CON ÉXITO ================');
      _syncStatusController.add(SyncStatus.success);
      return SyncResult(syncedMutations: successCount, failedMutations: errorCount);
    } catch (e) {
      Log.e('[SYNC-CRITICAL] Error en proceso de sincronización general', e);
      _syncStatusController.add(SyncStatus.error);
      return SyncResult(syncedMutations: successCount, failedMutations: errorCount, error: e.toString());
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncCatalogs() async {
    try {
      final results = await Future.wait([
        _apiClient.dio.get('/ciudad/todos'),
        _apiClient.dio.get('/deus/todos'),
        _apiClient.dio.get('/tienda/todos'),
      ]);

      final ciudades = (results[0].data as List<dynamic>)
          .map((j) => CatalogCiudad.fromJson(j))
          .toList();
      final deudores = (results[1].data as List<dynamic>)
          .map((j) => CatalogDeudor.fromJson(j))
          .toList();
      final tiendas = (results[2].data as List<dynamic>)
          .map((j) => CatalogTienda.fromJson(j))
          .toList();

      await Future.wait([
        _localDs.saveCiudades(ciudades),
        _localDs.saveDeudores(deudores),
        _localDs.saveTiendas(tiendas),
      ]);

      Log.i('[SYNC-CATALOGS] Catálogos base (ciudades, clientes, tiendas) actualizados en SQLite.');
    } catch (e) {
      Log.e('[SYNC-CATALOGS] Error al descargar catálogos', e);
    }
  }

  Future<void> _syncPedidos() async {
    try {
      final response = await _apiClient.dio.get('/form/pedidos/todos');
      final List<dynamic> data = response.data;
      final pedidos = data.map((json) => PedidoModel.fromJson(json)).toList();
      await _localDs.savePedidos(pedidos);
      Log.i('[SYNC-PEDIDOS] ${pedidos.length} pedidos actualizados en SQLite.');
    } catch (e) {
      Log.e('[SYNC-PEDIDOS] Error al descargar pedidos del backend', e);
    }
  }
}

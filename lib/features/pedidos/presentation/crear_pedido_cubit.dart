import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/services/notification_service.dart';
import '../data/pedidos_datasource.dart';
import '../domain/detalle_model.dart';
import '../domain/producto_model.dart';
import 'crear_pedido_state.dart';

class CrearPedidoCubit extends Cubit<CrearPedidoState> {
  final PedidosDatasource datasource;
  final _storage = const FlutterSecureStorage();
  StreamSubscription<Map<String, dynamic>>? _wsSubscription;

  CrearPedidoCubit({required this.datasource}) : super(const CrearPedidoState()) {
    _listenToWS();
  }

  void _listenToWS() {
    _wsSubscription = NotificationService().wsEvents.listen((event) {
      try {
        final type = event['type'];
        final payload = event['payload'];
        if (type == 'on-order-status-changed') {
          loadData();
        } else if (type == 'order-detail-changed') {
          if (payload != null) {
            final pedidoIdRaw = payload['pedidoId'];
            final pedidoId = pedidoIdRaw is int ? pedidoIdRaw : int.tryParse(pedidoIdRaw?.toString() ?? '');
            if (pedidoId != null) {
              final isExpanded = state.expandedPedidos[pedidoId] ?? false;
              if (isExpanded) {
                try {
                  final pedido = state.draftPedidos.firstWhere((p) => p.id == pedidoId);
                  loadPedidoDetails(pedidoId, pedido.deudorId, isSilent: true);
                } catch (_) {}
              }
            }
          }
        }
      } catch (e) {
        // Safe catch for parsing/stream issues
      }
    });
  }

  Future<void> loadData() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final userIdStr = await _storage.read(key: 'user_id');
      final userId = int.tryParse(userIdStr ?? '') ?? 0;

      final allPedidos = await datasource.getPedidos();
      final draftPedidos = allPedidos.where((p) => p.estadoId == 1 && p.deudorId != 0 && p.usuarioId == userId).toList();

      final ciudades = await datasource.getCiudades();
      final deudores = await datasource.getDeudores();
      final tiendas = await datasource.getTiendas();

      List<int> userRoutes = [];
      int userPaisId = 0;
      try {
        final meResponse = await datasource.apiClient.dio.get('/login/me');
        final data = meResponse.data;
        if (data != null) {
          final userJson = data['user'] ?? data['usuario'] ?? data;
          final rutas = userJson['rutas'] as List<dynamic>? ?? [];
          userRoutes = rutas.map((r) => int.tryParse(r['id']?.toString() ?? '') ?? 0).where((id) => id != 0).toList();
          userPaisId = int.tryParse(userJson['paisId']?.toString() ?? '') ?? 0;
          
          await _storage.write(key: 'user_routes', value: userRoutes.join(','));
          await _storage.write(key: 'user_pais_id', value: userPaisId.toString());
        }
      } catch (_) {
        final userRoutesStr = await _storage.read(key: 'user_routes') ?? '';
        userRoutes = userRoutesStr.split(',')
            .map((id) => int.tryParse(id) ?? 0)
            .where((id) => id != 0)
            .toList();

        final userPaisIdStr = await _storage.read(key: 'user_pais_id');
        userPaisId = int.tryParse(userPaisIdStr ?? '') ?? 0;
      }

      emit(state.copyWith(
        draftPedidos: draftPedidos,
        ciudades: ciudades,
        deudores: deudores,
        tiendas: tiendas,
        userRoutes: userRoutes,
        userPaisId: userPaisId,
      ));

      for (var p in draftPedidos) {
        if (state.expandedPedidos[p.id] == true) {
          await loadPedidoDetails(p.id, p.deudorId);
        }
      }
    } catch (e) {
      emit(state.copyWith(error: 'Error al cargar datos: $e'));
    } finally {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> loadPedidoDetails(int pedidoId, int deudorId, {bool isSilent = false}) async {
    if (!isSilent) {
      final loading = Map<int, bool>.from(state.loadingDetails);
      loading[pedidoId] = true;
      emit(state.copyWith(loadingDetails: loading));
    }

    try {
      final detalles = await datasource.getPedidoDetalles(pedidoId)
        ..sort((a, b) => a.productoNombre.toLowerCase().compareTo(b.productoNombre.toLowerCase()));
      final pedidoDetalles = Map<int, List<DetalleModel>>.from(state.pedidoDetalles);
      pedidoDetalles[pedidoId] = detalles;

      final deudorProductos = Map<int, List<ProductoModel>>.from(state.deudorProductos);
      if (!deudorProductos.containsKey(deudorId)) {
        deudorProductos[deudorId] = await datasource.getDeudorProductos(deudorId);
      }

      emit(state.copyWith(
        pedidoDetalles: pedidoDetalles,
        deudorProductos: deudorProductos,
      ));
    } catch (e) {
      emit(state.copyWith(error: 'Error cargando detalles del pedido $pedidoId: $e'));
    } finally {
      if (!isSilent) {
        final newLoading = Map<int, bool>.from(state.loadingDetails);
        newLoading[pedidoId] = false;
        emit(state.copyWith(loadingDetails: newLoading));
      }
    }
  }

  Future<void> toggleExpand(int pedidoId, int deudorId) async {
    final isExpanded = state.expandedPedidos[pedidoId] ?? false;
    final expanded = Map<int, bool>.from(state.expandedPedidos);
    expanded[pedidoId] = !isExpanded;
    emit(state.copyWith(expandedPedidos: expanded));

    if (!isExpanded && !state.pedidoDetalles.containsKey(pedidoId)) {
      await loadPedidoDetails(pedidoId, deudorId);
    }
  }

  Future<void> updateItemQuantity(int pedidoId, DetalleModel detail, int newQty) async {
    if (newQty < 1) return;

    // Optimistic Update
    final detailsMap = Map<int, List<DetalleModel>>.from(state.pedidoDetalles);
    final detailsList = detailsMap[pedidoId];
    if (detailsList != null) {
      final index = detailsList.indexWhere((d) => d.id == detail.id);
      if (index != -1) {
        final newList = List<DetalleModel>.from(detailsList);
        newList[index] = detail.copyWith(cantidad: newQty);
        detailsMap[pedidoId] = newList;
        emit(state.copyWith(pedidoDetalles: detailsMap));
      }
    }

    try {
      await datasource.updateItemQuantity(pedidoId, detail.id, newQty);
    } catch (e) {
      // Revertir recargando desde API
      await loadPedidoDetails(pedidoId, detail.pedidoId);
      emit(state.copyWith(error: 'Error al actualizar cantidad: $e'));
    }
  }

  Future<void> deleteItem(int pedidoId, DetalleModel detail) async {
    // Optimistic Update
    final detailsMap = Map<int, List<DetalleModel>>.from(state.pedidoDetalles);
    final detailsList = detailsMap[pedidoId];
    if (detailsList != null) {
      final newList = List<DetalleModel>.from(detailsList)..removeWhere((d) => d.id == detail.id);
      detailsMap[pedidoId] = newList;
      emit(state.copyWith(pedidoDetalles: detailsMap));
    }

    try {
      await datasource.deleteItem(detail.id);
      await loadPedidoDetails(pedidoId, detail.pedidoId, isSilent: true);
    } catch (e) {
      // Revertir recargando desde API
      await loadPedidoDetails(pedidoId, detail.pedidoId);
      emit(state.copyWith(error: 'Error al eliminar producto: $e'));
    }
  }

  void selectProduct(int pedidoId, int? productId) {
    final selected = Map<int, int?>.from(state.selectedProductForPedido);
    selected[pedidoId] = productId;
    emit(state.copyWith(selectedProductForPedido: selected));
  }

  Future<void> addItemToPedido(int pedidoId, int deudorId, int qty) async {
    final prodId = state.selectedProductForPedido[pedidoId];
    if (prodId == null) {
      emit(state.copyWith(error: 'Seleccione un producto'));
      return;
    }

    try {
      final userIdStr = await _storage.read(key: 'user_id');
      final userId = int.tryParse(userIdStr ?? '') ?? 0;

      await datasource.addItemToPedido(
        pedidoId: pedidoId,
        productoId: prodId,
        cantidad: qty,
        userId: userId,
      );

      selectProduct(pedidoId, null);
      await loadPedidoDetails(pedidoId, deudorId, isSilent: true);
    } catch (e) {
      emit(state.copyWith(error: 'Error al agregar producto: $e'));
    }
  }

  Future<void> deletePedido(int pedidoId) async {
    try {
      await datasource.deletePedido(pedidoId);
      emit(state.copyWith(successMessage: 'Borrador eliminado correctamente'));
      await loadData();
    } catch (e) {
      emit(state.copyWith(error: 'Error al eliminar borrador: $e'));
    }
  }

  Future<void> realizarPedido(int pedidoId, String comentario, String fecha) async {
    final details = state.pedidoDetalles[pedidoId] ?? [];
    if (details.isEmpty) {
      emit(state.copyWith(error: 'Agregue productos al pedido antes de realizarlo'));
      return;
    }

    try {
      final userIdStr = await _storage.read(key: 'user_id');
      final userId = int.tryParse(userIdStr ?? '') ?? 0;

      await datasource.realizarPedido(
        pedidoId: pedidoId,
        comentario: comentario,
        fecha: fecha,
        userId: userId,
      );

      emit(state.copyWith(successMessage: 'Pedido realizado exitosamente'));
      await loadData();
    } catch (e) {
      emit(state.copyWith(error: 'Error al procesar pedido: $e'));
    }
  }

  Future<void> createPedido({
    required int ciudadId,
    required int deudorId,
    required int tiendaId,
  }) async {
    emit(state.copyWith(isLoading: true));
    try {
      final userIdStr = await _storage.read(key: 'user_id');
      final userId = int.tryParse(userIdStr ?? '') ?? 0;

      final newPedido = await datasource.createPedido(
        deudorId: deudorId,
        tiendaId: tiendaId,
        ciudadId: ciudadId,
        usuarioId: userId,
      );
      
      // Auto-populate items with quantity 0 for the new order
      await datasource.populatePedidoModelo(
        deudorId: deudorId,
        pedidoId: newPedido.id,
        tiendaId: tiendaId,
      );
      
      emit(state.copyWith(successMessage: 'Borrador creado correctamente'));
      await loadData();
    } catch (e) {
      emit(state.copyWith(error: 'Error al crear borrador: $e'));
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> copiarUltimoPedido({
    required int ciudadId,
    required int deudorId,
    required int tiendaId,
  }) async {
    emit(state.copyWith(isLoading: true));
    try {
      final userIdStr = await _storage.read(key: 'user_id');
      final userId = int.tryParse(userIdStr ?? '') ?? 0;

      await datasource.copiarUltimoPedido(
        deudorId: deudorId,
        tiendaId: tiendaId,
        ciudadId: ciudadId,
        usuarioId: userId,
      );
      
      emit(state.copyWith(successMessage: 'Borrador copiado correctamente del último pedido'));
      await loadData();
    } catch (e) {
      emit(state.copyWith(error: 'Error al copiar borrador: $e'));
      emit(state.copyWith(isLoading: false));
    }
  }

  void clearError() {
    emit(state.copyWith(clearError: true));
  }

  void clearSuccess() {
    emit(state.copyWith(clearSuccess: true));
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    return super.close();
  }
}

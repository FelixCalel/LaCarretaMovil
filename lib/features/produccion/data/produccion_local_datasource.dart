import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/logger_service.dart';
import '../domain/produccion_model.dart';

class ProduccionLocalDatasource {
  final AppDatabase appDb;

  ProduccionLocalDatasource({AppDatabase? appDb})
      : appDb = appDb ?? AppDatabase();

  // ==========================================
  // CACHE: PEDIDOS AGRUPADOS POR ETAPA
  // ==========================================

  Future<void> savePedidosAgrupados({
    required int etapaId,
    required List<PedidoAgrupadoModel> list,
  }) async {
    try {
      final db = await appDb.database;
      await db.transaction((txn) async {
        await txn.delete(
          'produccion_grupos_local',
          where: 'etapa_id = ?',
          whereArgs: [etapaId],
        );

        final now = DateTime.now().toIso8601String();
        for (final item in list) {
          await txn.insert('produccion_grupos_local', {
            'etapa_id': etapaId,
            'id_grupo': item.pedidoId,
            'nombre_grupo': '${item.deudorNombre} - ${item.tienda}',
            'raw_json': jsonEncode(item.toJson()),
            'updated_at': now,
          });
        }
      });
      Log.i('[OFFLINE-PROD] Guardados ${list.length} grupos para etapa $etapaId');
    } catch (e) {
      Log.e('[OFFLINE-PROD] Error al guardar pedidos agrupados en SQLite', e);
    }
  }

  Future<List<PedidoAgrupadoModel>> getPedidosAgrupados({
    required int etapaId,
  }) async {
    try {
      final db = await appDb.database;
      final rows = await db.query(
        'produccion_grupos_local',
        where: 'etapa_id = ?',
        whereArgs: [etapaId],
        orderBy: 'id ASC',
      );

      final list = <PedidoAgrupadoModel>[];
      for (final r in rows) {
        final raw = r['raw_json'] as String?;
        if (raw != null && raw.isNotEmpty) {
          try {
            final json = jsonDecode(raw) as Map<String, dynamic>;
            list.add(PedidoAgrupadoModel.fromJson(json));
          } catch (e) {
            Log.w('[OFFLINE-PROD] Error decodificando grupo en SQLite', e);
          }
        }
      }
      return list;
    } catch (e) {
      Log.e('[OFFLINE-PROD] Error al leer pedidos agrupados desde SQLite', e);
      return [];
    }
  }

  // ==========================================
  // CACHE: RECETAS POR PEDIDO
  // ==========================================

  Future<void> saveRecetaByPedido({
    required int pedidoId,
    int? idAlmacen,
    required List<RecetaLineaModel> lineas,
  }) async {
    try {
      final db = await appDb.database;
      await db.delete(
        'produccion_recetas_local',
        where: 'pedido_id = ?',
        whereArgs: [pedidoId],
      );

      final now = DateTime.now().toIso8601String();
      await db.insert('produccion_recetas_local', {
        'pedido_id': pedidoId,
        'id_almacen': idAlmacen,
        'raw_json': jsonEncode(lineas.map((l) => l.toJson()).toList()),
        'updated_at': now,
      });
    } catch (e) {
      Log.e('[OFFLINE-PROD] Error al guardar receta en SQLite', e);
    }
  }

  Future<List<RecetaLineaModel>> getRecetaByPedido(
    int pedidoId, {
    int? idAlmacen,
  }) async {
    try {
      final db = await appDb.database;
      final rows = await db.query(
        'produccion_recetas_local',
        where: 'pedido_id = ?',
        whereArgs: [pedidoId],
        limit: 1,
      );

      if (rows.isNotEmpty) {
        final raw = rows.first['raw_json'] as String?;
        if (raw != null && raw.isNotEmpty) {
          final listJson = jsonDecode(raw) as List<dynamic>;
          return listJson
              .map((j) => RecetaLineaModel.fromJson(j as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      Log.e('[OFFLINE-PROD] Error al leer receta desde SQLite', e);
      return [];
    }
  }

  // ==========================================
  // CACHE: ALMACENES
  // ==========================================

  Future<void> saveAlmacenes(List<AlmacenModel> almacenes) async {
    try {
      final db = await appDb.database;
      final batch = db.batch();
      final now = DateTime.now().toIso8601String();

      for (final a in almacenes) {
        batch.insert('catalog_almacenes', {
          'id': a.id,
          'nombre': a.nombre,
          'state': 1,
          'raw_json': jsonEncode(a.toJson()),
          'updated_at': now,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    } catch (e) {
      Log.e('[OFFLINE-PROD] Error al guardar almacenes en SQLite', e);
    }
  }

  Future<List<AlmacenModel>> getAlmacenes() async {
    try {
      final db = await appDb.database;
      final rows = await db.query('catalog_almacenes', where: 'state = 1');
      final list = rows.map((r) => AlmacenModel(
            id: r['id'] as int,
            nombre: r['nombre'] as String,
          )).toList();
      list.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
      return list;
    } catch (e) {
      Log.e('[OFFLINE-PROD] Error al leer almacenes desde SQLite', e);
      return [];
    }
  }

  // ==========================================
  // CACHE: MESAS ACTIVAS ASIGNADAS
  // ==========================================

  Future<void> saveActiveMesaAssignments(List<MesaActivaAsignadaModel> mesas) async {
    try {
      final db = await appDb.database;
      await db.delete('produccion_mesas_activas_local');
      final now = DateTime.now().toIso8601String();

      await db.insert('produccion_mesas_activas_local', {
        'raw_json': jsonEncode(mesas.map((m) => m.toJson()).toList()),
        'updated_at': now,
      });
    } catch (e) {
      Log.e('[OFFLINE-PROD] Error al guardar mesas activas en SQLite', e);
    }
  }

  Future<List<MesaActivaAsignadaModel>> getActiveMesaAssignments() async {
    try {
      final db = await appDb.database;
      final rows = await db.query('produccion_mesas_activas_local', limit: 1);
      if (rows.isNotEmpty) {
        final raw = rows.first['raw_json'] as String?;
        if (raw != null && raw.isNotEmpty) {
          final listJson = jsonDecode(raw) as List<dynamic>;
          return listJson
              .map((j) => MesaActivaAsignadaModel.fromJson(j as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      Log.e('[OFFLINE-PROD] Error al leer mesas activas desde SQLite', e);
      return [];
    }
  }

  // ==========================================
  // CACHE: CONTEO SIN ASIGNAR
  // ==========================================

  Future<void> saveUnassignedCount(int count) async {
    try {
      final db = await appDb.database;
      await db.insert('produccion_metadata_local', {
        'key': 'unassigned_count',
        'value': count.toString(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      Log.w('[OFFLINE-PROD] Error al guardar conteo sin asignar', e);
    }
  }

  Future<int> getUnassignedCount() async {
    try {
      final db = await appDb.database;
      final rows = await db.query(
        'produccion_metadata_local',
        where: 'key = ?',
        whereArgs: ['unassigned_count'],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        final val = rows.first['value'] as String?;
        return int.tryParse(val ?? '0') ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // ==========================================
  // ENQUEUE SYNC MUTATION
  // ==========================================

  Future<void> enqueueSync({
    required String action,
    required String endpoint,
    required String method,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final db = await appDb.database;
      await db.insert('sync_queue', {
        'action': action,
        'endpoint': endpoint,
        'method': method,
        'payload_json': jsonEncode(payload),
        'status': 'PENDING',
        'retry_count': 0,
        'created_at': DateTime.now().toIso8601String(),
      });
      Log.i('[OFFLINE-PROD] Mutación encolada en sync_queue: $action -> $endpoint');
    } catch (e) {
      Log.e('[OFFLINE-PROD] Error al encolar mutación en sync_queue', e);
    }
  }

  // ==========================================
  // MUTACIONES OPTIMISTAS OFFLINE
  // ==========================================

  Future<void> assignMesaOffline({
    required int pedidoId,
    required int mesaId,
    required int usuarioId,
    String mesaNombre = '',
  }) async {
    // 1. Encolar mutación
    await enqueueSync(
      action: 'PROD_UPDATE_MULTIPLE',
      endpoint: '/pedidoProduccion/multiple',
      method: 'PUT',
      payload: {
        'ids': [pedidoId],
        'data': {
          'id_mesa': mesaId,
          'id_usuario': usuarioId,
          'etapa_id': 1,
        },
      },
    );

    // 2. Actualizar caché local de etapa 1
    final groups = await getPedidosAgrupados(etapaId: 1);
    bool modified = false;

    final updatedGroups = groups.map((g) {
      final updatedItems = g.items.map((item) {
        if (item.id == pedidoId || g.pedidoId == pedidoId) {
          modified = true;
          return item; // Los ítems mantienen consistencia
        }
        return item;
      }).toList();
      return PedidoAgrupadoModel(
        pedidoId: g.pedidoId,
        tienda: g.tienda,
        pais: g.pais,
        deudorCodigo: g.deudorCodigo,
        deudorNombre: g.deudorNombre,
        fechaPedido: g.fechaPedido,
        fechaOrdenSap: g.fechaOrdenSap,
        items: updatedItems,
      );
    }).toList();

    if (modified) {
      await savePedidosAgrupados(etapaId: 1, list: updatedGroups);
    }
  }

  Future<void> unassignMesaOffline({required int pedidoId}) async {
    // 1. Encolar mutación
    await enqueueSync(
      action: 'PROD_UPDATE_SINGLE',
      endpoint: '/pedidoProduccion/$pedidoId',
      method: 'PUT',
      payload: {
        'id_mesa': null,
        'id_usuario': null,
      },
    );
  }

  Future<void> avanzarMultiEtapaOffline({
    required List<int> detalleOrdenIds,
    required int usuarioId,
    int? nuevaEtapaId,
    String? comentario,
    String? fechaOrden,
    bool? avanzar,
  }) async {
    // 1. Encolar mutación
    final payload = <String, dynamic>{
      'detalleOrdenIds': detalleOrdenIds,
      'usuarioId': usuarioId,
    };
    if (comentario != null) payload['comentario'] = comentario;
    if (fechaOrden != null) payload['fechaOrden'] = fechaOrden;
    if (nuevaEtapaId != null) payload['nuevaEtapaId'] = nuevaEtapaId;
    if (avanzar != null) payload['avanzar'] = avanzar;

    await enqueueSync(
      action: 'PROD_AVANZAR_MULTIPLE',
      endpoint: '/lineaTiempoDetalle/avanzar-multiples',
      method: 'POST',
      payload: payload,
    );

    // 2. Actualización optimista de etapas en caché local
    final targetEtapa = nuevaEtapaId ?? 2;
    final sourceEtapa = targetEtapa == 2 ? 1 : (targetEtapa == 3 ? 2 : 1);

    final sourceGroups = await getPedidosAgrupados(etapaId: sourceEtapa);
    final targetGroups = await getPedidosAgrupados(etapaId: targetEtapa);

    final idsSet = detalleOrdenIds.toSet();
    final remainingSourceGroups = <PedidoAgrupadoModel>[];
    final movedItemsByGroup = <int, List<PedidoProduccionModel>>{};

    for (final g in sourceGroups) {
      final keepItems = <PedidoProduccionModel>[];
      for (final item in g.items) {
        if (idsSet.contains(item.id) || idsSet.contains(item.idDetallePedido)) {
          movedItemsByGroup.putIfAbsent(g.pedidoId, () => []).add(item);
        } else {
          keepItems.add(item);
        }
      }
      if (keepItems.isNotEmpty) {
        remainingSourceGroups.add(PedidoAgrupadoModel(
          pedidoId: g.pedidoId,
          tienda: g.tienda,
          pais: g.pais,
          deudorCodigo: g.deudorCodigo,
          deudorNombre: g.deudorNombre,
          fechaPedido: g.fechaPedido,
          fechaOrdenSap: g.fechaOrdenSap,
          items: keepItems,
        ));
      }
    }

    if (movedItemsByGroup.isNotEmpty) {
      // Agregar ítems a targetGroups
      final updatedTargetGroups = List<PedidoAgrupadoModel>.from(targetGroups);
      for (final entry in movedItemsByGroup.entries) {
        final existingIdx = updatedTargetGroups.indexWhere((g) => g.pedidoId == entry.key);
        if (existingIdx >= 0) {
          final existingGroup = updatedTargetGroups[existingIdx];
          final mergedItems = List<PedidoProduccionModel>.from(existingGroup.items)..addAll(entry.value);
          updatedTargetGroups[existingIdx] = PedidoAgrupadoModel(
            pedidoId: existingGroup.pedidoId,
            tienda: existingGroup.tienda,
            pais: existingGroup.pais,
            deudorCodigo: existingGroup.deudorCodigo,
            deudorNombre: existingGroup.deudorNombre,
            fechaPedido: existingGroup.fechaPedido,
            fechaOrdenSap: existingGroup.fechaOrdenSap,
            items: mergedItems,
          );
        } else {
          final firstItem = entry.value.first;
          updatedTargetGroups.add(PedidoAgrupadoModel(
            pedidoId: entry.key,
            tienda: firstItem.tienda,
            pais: firstItem.pais,
            deudorCodigo: firstItem.deudorCodigo,
            deudorNombre: firstItem.deudorNombre,
            fechaPedido: firstItem.fechaPedido,
            fechaOrdenSap: firstItem.fechaOrdenSap,
            items: entry.value,
          ));
        }
      }

      await savePedidosAgrupados(etapaId: sourceEtapa, list: remainingSourceGroups);
      await savePedidosAgrupados(etapaId: targetEtapa, list: updatedTargetGroups);
    }
  }

  Future<void> updateMultiplePedidosOffline({
    required List<int> ids,
    required Map<String, dynamic> data,
  }) async {
    await enqueueSync(
      action: 'PROD_UPDATE_MULTIPLE',
      endpoint: '/pedidoProduccion/multiple',
      method: 'PUT',
      payload: {
        'ids': ids,
        'data': data,
      },
    );
  }

  Future<void> updatePedidoProduccionOffline({
    required int id,
    required Map<String, dynamic> data,
  }) async {
    await enqueueSync(
      action: 'PROD_UPDATE_SINGLE',
      endpoint: '/pedidoProduccion/$id',
      method: 'PUT',
      payload: data,
    );
  }

  Future<void> syncProcesadoRecetaOffline({
    required int pedidoId,
    required double cantidadProcesada,
  }) async {
    await enqueueSync(
      action: 'PROD_SYNC_RECETA',
      endpoint: '/receta/pedido/$pedidoId/sync-procesado',
      method: 'POST',
      payload: {
        'cantidadProcesada': cantidadProcesada,
      },
    );
  }

  Future<void> updateRecetaLineaOffline({
    required int id,
    required Map<String, dynamic> data,
  }) async {
    await enqueueSync(
      action: 'PROD_UPDATE_RECETA_LINEA',
      endpoint: '/receta/$id',
      method: 'PUT',
      payload: data,
    );
  }

  Future<void> createRechazoOffline({
    required int usuarioId,
    required double cantidadRechazada,
    required String comentario,
    int? idPedidoProd,
    int? pedidoId,
    int? idPedidoReceta,
  }) async {
    final payload = <String, dynamic>{
      'usuarioId': usuarioId,
      'cantidadRechazada': cantidadRechazada,
      'comentario': comentario,
    };
    if (idPedidoProd != null) payload['id_pedidoProd'] = idPedidoProd;
    if (pedidoId != null) payload['pedidoId'] = pedidoId;
    if (idPedidoReceta != null) payload['id_pedidoReceta'] = idPedidoReceta;

    await enqueueSync(
      action: 'PROD_RECHAZO',
      endpoint: '/rechazo',
      method: 'POST',
      payload: payload,
    );
  }

  Future<void> exportarOrdenFabricacionSAPOffline({
    required List<int> ids,
    required String fecha,
    required String comentario,
    String dbsap = '',
    String ipsap = '',
  }) async {
    await enqueueSync(
      action: 'PROD_EXPORTAR_SAP',
      endpoint: '/sap/deus/exportarOrdenFabricacion',
      method: 'POST',
      payload: {
        'ids': ids,
        'fecha': fecha,
        'comentario': comentario,
        'dbsap': dbsap,
        'ipsap': ipsap,
      },
    );
  }

  Future<void> saveRecetaLineaProveedoresOffline({
    required int recetaId,
    required int pedidoId,
    required List<ProveedorRecetaModel> proveedores,
    double? cantidadProcesada,
  }) async {
    final payload = <String, dynamic>{
      'proveedores': proveedores.map((p) => p.toJson()).toList(),
    };
    if (cantidadProcesada != null) {
      payload['cantidadProcesada'] = cantidadProcesada;
    }

    await enqueueSync(
      action: 'PROD_SAVE_PROVEEDORES',
      endpoint: '/receta/$recetaId/proveedores',
      method: 'POST',
      payload: payload,
    );

    final currentLineas = await getRecetaByPedido(pedidoId);
    if (currentLineas.isNotEmpty) {
      final updated = currentLineas.map((l) {
        if (l.id == recetaId) {
          final totalQty = proveedores.fold<double>(0.0, (sum, p) => sum + p.cantidad);
          return l.copyWith(
            cantidadBase: totalQty > 0 ? totalQty : l.cantidadBase,
            proveedores: proveedores,
          );
        }
        return l;
      }).toList();

      await saveRecetaByPedido(pedidoId: pedidoId, lineas: updated);
    }
  }
}

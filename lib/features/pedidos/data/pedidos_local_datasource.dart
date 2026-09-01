// ignore_for_file: use_null_aware_elements
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/logger_service.dart';
import '../domain/pedido_model.dart';
import '../domain/catalog_models.dart';
import '../domain/detalle_model.dart';
import '../domain/producto_model.dart';

class PedidosLocalDatasource {
  final AppDatabase appDb;

  PedidosLocalDatasource({required this.appDb});

  Future<void> saveCiudades(List<CatalogCiudad> list) async {
    final db = await appDb.database;
    final batch = db.batch();
    for (final item in list) {
      batch.insert('catalog_ciudades', {
        'id': item.id,
        'nombre': item.nombre,
        'state': 1,
        'updated_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<CatalogCiudad>> getCiudades() async {
    final db = await appDb.database;
    final rows = await db.query('catalog_ciudades', where: 'state = 1');
    return rows
        .map(
          (r) =>
              CatalogCiudad(id: r['id'] as int, nombre: r['nombre'] as String),
        )
        .toList();
  }

  Future<void> saveDeudores(List<CatalogDeudor> list) async {
    final db = await appDb.database;
    final batch = db.batch();
    for (final item in list) {
      batch.insert('catalog_deudores', {
        'id': item.id,
        'nombre': item.nombre,
        'codigo': item.correlativo,
        'state': 1,
        'updated_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<CatalogDeudor>> getDeudores() async {
    final db = await appDb.database;
    final rows = await db.query('catalog_deudores', where: 'state = 1');
    return rows
        .map(
          (r) => CatalogDeudor(
            id: r['id'] as int,
            nombre: r['nombre'] as String,
            correlativo: (r['codigo'] ?? '') as String,
          ),
        )
        .toList();
  }

  Future<void> saveTiendas(List<CatalogTienda> list) async {
    final db = await appDb.database;
    final batch = db.batch();
    for (final item in list) {
      batch.insert('catalog_tiendas', {
        'id': item.id,
        'nombre': item.nombre,
        'deudor_id': item.deudorId,
        'ciudad_id': item.ciudadId,
        'ruta_id': item.rutaId,
        'pais_id': item.paisId,
        'state': 1,
        'updated_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<CatalogTienda>> getTiendas() async {
    final db = await appDb.database;
    final rows = await db.query('catalog_tiendas', where: 'state = 1');
    return rows
        .map(
          (r) => CatalogTienda(
            id: r['id'] as int,
            nombre: r['nombre'] as String,
            deudorId: (r['deudor_id'] ?? 0) as int,
            ciudadId: (r['ciudad_id'] ?? 0) as int,
            rutaId: (r['ruta_id'] ?? 0) as int,
            paisId: (r['pais_id'] ?? 0) as int,
          ),
        )
        .toList();
  }

  Future<void> saveProductos(int deudorId, List<ProductoModel> list) async {
    final db = await appDb.database;
    final batch = db.batch();
    for (final item in list) {
      batch.insert('catalog_productos', {
        'id': item.id,
        'codigo': item.codigo,
        'nombre': item.nombre,
        'deudor_id': deudorId,
        'state': 1,
        'updated_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<ProductoModel>> getProductos(int deudorId) async {
    final db = await appDb.database;
    final rows = await db.query(
      'catalog_productos',
      where: 'deudor_id = ? AND state = 1',
      whereArgs: [deudorId],
    );
    return rows
        .map(
          (r) => ProductoModel(
            id: r['id'] as int,
            nombre: r['nombre'] as String,
            codigo: (r['codigo'] ?? '') as String,
          ),
        )
        .toList();
  }

  Future<void> savePedidos(List<PedidoModel> list) async {
    final db = await appDb.database;
    final batch = db.batch();
    for (final item in list) {
      batch.insert('pedidos_local', {
        'id': item.id,
        'deudor_id': item.deudorId,
        'tienda_id': item.tiendaId,
        'ciudad_id': 0,
        'usuario_id': item.usuarioId,
        'comentario': item.comentario,
        'estado_id': item.estadoId,
        'estado_nombre': item.estadoNombre,
        'fecha': item.creadoEl.toIso8601String(),
        'raw_json': jsonEncode(item.toJson()),
        'synced': 1,
        'created_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<PedidoModel>> getPedidos() async {
    final db = await appDb.database;
    final rows = await db.query('pedidos_local', orderBy: 'id DESC');
    return rows.map((r) {
      final json = jsonDecode(r['raw_json'] as String) as Map<String, dynamic>;
      final isSynced = (r['synced'] as int? ?? 1) == 1;
      return PedidoModel.fromJson(json, synced: isSynced);
    }).toList();
  }

  Future<PedidoModel> saveOfflinePedido({
    required int deudorId,
    required int tiendaId,
    required int ciudadId,
    int? usuarioId,
    String? comentario,
    String deudorNombre = '',
    String tiendaNombre = '',
  }) async {
    final db = await appDb.database;
    final now = DateTime.now();
    final tempId = -(now.millisecondsSinceEpoch % 2147483647);

    final offlinePedido = PedidoModel(
      id: tempId,
      deudorId: deudorId,
      tiendaId: tiendaId,
      estadoId: 1,
      creadoEl: now,
      comentario: comentario,
      deudorNombre: deudorNombre.isNotEmpty
          ? deudorNombre
          : 'Cliente #$deudorId',
      tiendaNombre: tiendaNombre.isNotEmpty
          ? tiendaNombre
          : 'Tienda #$tiendaId',
      estadoNombre: 'Pendiente (Offline)',
      usuarioId: usuarioId,
      synced: false,
    );

    await db.insert('pedidos_local', {
      'id': tempId,
      'deudor_id': deudorId,
      'tienda_id': tiendaId,
      'ciudad_id': ciudadId,
      'usuario_id': usuarioId,
      'comentario': comentario,
      'estado_id': 1,
      'estado_nombre': 'Pendiente (Offline)',
      'fecha': now.toIso8601String(),
      'raw_json': jsonEncode(offlinePedido.toJson()),
      'synced': 0,
      'created_at': now.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    final payload = {
      'tempId': tempId,
      'deudorId': deudorId,
      'tiendaId': tiendaId,
      'ciudadId': ciudadId,
      if (usuarioId != null) 'usuarioId': usuarioId,
      if (comentario != null) 'comentario': comentario,
      'estadoId': 1,
    };

    await db.insert('sync_queue', {
      'action': 'CREATE_PEDIDO',
      'endpoint': '/form/pedidos/create',
      'method': 'POST',
      'payload_json': jsonEncode(payload),
      'status': 'PENDING',
      'retry_count': 0,
      'created_at': now.toIso8601String(),
    });

    Log.i(
      '[OFFLINE] Pedido creado localmente con ID temporal $tempId y encolado para sync.',
    );
    return offlinePedido;
  }

  Future<PedidoModel> copiarUltimoPedidoLocal({
    required int ciudadId,
    required int deudorId,
    required int tiendaId,
    required int usuarioId,
    String deudorNombre = '',
    String tiendaNombre = '',
  }) async {
    final db = await appDb.database;
    final nuevoPedido = await saveOfflinePedido(
      deudorId: deudorId,
      tiendaId: tiendaId,
      ciudadId: ciudadId,
      usuarioId: usuarioId,
      comentario: 'Copia del último pedido',
      deudorNombre: deudorNombre,
      tiendaNombre: tiendaNombre,
    );

    final ultimosPedidos = await db.query(
      'pedidos_local',
      where: 'deudor_id = ? AND tienda_id = ? AND id != ?',
      whereArgs: [deudorId, tiendaId, nuevoPedido.id],
      orderBy: 'id DESC',
      limit: 1,
    );

    if (ultimosPedidos.isNotEmpty) {
      final ultimoId = ultimosPedidos.first['id'] as int;
      final detallesPrevios = await getDetalles(ultimoId);
      if (detallesPrevios.isNotEmpty) {
        final nuevosDetalles = detallesPrevios.map((d) => d.copyWith(
          id: -(DateTime.now().millisecondsSinceEpoch % 2147483647),
          pedidoId: nuevoPedido.id,
        )).toList();
        await saveDetalles(nuevoPedido.id, nuevosDetalles);
        Log.i('[OFFLINE] ${nuevosDetalles.length} productos copiados del pedido $ultimoId al pedido ${nuevoPedido.id}');
        return nuevoPedido;
      }
    }

    final prods = await getProductos(deudorId);
    final emptyDetalles = prods.map((p) => DetalleModel(
      id: -(DateTime.now().millisecondsSinceEpoch % 2147483647),
      pedidoId: nuevoPedido.id,
      productoId: p.id,
      cantidad: 0,
      precio: 0,
      productoNombre: p.nombre,
      productoCodigo: p.codigo,
    )).toList();
    await saveDetalles(nuevoPedido.id, emptyDetalles);

    return nuevoPedido;
  }

  Future<void> saveDetalles(int pedidoId, List<DetalleModel> list) async {
    final db = await appDb.database;
    final batch = db.batch();
    await db.delete(
      'pedidos_detalle_local',
      where: 'pedido_id = ?',
      whereArgs: [pedidoId],
    );
    for (final item in list) {
      batch.insert('pedidos_detalle_local', {
        'pedido_id': pedidoId,
        'producto_id': item.productoId,
        'cantidad': item.cantidad,
        'precio': item.precio,
        'raw_json': jsonEncode({
          'id': item.id,
          'pedidoId': item.pedidoId,
          'productoId': item.productoId,
          'cantidad': item.cantidad,
          'precio': item.precio,
          'nombreProducto': item.productoNombre,
          'codigo': item.productoCodigo,
        }),
        'synced': 1,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
    await batch.commit(noResult: true);
  }

  Future<List<DetalleModel>> getDetalles(int pedidoId) async {
    final db = await appDb.database;
    final rows = await db.query(
      'pedidos_detalle_local',
      where: 'pedido_id = ?',
      whereArgs: [pedidoId],
    );
    return rows.map((r) {
      final json = jsonDecode(r['raw_json'] as String) as Map<String, dynamic>;
      return DetalleModel.fromJson(json);
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    final db = await appDb.database;
    return await db.query(
      'sync_queue',
      where: 'status = ?',
      whereArgs: ['PENDING'],
      orderBy: 'id ASC',
    );
  }

  Future<void> markSyncItemCompleted(
    int queueId,
    int tempId,
    int realId,
  ) async {
    final db = await appDb.database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [queueId]);

    final localRow = await db.query(
      'pedidos_local',
      where: 'id = ?',
      whereArgs: [tempId],
    );
    if (localRow.isNotEmpty) {
      final raw =
          jsonDecode(localRow.first['raw_json'] as String)
              as Map<String, dynamic>;
      raw['id'] = realId;
      raw['synced'] = true;
      raw['tipoEstado'] = {'nombre': 'Creado'};

      await db.delete('pedidos_local', where: 'id = ?', whereArgs: [tempId]);
      await db.insert('pedidos_local', {
        'id': realId,
        'deudor_id': localRow.first['deudor_id'],
        'tienda_id': localRow.first['tienda_id'],
        'ciudad_id': localRow.first['ciudad_id'],
        'usuario_id': localRow.first['usuario_id'],
        'comentario': localRow.first['comentario'],
        'estado_id': 1,
        'estado_nombre': 'Creado',
        'fecha': localRow.first['fecha'],
        'raw_json': jsonEncode(raw),
        'synced': 1,
        'created_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    Log.i(
      '[SYNC] Ítem $queueId procesado con éxito. ID temporal $tempId reemplazado por real $realId.',
    );
  }

  Future<void> markSyncItemFailed(int queueId, String error) async {
    final db = await appDb.database;
    await db.rawUpdate(
      '''
      UPDATE sync_queue 
      SET retry_count = retry_count + 1, last_error = ? 
      WHERE id = ?
    ''',
      [error, queueId],
    );
  }

  // ===================== OFFLINE MUTATIONS =====================

  Future<void> deleteLocalPedido(int pedidoId) async {
    final db = await appDb.database;
    await db.delete('pedidos_local', where: 'id = ?', whereArgs: [pedidoId]);
    await db.delete('pedidos_detalle_local', where: 'pedido_id = ?', whereArgs: [pedidoId]);

    if (pedidoId < 0) {
      // Si fue creado offline y nunca subió, limpiar la cola de creación
      await db.delete('sync_queue', where: 'payload_json LIKE ?', whereArgs: ['%"tempId":$pedidoId%']);
      Log.i('[OFFLINE] Borrador offline $pedidoId eliminado de base local y cola.');
    } else {
      // Si ya existía en backend, encolar eliminación
      await db.insert('sync_queue', {
        'action': 'DELETE_PEDIDO',
        'endpoint': '/form/pedidos/eliminar/$pedidoId',
        'method': 'DELETE',
        'payload_json': jsonEncode({'pedidoId': pedidoId}),
        'status': 'PENDING',
        'retry_count': 0,
        'created_at': DateTime.now().toIso8601String(),
      });
      Log.i('[OFFLINE] Pedido $pedidoId eliminado localmente y encolado para backend.');
    }
  }

  Future<void> realizarLocalPedido({
    required int pedidoId,
    required String comentario,
    required String fecha,
    required int userId,
  }) async {
    final db = await appDb.database;
    final now = DateTime.now();

    final localRow = await db.query('pedidos_local', where: 'id = ?', whereArgs: [pedidoId]);
    if (localRow.isNotEmpty) {
      final raw = jsonDecode(localRow.first['raw_json'] as String) as Map<String, dynamic>;
      raw['estadoId'] = 2;
      raw['estadoNombre'] = 'Realizado';
      raw['comentario'] = comentario;
      raw['tipoEstado'] = {'nombre': 'Realizado'};
      raw['synced'] = false;

      await db.update(
        'pedidos_local',
        {
          'estado_id': 2,
          'estado_nombre': 'Realizado',
          'comentario': comentario,
          'fecha': fecha,
          'raw_json': jsonEncode(raw),
          'synced': 0,
        },
        where: 'id = ?',
        whereArgs: [pedidoId],
      );
    }

    final payload = {
      'pedidoId': pedidoId,
      'estadoId': 2,
      'comentario': comentario,
      'comentarioDisplay': comentario,
      'fechaOrdenDisplay': fecha,
      'updatedBy': userId,
    };

    await db.insert('sync_queue', {
      'action': 'REALIZAR_PEDIDO',
      'endpoint': '/form/pedidos/actualizar-estado/$pedidoId',
      'method': 'PATCH',
      'payload_json': jsonEncode(payload),
      'status': 'PENDING',
      'retry_count': 0,
      'created_at': now.toIso8601String(),
    });

    Log.i('[OFFLINE] Pedido $pedidoId marcado como realizado localmente y encolado.');
  }

  Future<void> updateLocalItemQuantity(int pedidoId, int detailId, int cantidad) async {
    final db = await appDb.database;
    final row = await db.query('pedidos_detalle_local', where: 'id = ?', whereArgs: [detailId]);
    if (row.isNotEmpty) {
      final raw = jsonDecode(row.first['raw_json'] as String) as Map<String, dynamic>;
      raw['cantidad'] = cantidad;
      await db.update(
        'pedidos_detalle_local',
        {
          'cantidad': cantidad,
          'raw_json': jsonEncode(raw),
        },
        where: 'id = ?',
        whereArgs: [detailId],
      );
    }

    await db.insert('sync_queue', {
      'action': 'UPDATE_QTY',
      'endpoint': '/detalle/pedido/actualizar/$pedidoId/$detailId',
      'method': 'PUT',
      'payload_json': jsonEncode({'pedidoId': pedidoId, 'detailId': detailId, 'cantidad': cantidad}),
      'status': 'PENDING',
      'retry_count': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
    Log.i('[OFFLINE] Cantidad de producto $detailId actualizada localmente a $cantidad y encolada.');
  }

  Future<void> deleteLocalItem(int detailId) async {
    final db = await appDb.database;
    await db.delete('pedidos_detalle_local', where: 'id = ?', whereArgs: [detailId]);

    await db.insert('sync_queue', {
      'action': 'DELETE_ITEM',
      'endpoint': '/detalle/pedido/eliminar/$detailId',
      'method': 'DELETE',
      'payload_json': jsonEncode({'detailId': detailId}),
      'status': 'PENDING',
      'retry_count': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
    Log.i('[OFFLINE] Producto $detailId eliminado localmente y encolado.');
  }

  Future<void> addLocalItem({
    required int pedidoId,
    required int productoId,
    required int cantidad,
    required int userId,
    String productoNombre = '',
    String productoCodigo = '',
  }) async {
    final db = await appDb.database;
    final tempDetailId = -(DateTime.now().millisecondsSinceEpoch % 2147483647);

    final raw = {
      'id': tempDetailId,
      'pedidoId': pedidoId,
      'productoId': productoId,
      'cantidad': cantidad,
      'precio': 0,
      'nombreProducto': productoNombre,
      'codigo': productoCodigo,
    };

    await db.insert('pedidos_detalle_local', {
      'id': tempDetailId,
      'pedido_id': pedidoId,
      'producto_id': productoId,
      'cantidad': cantidad,
      'precio': 0,
      'raw_json': jsonEncode(raw),
      'synced': 0,
      'created_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    await db.insert('sync_queue', {
      'action': 'ADD_ITEM',
      'endpoint': '/detalle/pedido/create',
      'method': 'POST',
      'payload_json': jsonEncode({
        'pedidoId': pedidoId,
        'productoId': productoId,
        'cantidad': cantidad,
        'precio': 0,
        'createdBy': userId,
      }),
      'status': 'PENDING',
      'retry_count': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
    Log.i('[OFFLINE] Producto $productoId agregado a pedido $pedidoId localmente y encolado.');
  }
}

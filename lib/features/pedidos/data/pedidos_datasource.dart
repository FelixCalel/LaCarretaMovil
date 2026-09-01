// ignore_for_file: use_null_aware_elements
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/logger_service.dart';
import '../domain/pedido_model.dart';
import '../domain/catalog_models.dart';
import '../domain/detalle_model.dart';
import '../domain/producto_model.dart';
import 'pedidos_local_datasource.dart';

class PedidosDatasource {
  final ApiClient apiClient;
  final PedidosLocalDatasource localDs;

  PedidosDatasource({required this.apiClient, PedidosLocalDatasource? localDs})
    : localDs = localDs ?? PedidosLocalDatasource(appDb: AppDatabase());

  Future<List<PedidoModel>> getPedidos() async {
    try {
      final response = await apiClient.dio.get('/form/pedidos/todos');
      final List<dynamic> data = response.data;
      final pedidos = data.map((json) => PedidoModel.fromJson(json)).toList();

      await localDs.savePedidos(pedidos);

      return await localDs.getPedidos();
    } on DioException catch (e) {
      Log.w('Fallo de red al obtener pedidos. Consultando SQLite...', e);
      final localPedidos = await localDs.getPedidos();
      if (localPedidos.isNotEmpty) {
        return localPedidos;
      }
      final errorMessage =
          e.response?.data['error'] ??
          'Error al obtener pedidos y no hay datos offline';
      throw Exception(errorMessage);
    } catch (e) {
      final localPedidos = await localDs.getPedidos();
      if (localPedidos.isNotEmpty) return localPedidos;
      rethrow;
    }
  }

  Future<PedidoModel> createPedido({
    required int deudorId,
    required int tiendaId,
    required int ciudadId,
    int? usuarioId,
    String? comentario,
    String deudorNombre = '',
    String tiendaNombre = '',
  }) async {
    try {
      final response = await apiClient.dio.post(
        '/form/pedidos/create',
        data: {
          'deudorId': deudorId,
          'tiendaId': tiendaId,
          'ciudadId': ciudadId,
          if (usuarioId != null) 'usuarioId': usuarioId,
          if (comentario != null) 'comentario': comentario,
          'estadoId': 1,
        },
      );
      final newPedido = PedidoModel.fromJson(response.data);
      await localDs.savePedidos([newPedido]);
      return newPedido;
    } on DioException catch (e) {
      Log.w(
        'Fallo de conexión al crear pedido. Guardando en cola SQLite offline...',
        e,
      );
      return await localDs.saveOfflinePedido(
        deudorId: deudorId,
        tiendaId: tiendaId,
        ciudadId: ciudadId,
        usuarioId: usuarioId,
        comentario: comentario,
        deudorNombre: deudorNombre,
        tiendaNombre: tiendaNombre,
      );
    } catch (e) {
      Log.w('Error inesperado. Creando pedido en modo offline...', e);
      return await localDs.saveOfflinePedido(
        deudorId: deudorId,
        tiendaId: tiendaId,
        ciudadId: ciudadId,
        usuarioId: usuarioId,
        comentario: comentario,
        deudorNombre: deudorNombre,
        tiendaNombre: tiendaNombre,
      );
    }
  }

  Future<void> populatePedidoModelo({
    required int deudorId,
    required int pedidoId,
    required int tiendaId,
  }) async {
    try {
      await apiClient.dio.get(
        '/detalle/pedido/pedidoModelo/$deudorId/$pedidoId/$tiendaId',
      );
    } on DioException catch (e) {
      if (pedidoId < 0) {
        Log.i(
          'Pedido offline: se populará automáticamente tras la sincronización.',
        );
        return;
      }
      final errorMessage =
          e.response?.data['error'] ?? 'Error al popular pedido modelo';
      throw Exception(errorMessage);
    }
  }

  Future<List<CatalogCiudad>> getCiudades() async {
    try {
      final response = await apiClient.dio.get('/ciudad/todos');
      final List<dynamic> data = response.data;
      final list = data.map((json) => CatalogCiudad.fromJson(json)).toList();
      await localDs.saveCiudades(list);
      return list;
    } catch (e) {
      Log.w('Sin red para ciudades. Leyendo desde SQLite...', e);
      final localList = await localDs.getCiudades();
      if (localList.isNotEmpty) return localList;
      throw Exception(
        'No hay ciudades disponibles offline. Conéctate a internet para sincronizar.',
      );
    }
  }

  Future<List<CatalogDeudor>> getDeudores() async {
    try {
      final response = await apiClient.dio.get('/deus/todos');
      final List<dynamic> data = response.data;
      final list = data.map((json) => CatalogDeudor.fromJson(json)).toList();
      await localDs.saveDeudores(list);
      return list;
    } catch (e) {
      Log.w('Sin red para clientes. Leyendo desde SQLite...', e);
      final localList = await localDs.getDeudores();
      if (localList.isNotEmpty) return localList;
      throw Exception(
        'No hay clientes disponibles offline. Conéctate a internet para sincronizar.',
      );
    }
  }

  Future<List<CatalogTienda>> getTiendas() async {
    try {
      final response = await apiClient.dio.get('/tienda/todos');
      final List<dynamic> data = response.data;
      final list = data.map((json) => CatalogTienda.fromJson(json)).toList();
      await localDs.saveTiendas(list);
      return list;
    } catch (e) {
      Log.w('Sin red para tiendas. Leyendo desde SQLite...', e);
      final localList = await localDs.getTiendas();
      if (localList.isNotEmpty) return localList;
      throw Exception(
        'No hay tiendas disponibles offline. Conéctate a internet para sincronizar.',
      );
    }
  }

  Future<List<DetalleModel>> getPedidoDetalles(int pedidoId) async {
    try {
      if (pedidoId < 0) {
        return await localDs.getDetalles(pedidoId);
      }
      final response = await apiClient.dio.get(
        '/detalle/pedido/listar/$pedidoId',
      );
      final List<dynamic> data = response.data;
      final list = data.map((json) => DetalleModel.fromJson(json)).toList();
      await localDs.saveDetalles(pedidoId, list);
      return list;
    } catch (e) {
      Log.w('Sin red para detalles de pedido. Leyendo desde SQLite...', e);
      return await localDs.getDetalles(pedidoId);
    }
  }

  Future<List<ProductoModel>> getDeudorProductos(int deudorId) async {
    try {
      final response = await apiClient.dio.get(
        '/items/activos/deudor/$deudorId',
      );
      final List<dynamic> data = response.data['items'] ?? [];
      final list = data.map((json) => ProductoModel.fromJson(json)).toList();
      await localDs.saveProductos(deudorId, list);
      return list;
    } catch (e) {
      Log.w('Sin red para productos del cliente. Leyendo desde SQLite...', e);
      final localList = await localDs.getProductos(deudorId);
      if (localList.isNotEmpty) return localList;
      throw Exception(
        'No hay productos disponibles offline para este cliente.',
      );
    }
  }

  Future<void> updateItemQuantity(
    int pedidoId,
    int detailId,
    int cantidad,
  ) async {
    try {
      await apiClient.dio.put(
        '/detalle/pedido/actualizar/$pedidoId/$detailId',
        data: {'cantidad': cantidad},
      );
    } on DioException catch (e) {
      Log.w('Sin red al actualizar cantidad. Guardando en SQLite offline...', e);
      await localDs.updateLocalItemQuantity(pedidoId, detailId, cantidad);
    } catch (_) {
      await localDs.updateLocalItemQuantity(pedidoId, detailId, cantidad);
    }
  }

  Future<void> deleteItem(int detailId) async {
    try {
      await apiClient.dio.delete('/detalle/pedido/eliminar/$detailId');
    } on DioException catch (e) {
      Log.w('Sin red al eliminar producto. Guardando en SQLite offline...', e);
      await localDs.deleteLocalItem(detailId);
    } catch (_) {
      await localDs.deleteLocalItem(detailId);
    }
  }

  Future<void> addItemToPedido({
    required int pedidoId,
    required int productoId,
    required int cantidad,
    required int userId,
    String productoNombre = '',
    String productoCodigo = '',
  }) async {
    try {
      await apiClient.dio.post(
        '/detalle/pedido/create',
        data: {
          'pedidoId': pedidoId,
          'productoId': productoId,
          'cantidad': cantidad,
          'precio': 0,
          'createdBy': userId,
        },
      );
    } on DioException catch (e) {
      Log.w('Sin red al agregar producto. Guardando en SQLite offline...', e);
      await localDs.addLocalItem(
        pedidoId: pedidoId,
        productoId: productoId,
        cantidad: cantidad,
        userId: userId,
        productoNombre: productoNombre,
        productoCodigo: productoCodigo,
      );
    } catch (_) {
      await localDs.addLocalItem(
        pedidoId: pedidoId,
        productoId: productoId,
        cantidad: cantidad,
        userId: userId,
        productoNombre: productoNombre,
        productoCodigo: productoCodigo,
      );
    }
  }

  Future<void> deletePedido(int pedidoId) async {
    if (pedidoId < 0) {
      // Pedido creado offline
      await localDs.deleteLocalPedido(pedidoId);
      return;
    }
    try {
      await apiClient.dio.delete('/form/pedidos/eliminar/$pedidoId');
      await localDs.deleteLocalPedido(pedidoId);
    } on DioException catch (e) {
      Log.w('Sin red al eliminar pedido. Marcando en SQLite offline...', e);
      await localDs.deleteLocalPedido(pedidoId);
    } catch (_) {
      await localDs.deleteLocalPedido(pedidoId);
    }
  }

  Future<void> realizarPedido({
    required int pedidoId,
    required String comentario,
    required String fecha,
    required int userId,
  }) async {
    try {
      await apiClient.dio.patch(
        '/form/pedidos/actualizar-estado/$pedidoId',
        data: {
          'estadoId': 2,
          'comentario': comentario,
          'comentarioDisplay': comentario,
          'fechaOrdenDisplay': fecha,
          'updatedBy': userId,
        },
      );
      await localDs.realizarLocalPedido(
        pedidoId: pedidoId,
        comentario: comentario,
        fecha: fecha,
        userId: userId,
      );
    } on DioException catch (e) {
      Log.w('Sin red al realizar pedido. Guardando estado en SQLite offline...', e);
      await localDs.realizarLocalPedido(
        pedidoId: pedidoId,
        comentario: comentario,
        fecha: fecha,
        userId: userId,
      );
    } catch (_) {
      await localDs.realizarLocalPedido(
        pedidoId: pedidoId,
        comentario: comentario,
        fecha: fecha,
        userId: userId,
      );
    }
  }

  Future<void> copiarUltimoPedido({
    required int ciudadId,
    required int deudorId,
    required int tiendaId,
    required int usuarioId,
    String deudorNombre = '',
    String tiendaNombre = '',
  }) async {
    try {
      await apiClient.dio.post(
        '/detalle/pedido/copiar-ultimo',
        data: {
          'ciudadId': ciudadId,
          'deudorId': deudorId,
          'tiendaId': tiendaId,
          'usuarioId': usuarioId,
        },
      );
    } on DioException catch (e) {
      Log.w('Sin red al copiar último pedido. Copiando en SQLite local...', e);
      await localDs.copiarUltimoPedidoLocal(
        ciudadId: ciudadId,
        deudorId: deudorId,
        tiendaId: tiendaId,
        usuarioId: usuarioId,
        deudorNombre: deudorNombre,
        tiendaNombre: tiendaNombre,
      );
    } catch (_) {
      await localDs.copiarUltimoPedidoLocal(
        ciudadId: ciudadId,
        deudorId: deudorId,
        tiendaId: tiendaId,
        usuarioId: usuarioId,
        deudorNombre: deudorNombre,
        tiendaNombre: tiendaNombre,
      );
    }
  }
}

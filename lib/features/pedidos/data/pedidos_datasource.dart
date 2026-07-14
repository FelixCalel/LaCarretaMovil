// ignore_for_file: use_null_aware_elements
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../domain/pedido_model.dart';
import '../domain/catalog_models.dart';
import '../domain/detalle_model.dart';
import '../domain/producto_model.dart';

class PedidosDatasource {
  final ApiClient apiClient;

  PedidosDatasource({required this.apiClient});

  Future<List<PedidoModel>> getPedidos() async {
    try {
      final response = await apiClient.dio.get('/form/pedidos/todos');
      final List<dynamic> data = response.data;
      return data.map((json) => PedidoModel.fromJson(json)).toList();
    } on DioException catch (e) {
      final errorMessage = e.response?.data['error'] ?? 'Error al obtener pedidos';
      throw Exception(errorMessage);
    }
  }

  Future<PedidoModel> createPedido({
    required int deudorId,
    required int tiendaId,
    required int ciudadId,
    int? usuarioId,
    String? comentario,
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
      return PedidoModel.fromJson(response.data);
    } on DioException catch (e) {
      final errorMessage = e.response?.data['error'] ?? 'Error al crear pedido';
      throw Exception(errorMessage);
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
      final errorMessage = e.response?.data['error'] ?? 'Error al popular pedido modelo';
      throw Exception(errorMessage);
    }
  }

  Future<List<CatalogCiudad>> getCiudades() async {
    try {
      final response = await apiClient.dio.get('/ciudad/todos');
      final List<dynamic> data = response.data;
      return data.map((json) => CatalogCiudad.fromJson(json)).toList();
    } on DioException catch (e) {
      final errorMessage = e.response?.data['error'] ?? 'Error al obtener ciudades';
      throw Exception(errorMessage);
    }
  }

  Future<List<CatalogDeudor>> getDeudores() async {
    try {
      final response = await apiClient.dio.get('/deus/todos');
      final List<dynamic> data = response.data;
      return data.map((json) => CatalogDeudor.fromJson(json)).toList();
    } on DioException catch (e) {
      final errorMessage = e.response?.data['error'] ?? 'Error al obtener clientes';
      throw Exception(errorMessage);
    }
  }

  Future<List<CatalogTienda>> getTiendas() async {
    try {
      final response = await apiClient.dio.get('/tienda/todos');
      final List<dynamic> data = response.data;
      return data.map((json) => CatalogTienda.fromJson(json)).toList();
    } on DioException catch (e) {
      final errorMessage = e.response?.data['error'] ?? 'Error al obtener tiendas';
      throw Exception(errorMessage);
    }
  }

  Future<List<DetalleModel>> getPedidoDetalles(int pedidoId) async {
    try {
      final response = await apiClient.dio.get('/detalle/pedido/listar/$pedidoId');
      final List<dynamic> data = response.data;
      return data.map((json) => DetalleModel.fromJson(json)).toList();
    } on DioException catch (e) {
      final errorMessage = e.response?.data['error'] ?? 'Error al obtener detalles del pedido';
      throw Exception(errorMessage);
    }
  }

  Future<List<ProductoModel>> getDeudorProductos(int deudorId) async {
    try {
      final response = await apiClient.dio.get('/items/activos/deudor/$deudorId');
      final List<dynamic> data = response.data['items'] ?? [];
      return data.map((json) => ProductoModel.fromJson(json)).toList();
    } on DioException catch (e) {
      final errorMessage = e.response?.data['error'] ?? 'Error al obtener productos del cliente';
      throw Exception(errorMessage);
    }
  }

  Future<void> updateItemQuantity(int pedidoId, int detailId, int cantidad) async {
    try {
      await apiClient.dio.put(
        '/detalle/pedido/actualizar/$pedidoId/$detailId',
        data: {'cantidad': cantidad},
      );
    } on DioException catch (e) {
      final errorMessage = e.response?.data['error'] ?? 'Error al actualizar cantidad';
      throw Exception(errorMessage);
    }
  }

  Future<void> deleteItem(int detailId) async {
    try {
      await apiClient.dio.delete('/detalle/pedido/eliminar/$detailId');
    } on DioException catch (e) {
      final errorMessage = e.response?.data['error'] ?? 'Error al eliminar producto';
      throw Exception(errorMessage);
    }
  }

  Future<void> addItemToPedido({
    required int pedidoId,
    required int productoId,
    required int cantidad,
    required int userId,
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
      final errorMessage = e.response?.data['error'] ?? 'Error al agregar producto';
      throw Exception(errorMessage);
    }
  }

  Future<void> deletePedido(int pedidoId) async {
    try {
      await apiClient.dio.delete('/form/pedidos/eliminar/$pedidoId');
    } on DioException catch (e) {
      final errorMessage = e.response?.data['error'] ?? 'Error al eliminar pedido';
      throw Exception(errorMessage);
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
    } on DioException catch (e) {
      final errorMessage = e.response?.data['error'] ?? 'Error al realizar pedido';
      throw Exception(errorMessage);
    }
  }

  Future<void> copiarUltimoPedido({
    required int ciudadId,
    required int deudorId,
    required int tiendaId,
    required int usuarioId,
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
      final errorMessage = e.response?.data['error'] ?? 'Error al copiar el último pedido';
      throw Exception(errorMessage);
    }
  }
}

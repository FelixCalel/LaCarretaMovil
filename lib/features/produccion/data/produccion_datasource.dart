import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/logger_service.dart';
import '../domain/produccion_model.dart';
import 'produccion_local_datasource.dart';

class ProduccionDatasource {
  final ApiClient apiClient;
  final ProduccionLocalDatasource localDs;

  ProduccionDatasource({ApiClient? apiClient, ProduccionLocalDatasource? localDs})
      : apiClient = apiClient ?? ApiClient(),
        localDs = localDs ?? ProduccionLocalDatasource();

  Future<List<PedidoAgrupadoModel>> getPedidosAgrupados({
    int etapaId = 1,
    bool? completed,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'etapaId': etapaId,
      };
      if (completed != null) {
        queryParams['completed'] = completed;
      }

      final response = await apiClient.dio.get(
        '/pedidoProduccion/agrupados',
        queryParameters: queryParams,
      );

      if (response.data is List) {
        final list = (response.data as List)
            .map((j) => PedidoAgrupadoModel.fromJson(j as Map<String, dynamic>))
            .toList();

        // Guardar en caché local SQLite si es consulta normal (sin filtro completed restrictivo)
        if (completed == null) {
          await localDs.savePedidosAgrupados(etapaId: etapaId, list: list);
        }

        return list;
      }
      return [];
    } catch (e) {
      Log.w('Fallo de red al obtener pedidos agrupados (etapa $etapaId). Consultando SQLite...', e);
      final localList = await localDs.getPedidosAgrupados(etapaId: etapaId);
      if (localList.isNotEmpty) {
        return localList;
      }
      if (e is DioException) {
        throw Exception(
          e.response?.data?['message'] ??
              e.response?.data?['error'] ??
              'Sin conexión a internet y no hay datos locales de producción',
        );
      }
      rethrow;
    }
  }

  Future<int> getUnassignedOrdersCount() async {
    try {
      final response = await apiClient.dio.get(
        '/pedidoProduccion/sin-asignar/count',
      );
      if (response.data is Map && response.data['count'] != null) {
        final count = response.data['count'];
        final parsed = count is int ? count : int.tryParse(count.toString()) ?? 0;
        await localDs.saveUnassignedCount(parsed);
        return parsed;
      }
      return 0;
    } catch (e) {
      Log.w('Fallo de red al obtener conteo sin asignar. Consultando SQLite...', e);
      return await localDs.getUnassignedCount();
    }
  }

  Future<List<MesaActivaAsignadaModel>> getActiveMesaAssignments() async {
    try {
      final response = await apiClient.dio.get('/asignarAM/activos');
      if (response.data is List) {
        final list = (response.data as List)
            .map((j) =>
                MesaActivaAsignadaModel.fromJson(j as Map<String, dynamic>))
            .toList();
        await localDs.saveActiveMesaAssignments(list);
        return list;
      }
      return [];
    } catch (e) {
      Log.w('Fallo de red al obtener mesas activas. Consultando SQLite...', e);
      return await localDs.getActiveMesaAssignments();
    }
  }

  Future<List<AlmacenModel>> getAlmacenes() async {
    try {
      final response = await apiClient.dio.get('/almacen');
      if (response.data is List) {
        final list = (response.data as List)
            .map((j) => AlmacenModel.fromJson(j as Map<String, dynamic>))
            .toList();
        list.sort((a, b) =>
            a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
        await localDs.saveAlmacenes(list);
        return list;
      }
      return [];
    } catch (e) {
      Log.w('Fallo de red al obtener almacenes. Consultando SQLite...', e);
      return await localDs.getAlmacenes();
    }
  }

  Future<List<RecetaLineaModel>> getRecetaByPedido(
    int pedidoId, {
    int? idAlmacen,
  }) async {
    try {
      String url = '/receta/pedido/$pedidoId';
      final queryParams = <String, dynamic>{};
      if (idAlmacen != null) {
        queryParams['id_almacen'] = idAlmacen;
      }

      final response = await apiClient.dio.get(
        url,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.data is List) {
        final list = (response.data as List)
            .map((j) => RecetaLineaModel.fromJson(j as Map<String, dynamic>))
            .toList();
        await localDs.saveRecetaByPedido(
          pedidoId: pedidoId,
          idAlmacen: idAlmacen,
          lineas: list,
        );
        return list;
      }
      return [];
    } catch (e) {
      Log.w('Fallo de red al obtener receta de pedido $pedidoId. Consultando SQLite...', e);
      final localReceta = await localDs.getRecetaByPedido(pedidoId, idAlmacen: idAlmacen);
      if (localReceta.isNotEmpty) {
        return localReceta;
      }
      if (e is DioException) {
        throw Exception(
          e.response?.data?['message'] ?? 'Sin conexión y no hay receta guardada localmente',
        );
      }
      rethrow;
    }
  }

  Future<void> updateMultiplePedidos({
    required List<int> ids,
    required Map<String, dynamic> data,
  }) async {
    try {
      await apiClient.dio.put(
        '/pedidoProduccion/multiple',
        data: {
          'ids': ids,
          'data': data,
        },
      );
    } catch (e) {
      Log.w('Fallo de conexión al actualizar pedidos múltiples. Guardando en cola SQLite...', e);
      await localDs.updateMultiplePedidosOffline(ids: ids, data: data);
    }
  }

  Future<void> updatePedidoProduccion({
    required int id,
    required Map<String, dynamic> data,
  }) async {
    try {
      await apiClient.dio.put(
        '/pedidoProduccion/$id',
        data: data,
      );
    } catch (e) {
      Log.w('Fallo de conexión al actualizar pedido $id. Guardando en cola SQLite...', e);
      await localDs.updatePedidoProduccionOffline(id: id, data: data);
    }
  }

  Future<void> syncProcesadoReceta({
    required int pedidoId,
    required double cantidadProcesada,
  }) async {
    try {
      await apiClient.dio.post(
        '/receta/pedido/$pedidoId/sync-procesado',
        data: {
          'cantidadProcesada': cantidadProcesada,
        },
      );
    } catch (e) {
      Log.w('Fallo de conexión sincronizando receta. Guardando en cola SQLite...', e);
      await localDs.syncProcesadoRecetaOffline(
        pedidoId: pedidoId,
        cantidadProcesada: cantidadProcesada,
      );
    }
  }

  Future<void> updateRecetaLinea({
    required int id,
    required Map<String, dynamic> data,
  }) async {
    try {
      await apiClient.dio.put(
        '/receta/$id',
        data: data,
      );
    } catch (e) {
      Log.w('Fallo de conexión al actualizar receta $id. Guardando en cola SQLite...', e);
      await localDs.updateRecetaLineaOffline(id: id, data: data);
    }
  }

  Future<void> avanzarMultiEtapaDetalle({
    required List<int> detalleOrdenIds,
    required int usuarioId,
    String? comentario,
    String? fechaOrden,
    int? nuevaEtapaId,
    bool? avanzar,
  }) async {
    try {
      final body = <String, dynamic>{
        'detalleOrdenIds': detalleOrdenIds,
        'usuarioId': usuarioId,
      };
      if (comentario != null) body['comentario'] = comentario;
      if (fechaOrden != null) body['fechaOrden'] = fechaOrden;
      if (nuevaEtapaId != null) body['nuevaEtapaId'] = nuevaEtapaId;
      if (avanzar != null) body['avanzar'] = avanzar;

      await apiClient.dio.post(
        '/lineaTiempoDetalle/avanzar-multiples',
        data: body,
      );
    } catch (e) {
      Log.w('Fallo de conexión al avanzar etapas. Guardando en cola SQLite y actualizando caché...', e);
      await localDs.avanzarMultiEtapaOffline(
        detalleOrdenIds: detalleOrdenIds,
        usuarioId: usuarioId,
        comentario: comentario,
        fechaOrden: fechaOrden,
        nuevaEtapaId: nuevaEtapaId,
        avanzar: avanzar,
      );
    }
  }

  Future<void> createRechazo({
    required int usuarioId,
    required double cantidadRechazada,
    required String comentario,
    int? idPedidoProd,
    int? pedidoId,
    int? idPedidoReceta,
  }) async {
    try {
      final body = <String, dynamic>{
        'usuarioId': usuarioId,
        'cantidadRechazada': cantidadRechazada,
        'comentario': comentario,
      };
      if (idPedidoProd != null) body['id_pedidoProd'] = idPedidoProd;
      if (pedidoId != null) body['pedidoId'] = pedidoId;
      if (idPedidoReceta != null) body['id_pedidoReceta'] = idPedidoReceta;

      await apiClient.dio.post('/rechazo', data: body);
    } catch (e) {
      Log.w('Fallo de conexión al registrar rechazo. Guardando en cola SQLite...', e);
      await localDs.createRechazoOffline(
        usuarioId: usuarioId,
        cantidadRechazada: cantidadRechazada,
        comentario: comentario,
        idPedidoProd: idPedidoProd,
        pedidoId: pedidoId,
        idPedidoReceta: idPedidoReceta,
      );
    }
  }

  Future<Map<String, dynamic>> exportarOrdenFabricacionSAP({
    required List<int> ids,
    required String fecha,
    required String comentario,
    String dbsap = '',
    String ipsap = '',
  }) async {
    try {
      final response = await apiClient.dio.post(
        '/sap/deus/exportarOrdenFabricacion',
        data: {
          'ids': ids,
          'fecha': fecha,
          'comentario': comentario,
          'dbsap': dbsap,
          'ipsap': ipsap,
        },
      );
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return {'ok': true};
    } catch (e) {
      Log.w('Fallo de conexión al exportar a SAP. Guardando en cola SQLite...', e);
      await localDs.exportarOrdenFabricacionSAPOffline(
        ids: ids,
        fecha: fecha,
        comentario: comentario,
        dbsap: dbsap,
        ipsap: ipsap,
      );
      return {
        'ok': true,
        'offline': true,
        'message': 'Sin conexión. Exportación guardada localmente en cola.',
      };
    }
  }

  Future<void> saveRecetaLineaProveedores({
    required int recetaId,
    required int pedidoId,
    required List<ProveedorRecetaModel> proveedores,
    double? cantidadProcesada,
  }) async {
    try {
      final body = <String, dynamic>{
        'proveedores': proveedores.map((p) => p.toJson()).toList(),
      };
      if (cantidadProcesada != null) {
        body['cantidadProcesada'] = cantidadProcesada;
      }

      await apiClient.dio.post(
        '/receta/$recetaId/proveedores',
        data: body,
      );

      // Actualizar también en caché local SQLite
      final currentLineas = await localDs.getRecetaByPedido(pedidoId);
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
        await localDs.saveRecetaByPedido(pedidoId: pedidoId, lineas: updated);
      }
    } catch (e) {
      Log.w('Fallo de conexión al guardar proveedores de receta. Guardando en cola SQLite...', e);
      await localDs.saveRecetaLineaProveedoresOffline(
        recetaId: recetaId,
        pedidoId: pedidoId,
        proveedores: proveedores,
        cantidadProcesada: cantidadProcesada,
      );
    }
  }
}



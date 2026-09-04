import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/services/logger_service.dart';
import '../../data/produccion_datasource.dart';
import '../../domain/produccion_model.dart';
import 'produccion_supervisor_state.dart';

class ProduccionSupervisorCubit extends Cubit<ProduccionSupervisorState> {
  final ProduccionDatasource datasource;
  final SecureStorageService _storage = SecureStorageService();

  ProduccionSupervisorCubit({required this.datasource})
      : super(const ProduccionSupervisorState());

  Future<void> loadData({bool silent = false}) async {
    if (!silent) {
      emit(state.copyWith(status: ProduccionSupervisorStatus.loading, clearError: true));
    }

    try {
      final results = await Future.wait([
        datasource.getPedidosAgrupados(etapaId: 2),
        datasource.getUnassignedOrdersCount(),
        datasource.getAlmacenes(),
      ]);

      final allGroups = results[0] as List<PedidoAgrupadoModel>;
      final unassignedCount = results[1] as int;
      final almacenes = results[2] as List<AlmacenModel>;

      emit(state.copyWith(
        status: ProduccionSupervisorStatus.loaded,
        allGroups: allGroups,
        unassignedCount: unassignedCount,
        almacenes: almacenes,
      ));
    } catch (e) {
      Log.e('Error cargando pedidos de supervisor', e);
      emit(state.copyWith(
        status: ProduccionSupervisorStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  void setCountryFilter(String? val) {
    emit(state.copyWith(countryFilter: val, clearCountry: val == null));
  }

  void setClientFilter(String? val) {
    emit(state.copyWith(clientFilter: val, clearClient: val == null));
  }

  void setDeuFilter(String? val) {
    emit(state.copyWith(deuFilter: val, clearDeu: val == null));
  }

  void setStateFilter(String? val) {
    emit(state.copyWith(stateFilter: val, clearState: val == null));
  }

  void setDateMode(String mode) {
    emit(state.copyWith(dateMode: mode));
  }

  void setSelectedDate(String? date) {
    emit(state.copyWith(selectedDate: date));
  }

  void setDateType(String type) {
    emit(state.copyWith(dateType: type));
  }

  void setViewMode(String mode) {
    emit(state.copyWith(viewMode: mode));
  }

  void selectOrder(PedidoAgrupadoModel? order) {
    emit(state.copyWith(
      selectedOrder: order,
      clearSelectedOrder: order == null,
    ));
  }

  void toggleDeuCollapse(String deuCode) {
    final updated = Set<String>.from(state.collapsedDeus);
    if (updated.contains(deuCode)) {
      updated.remove(deuCode);
    } else {
      updated.add(deuCode);
    }
    emit(state.copyWith(collapsedDeus: updated));
  }

  void toggleSelectItem(String key) {
    final updated = Set<String>.from(state.selectedKeys);
    if (updated.contains(key)) {
      updated.remove(key);
    } else {
      updated.add(key);
    }
    emit(state.copyWith(selectedKeys: updated));
  }

  void toggleSelectAll() {
    final allKeys = state.consolidatedItems.map((i) => i.key).toSet();
    if (state.selectedKeys.length == allKeys.length) {
      emit(state.copyWith(selectedKeys: {}));
    } else {
      emit(state.copyWith(selectedKeys: allKeys));
    }
  }

  Future<void> toggleExpandReceta(ConsolidatedProductModel item) async {
    final currentExpanded = Map<String, List<RecetaLineaModel>>.from(state.expandedRecetas);

    if (currentExpanded.containsKey(item.key)) {
      currentExpanded.remove(item.key);
      emit(state.copyWith(expandedRecetas: currentExpanded));
      return;
    }

    final primaryOrder = item.originalItems.isNotEmpty ? item.originalItems.first : null;
    if (primaryOrder == null) return;

    final loadingKeys = Set<String>.from(state.loadingRecetaKeys)..add(item.key);
    emit(state.copyWith(loadingRecetaKeys: loadingKeys));

    try {
      final lineas = await datasource.getRecetaByPedido(
        primaryOrder.id,
      );
      currentExpanded[item.key] = lineas;
      final updatedLoading = Set<String>.from(state.loadingRecetaKeys)..remove(item.key);
      emit(state.copyWith(
        expandedRecetas: currentExpanded,
        loadingRecetaKeys: updatedLoading,
      ));
    } catch (e) {
      Log.e('Error cargando receta para ${item.productoNombre}', e);
      final updatedLoading = Set<String>.from(state.loadingRecetaKeys)..remove(item.key);
      emit(state.copyWith(
        loadingRecetaKeys: updatedLoading,
        errorMessage: 'No se pudo cargar la receta del producto',
      ));
    }
  }

  Future<void> updateProcesado(ConsolidatedProductModel item, double newQty) async {
    final primaryOrder = item.originalItems.isNotEmpty ? item.originalItems.first : null;
    if (primaryOrder == null) return;

    final updatedGroups = state.allGroups.map((g) {
      final updatedItems = g.items.map((it) {
        if (it.deudorCodigo == item.deudorCodigo &&
            it.productoNombre == item.productoNombre) {
          return it.copyWith(cantidad: newQty);
        }
        return it;
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

    emit(state.copyWith(allGroups: updatedGroups));

    try {
      final ids = item.originalItems.map((i) => i.id).toList();
      await datasource.updateMultiplePedidos(
        ids: ids,
        data: {'cantidad': newQty},
      );
      await datasource.syncProcesadoReceta(
        pedidoId: primaryOrder.id,
        cantidadProcesada: newQty,
      );
    } catch (e) {
      Log.e('Error actualizando procesado', e);
      emit(state.copyWith(errorMessage: 'Error al actualizar cantidad procesada'));
      await loadData(silent: true);
    }
  }

  Future<void> updateTrazabilidadDig(ConsolidatedProductModel item, String value) async {
    final ids = item.originalItems.map((i) => i.id).toList();
    if (ids.isEmpty) return;

    try {
      await datasource.updateMultiplePedidos(
        ids: ids,
        data: {'trazabilidad_Dig': value.trim()},
      );
      final updatedGroups = state.allGroups.map((g) {
        final updatedItems = g.items.map((it) {
          if (ids.contains(it.id)) {
            return it.copyWith(trazabilidadDig: value.trim());
          }
          return it;
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

      emit(state.copyWith(allGroups: updatedGroups));
    } catch (e) {
      Log.e('Error actualizando trazabilidad', e);
      emit(state.copyWith(errorMessage: 'No se pudo guardar la trazabilidad'));
    }
  }

  Future<void> updateCompleto(ConsolidatedProductModel item, bool isComplete) async {
    final ids = item.originalItems.map((i) => i.id).toList();
    if (ids.isEmpty) return;

    try {
      await datasource.updateMultiplePedidos(
        ids: ids,
        data: {'completo': isComplete},
      );
      final updatedGroups = state.allGroups.map((g) {
        final updatedItems = g.items.map((it) {
          if (ids.contains(it.id)) {
            return it.copyWith(completo: isComplete);
          }
          return it;
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

      emit(state.copyWith(allGroups: updatedGroups));
    } catch (e) {
      Log.e('Error actualizando estado completo', e);
      emit(state.copyWith(errorMessage: 'No se pudo actualizar estado'));
    }
  }

  Future<void> updateAlmacen(ConsolidatedProductModel item, int almacenId) async {
    final ids = item.originalItems.map((i) => i.id).toList();
    if (ids.isEmpty) return;

    try {
      await datasource.updateMultiplePedidos(
        ids: ids,
        data: {'id_almacen': almacenId},
      );
      final updatedGroups = state.allGroups.map((g) {
        final updatedItems = g.items.map((it) {
          if (ids.contains(it.id)) {
            return it.copyWith(idAlmacen: almacenId);
          }
          return it;
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

      emit(state.copyWith(allGroups: updatedGroups));
    } catch (e) {
      Log.e('Error actualizando almacén', e);
      emit(state.copyWith(errorMessage: 'No se pudo actualizar el almacén'));
    }
  }

  Future<void> toggleMaterialState(int recetaId, bool newState, String productKey) async {
    final currentExpanded = Map<String, List<RecetaLineaModel>>.from(state.expandedRecetas);
    final list = currentExpanded[productKey];
    if (list == null) return;

    final updatedList = list.map((l) => l.id == recetaId ? l.copyWith(state: newState) : l).toList();
    currentExpanded[productKey] = updatedList;
    emit(state.copyWith(expandedRecetas: currentExpanded));

    try {
      await datasource.updateRecetaLinea(
        id: recetaId,
        data: {'state': newState},
      );
    } catch (e) {
      Log.e('Error actualizando estado de material', e);
    }
  }

  Future<void> avanzarADigitador() async {
    if (state.selectedKeys.isEmpty) return;

    emit(state.copyWith(isSaving: true, clearError: true, clearSuccess: true));

    try {
      final userIdStr = await _storage.getUserId();
      final userId = int.tryParse(userIdStr ?? '1') ?? 1;

      final detalleIds = <int>{};
      for (final key in state.selectedKeys) {
        final item = state.consolidatedItems.firstWhere((i) => i.key == key);
        for (final orig in item.originalItems) {
          if (orig.idDetallePedido != null) {
            detalleIds.add(orig.idDetallePedido!);
          } else {
            detalleIds.add(orig.id);
          }
        }
      }

      if (detalleIds.isEmpty) {
        emit(state.copyWith(
          isSaving: false,
          errorMessage: 'No se encontraron IDs válidos para avanzar',
        ));
        return;
      }

      await datasource.avanzarMultiEtapaDetalle(
        detalleOrdenIds: detalleIds.toList(),
        usuarioId: userId,
        avanzar: true,
      );

      emit(state.copyWith(
        isSaving: false,
        selectedKeys: {},
        successMessage: 'Se avanzaron ${state.selectedKeys.length} productos a Digitador con éxito.',
      ));

      await loadData(silent: true);
    } catch (e) {
      Log.e('Error al avanzar a digitador', e);
      emit(state.copyWith(
        isSaving: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  Future<void> aceptarPedido(PedidoAgrupadoModel order, {String? comentario}) async {
    emit(state.copyWith(isSaving: true, clearError: true, clearSuccess: true));

    try {
      final userIdStr = await _storage.getUserId();
      final userId = int.tryParse(userIdStr ?? '1') ?? 1;

      final detalleIds = order.items
          .map((i) => i.idDetallePedido ?? i.id)
          .toList();

      if (detalleIds.isNotEmpty) {
        await datasource.avanzarMultiEtapaDetalle(
          detalleOrdenIds: detalleIds,
          usuarioId: userId,
          comentario: comentario,
          avanzar: true,
        );
      }

      emit(state.copyWith(
        isSaving: false,
        clearSelectedOrder: true,
        successMessage: 'Pedido #${order.pedidoId} aceptado y avanzado a Digitador.',
      ));

      await loadData(silent: true);
    } catch (e) {
      Log.e('Error al aceptar pedido de supervisor', e);
      emit(state.copyWith(
        isSaving: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  Future<void> saveRecetaProveedores({
    required int recetaId,
    required int pedidoId,
    required String productKey,
    required List<ProveedorRecetaModel> proveedores,
    double? cantidadProcesada,
  }) async {
    final currentExpanded = Map<String, List<RecetaLineaModel>>.from(state.expandedRecetas);
    final list = currentExpanded[productKey];
    if (list != null) {
      final totalQty = proveedores.fold<double>(0.0, (sum, p) => sum + p.cantidad);
      final updatedList = list.map((l) {
        if (l.id == recetaId) {
          return l.copyWith(
            cantidadBase: totalQty > 0 ? totalQty : l.cantidadBase,
            proveedores: proveedores,
          );
        }
        return l;
      }).toList();
      currentExpanded[productKey] = updatedList;
      emit(state.copyWith(expandedRecetas: currentExpanded));
    }

    try {
      await datasource.saveRecetaLineaProveedores(
        recetaId: recetaId,
        pedidoId: pedidoId,
        proveedores: proveedores,
        cantidadProcesada: cantidadProcesada,
      );
    } catch (e) {
      Log.e('Error guardando proveedores de receta', e);
    }
  }

  Future<void> registrarRechazo({
    required int usuarioId,
    required double cantidad,
    required String comentario,
    int? idPedidoProd,
    int? pedidoId,
    int? idPedidoReceta,
  }) async {
    try {
      await datasource.createRechazo(
        usuarioId: usuarioId,
        cantidadRechazada: cantidad,
        comentario: comentario,
        idPedidoProd: idPedidoProd,
        pedidoId: pedidoId,
        idPedidoReceta: idPedidoReceta,
      );
      emit(state.copyWith(
        successMessage: 'Rechazo de $cantidad registrado correctamente.',
      ));
    } catch (e) {
      Log.e('Error al registrar rechazo', e);
      emit(state.copyWith(
        errorMessage: 'Error al registrar rechazo: ${e.toString().replaceAll('Exception: ', '')}',
      ));
    }
  }

  void clearMessages() {
    emit(state.copyWith(clearError: true, clearSuccess: true));
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/logger_service.dart';
import '../../data/produccion_datasource.dart';
import '../../domain/produccion_model.dart';
import 'produccion_fabricacion_state.dart';

class ProduccionFabricacionCubit extends Cubit<ProduccionFabricacionState> {
  final ProduccionDatasource datasource;

  ProduccionFabricacionCubit({required this.datasource})
      : super(const ProduccionFabricacionState());

  Future<void> loadData({bool silent = false}) async {
    if (!silent) {
      emit(state.copyWith(status: ProduccionFabricacionStatus.loading, clearError: true));
    }

    try {
      final results = await Future.wait([
        datasource.getPedidosAgrupados(etapaId: 3),
        datasource.getAlmacenes(),
      ]);

      final allGroups = results[0] as List<PedidoAgrupadoModel>;
      final almacenes = results[1] as List<AlmacenModel>;

      emit(state.copyWith(
        status: ProduccionFabricacionStatus.loaded,
        allGroups: allGroups,
        almacenes: almacenes,
      ));
    } catch (e) {
      Log.e('Error cargando órdenes de fabricación', e);
      emit(state.copyWith(
        status: ProduccionFabricacionStatus.error,
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

  Future<void> cargarASAP({
    required String fecha,
    required String comentario,
  }) async {
    if (state.selectedKeys.isEmpty) return;

    emit(state.copyWith(isSaving: true, clearError: true, clearSuccess: true));

    try {
      final productIds = <int>[];
      for (final key in state.selectedKeys) {
        final item = state.consolidatedItems.firstWhere((i) => i.key == key);
        for (final orig in item.originalItems) {
          productIds.add(orig.id);
        }
      }

      final res = await datasource.exportarOrdenFabricacionSAP(
        ids: productIds,
        fecha: fecha,
        comentario: comentario,
      );

      final isOffline = res['offline'] == true;
      final successMsg = isOffline
          ? 'Exportación guardada en cola sin conexión. Se enviará a SAP automáticamente al conectar a internet.'
          : 'Se exportaron ${state.selectedKeys.length} productos a SAP correctamente.';

      emit(state.copyWith(
        isSaving: false,
        selectedKeys: {},
        successMessage: successMsg,
      ));

      await loadData(silent: true);
    } catch (e) {
      Log.e('Error exportando a SAP', e);
      emit(state.copyWith(
        isSaving: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  void clearMessages() {
    emit(state.copyWith(clearError: true, clearSuccess: true));
  }
}

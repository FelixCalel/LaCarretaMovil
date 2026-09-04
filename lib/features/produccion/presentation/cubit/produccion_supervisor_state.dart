import '../../domain/produccion_model.dart';

enum ProduccionSupervisorStatus { initial, loading, loaded, error }

class ProduccionSupervisorState {
  final ProduccionSupervisorStatus status;
  final String? errorMessage;
  final String? successMessage;
  final bool isSaving;
  final int unassignedCount;
  final List<PedidoAgrupadoModel> allGroups;
  final List<AlmacenModel> almacenes;

  // Filtros
  final String? countryFilter;
  final String? clientFilter;
  final String? deuFilter;
  final String? stateFilter;
  final String dateMode; // 'all', 'today', 'custom'
  final String? selectedDate; // YYYY-MM-DD
  final String dateType; // 'entrega', 'sap'

  // Modo: 'consolidado' | 'porPedido'
  final String viewMode;

  // Selección múltiple para "Pasar a Digitador"
  final Set<String> selectedKeys;

  // Expansión de recetas
  final Map<String, List<RecetaLineaModel>> expandedRecetas;
  final Set<String> loadingRecetaKeys;

  // Acordeón colapsado por DEU
  final Set<String> collapsedDeus;

  // Pedido seleccionado para vista de detalle
  final PedidoAgrupadoModel? selectedOrder;

  const ProduccionSupervisorState({
    this.status = ProduccionSupervisorStatus.initial,
    this.errorMessage,
    this.successMessage,
    this.isSaving = false,
    this.unassignedCount = 0,
    this.allGroups = const [],
    this.almacenes = const [],
    this.countryFilter,
    this.clientFilter,
    this.deuFilter,
    this.stateFilter,
    this.dateMode = 'all',
    this.selectedDate,
    this.dateType = 'entrega',
    this.viewMode = 'consolidado',
    this.selectedKeys = const {},
    this.expandedRecetas = const {},
    this.loadingRecetaKeys = const {},
    this.collapsedDeus = const {},
    this.selectedOrder,
  });

  bool get isLoading => status == ProduccionSupervisorStatus.loading;

  List<String> get availableCountries {
    final set = <String>{};
    for (final g in allGroups) {
      if (g.pais.isNotEmpty) set.add(g.pais);
    }
    final list = set.toList()..sort();
    return list;
  }

  List<String> get availableClients {
    final set = <String>{};
    for (final g in allGroups) {
      if (g.tienda.isNotEmpty) set.add(g.tienda);
    }
    final list = set.toList()..sort();
    return list;
  }

  List<String> get availableDeudores {
    final set = <String>{};
    for (final g in allGroups) {
      if (g.deudorCodigo.isNotEmpty) set.add(g.deudorCodigo);
    }
    final list = set.toList()..sort();
    return list;
  }

  List<PedidoAgrupadoModel> get filteredGroups {
    final now = DateTime.now();
    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final effectiveDate = dateMode == 'today' ? todayStr : selectedDate;

    return allGroups.where((g) {
      if (countryFilter != null &&
          countryFilter!.isNotEmpty &&
          g.pais != countryFilter) {
        return false;
      }
      if (clientFilter != null &&
          clientFilter!.isNotEmpty &&
          g.tienda != clientFilter) {
        return false;
      }
      if (deuFilter != null &&
          deuFilter!.isNotEmpty &&
          g.deudorCodigo != deuFilter) {
        return false;
      }

      if (dateMode != 'all' && effectiveDate != null && effectiveDate.isNotEmpty) {
        final firstItem = g.items.isNotEmpty ? g.items.first : null;
        final rawDate = dateType == 'sap'
            ? (firstItem?.fechaOrdenSap ?? g.fechaOrdenSap)
            : (firstItem?.fechaPedido ?? g.fechaPedido);

        if (rawDate == null || !rawDate.startsWith(effectiveDate)) {
          return false;
        }
      }

      if (stateFilter != null && stateFilter!.isNotEmpty) {
        final total = g.items.length;
        final done = g.items.where((i) => i.completo).length;
        final inProgress = g.items.any((i) => i.cantidad > 0);

        final status = done == total
            ? 'Completado'
            : inProgress
                ? 'En Proceso'
                : 'Pendiente';
        if (status != stateFilter) return false;
      }

      return true;
    }).toList();
  }

  List<ConsolidatedProductModel> get consolidatedItems {
    final map = <String, ConsolidatedProductModel>{};

    for (final group in filteredGroups) {
      for (final item in group.items) {
        final key = "${item.deudorCodigo}|${item.productoNombre}";

        if (map.containsKey(key)) {
          final existing = map[key]!;
          final updatedOriginal = List<PedidoProduccionModel>.from(existing.originalItems)..add(item);
          map[key] = existing.copyWith(
            originalItems: updatedOriginal,
          )._sumQuantities(item.cantidadUnidad, item.cantidad);
        } else {
          map[key] = ConsolidatedProductModel(
            key: key,
            deudorCodigo: item.deudorCodigo,
            deudorNombre: item.deudorNombre,
            tienda: item.tienda,
            pais: item.pais,
            productoNombre: item.productoNombre,
            itemCode: item.itemCode,
            cantidadUnidadTotal: item.cantidadUnidad,
            cantidadProcesada: item.cantidad,
            completo: item.completo,
            trazabilidadDig: item.trazabilidadDig ?? '',
            trazabilidadProd: item.trazabilidadProd ?? '',
            idAlmacen: item.idAlmacen,
            originalItems: [item],
          );
        }
      }
    }

    final list = map.values.toList();
    list.sort((a, b) {
      final cDeu = a.deudorCodigo.compareTo(b.deudorCodigo);
      if (cDeu != 0) return cDeu;
      return a.productoNombre.compareTo(b.productoNombre);
    });
    return list;
  }

  ProduccionSupervisorState copyWith({
    ProduccionSupervisorStatus? status,
    String? errorMessage,
    String? successMessage,
    bool? isSaving,
    int? unassignedCount,
    List<PedidoAgrupadoModel>? allGroups,
    List<AlmacenModel>? almacenes,
    String? countryFilter,
    String? clientFilter,
    String? deuFilter,
    String? stateFilter,
    String? dateMode,
    String? selectedDate,
    String? dateType,
    String? viewMode,
    Set<String>? selectedKeys,
    Map<String, List<RecetaLineaModel>>? expandedRecetas,
    Set<String>? loadingRecetaKeys,
    Set<String>? collapsedDeus,
    PedidoAgrupadoModel? selectedOrder,
    bool clearCountry = false,
    bool clearClient = false,
    bool clearDeu = false,
    bool clearState = false,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearSelectedOrder = false,
  }) {
    return ProduccionSupervisorState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      isSaving: isSaving ?? this.isSaving,
      unassignedCount: unassignedCount ?? this.unassignedCount,
      allGroups: allGroups ?? this.allGroups,
      almacenes: almacenes ?? this.almacenes,
      countryFilter: clearCountry ? null : (countryFilter ?? this.countryFilter),
      clientFilter: clearClient ? null : (clientFilter ?? this.clientFilter),
      deuFilter: clearDeu ? null : (deuFilter ?? this.deuFilter),
      stateFilter: clearState ? null : (stateFilter ?? this.stateFilter),
      dateMode: dateMode ?? this.dateMode,
      selectedDate: selectedDate ?? this.selectedDate,
      dateType: dateType ?? this.dateType,
      viewMode: viewMode ?? this.viewMode,
      selectedKeys: selectedKeys ?? this.selectedKeys,
      expandedRecetas: expandedRecetas ?? this.expandedRecetas,
      loadingRecetaKeys: loadingRecetaKeys ?? this.loadingRecetaKeys,
      collapsedDeus: collapsedDeus ?? this.collapsedDeus,
      selectedOrder: clearSelectedOrder ? null : (selectedOrder ?? this.selectedOrder),
    );
  }
}

extension _ConsolidatedSupervisorProductSum on ConsolidatedProductModel {
  ConsolidatedProductModel _sumQuantities(double addUnidad, double addProcesada) {
    return ConsolidatedProductModel(
      key: key,
      deudorCodigo: deudorCodigo,
      deudorNombre: deudorNombre,
      tienda: tienda,
      pais: pais,
      productoNombre: productoNombre,
      itemCode: itemCode,
      cantidadUnidadTotal: cantidadUnidadTotal + addUnidad,
      cantidadProcesada: cantidadProcesada + addProcesada,
      completo: completo,
      trazabilidadDig: trazabilidadDig,
      trazabilidadProd: trazabilidadProd,
      idAlmacen: idAlmacen,
      originalItems: originalItems,
    );
  }
}

import '../../domain/produccion_model.dart';

enum ProduccionDigitadorStatus { initial, loading, loaded, error }

class DigitadorConsolidatedItem {
  final String key;
  final String itemCode;
  final String productoNombre;
  final String unidad;
  final double cantSolicitada;
  final double cantDespacho;
  final String deudorCodigo;
  final String deudorNombre;
  final String fecha;
  final String pais;
  final int etapaId;
  final bool completo;
  final String? docNum;
  final Set<String> trazabilidadesDig;
  final Set<String> trazabilidadesPro;

  DigitadorConsolidatedItem({
    required this.key,
    required this.itemCode,
    required this.productoNombre,
    required this.unidad,
    required this.cantSolicitada,
    required this.cantDespacho,
    required this.deudorCodigo,
    required this.deudorNombre,
    required this.fecha,
    required this.pais,
    required this.etapaId,
    required this.completo,
    this.docNum,
    required this.trazabilidadesDig,
    required this.trazabilidadesPro,
  });

  String get estadoLabel {
    if (etapaId >= 4 || (docNum != null && docNum!.isNotEmpty)) {
      return 'EXPORTADO';
    }
    if (etapaId == 3 || completo) {
      return 'FABRICADO';
    }
    if (etapaId == 2) {
      return 'EN PROCESO';
    }
    return 'PENDIENTE';
  }
}

class ProduccionDigitadorState {
  final ProduccionDigitadorStatus status;
  final String? errorMessage;
  final String? successMessage;
  final List<PedidoAgrupadoModel> allGroups;

  // Filtros
  final String searchTerm;
  final String? countryFilter;
  final String? clientFilter;
  final String? deuFilter;
  final String dateMode; // 'all', 'today', 'custom'
  final String? selectedDate; // YYYY-MM-DD
  final String dateType; // 'entrega', 'sap'

  // Modo: 'consolidado' | 'porPedido'
  final String viewMode;

  // Acordeón colapsado por DEU / Sección
  final Set<String> collapsedSections;

  // Pedido seleccionado para detalle
  final PedidoAgrupadoModel? selectedOrder;

  const ProduccionDigitadorState({
    this.status = ProduccionDigitadorStatus.initial,
    this.errorMessage,
    this.successMessage,
    this.allGroups = const [],
    this.searchTerm = '',
    this.countryFilter,
    this.clientFilter,
    this.deuFilter,
    this.dateMode = 'all',
    this.selectedDate,
    this.dateType = 'entrega',
    this.viewMode = 'consolidado',
    this.collapsedSections = const {},
    this.selectedOrder,
  });

  bool get isLoading => status == ProduccionDigitadorStatus.loading;

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
    final lowerTerm = searchTerm.trim().toLowerCase();

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

      if (lowerTerm.isNotEmpty) {
        final matchesPedido = g.pedidoId.toString().contains(lowerTerm);
        final matchesTienda = g.tienda.toLowerCase().contains(lowerTerm);
        final matchesItems = g.items.any((it) {
          final pName = it.productoNombre.toLowerCase();
          final code = (it.itemCode ?? '').toLowerCase();
          final tDig = (it.trazabilidadDig ?? '').toLowerCase();
          final tProd = (it.trazabilidadProd ?? '').toLowerCase();
          return pName.contains(lowerTerm) ||
              code.contains(lowerTerm) ||
              tDig.contains(lowerTerm) ||
              tProd.contains(lowerTerm);
        });

        if (!matchesPedido && !matchesTienda && !matchesItems) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  // Lista consolidada por DEU + Producto
  List<DigitadorConsolidatedItem> get consolidatedItems {
    final map = <String, DigitadorConsolidatedItem>{};

    for (final group in filteredGroups) {
      for (final item in group.items) {
        final code = item.itemCode ?? item.productoNombre;
        final key = "${item.deudorCodigo}|$code";

        final rawDate = dateType == 'sap'
            ? (item.fechaOrdenSap ?? group.fechaOrdenSap ?? 'Sin Fecha')
            : (item.fechaPedido ?? group.fechaPedido ?? 'Sin Fecha');

        if (map.containsKey(key)) {
          final existing = map[key]!;
          final digSet = Set<String>.from(existing.trazabilidadesDig);
          if (item.trazabilidadDig != null && item.trazabilidadDig!.isNotEmpty) {
            digSet.add(item.trazabilidadDig!);
          }
          final proSet = Set<String>.from(existing.trazabilidadesPro);
          if (item.trazabilidadProd != null && item.trazabilidadProd!.isNotEmpty) {
            proSet.add(item.trazabilidadProd!);
          }

          map[key] = DigitadorConsolidatedItem(
            key: key,
            itemCode: existing.itemCode,
            productoNombre: existing.productoNombre,
            unidad: existing.unidad,
            cantSolicitada: existing.cantSolicitada + item.cantidadUnidad,
            cantDespacho: existing.cantDespacho + item.cantidad,
            deudorCodigo: existing.deudorCodigo,
            deudorNombre: existing.deudorNombre,
            fecha: existing.fecha,
            pais: existing.pais,
            etapaId: item.idDetallePedido != null ? 3 : existing.etapaId,
            completo: existing.completo && item.completo,
            docNum: existing.docNum,
            trazabilidadesDig: digSet,
            trazabilidadesPro: proSet,
          );
        } else {
          final digSet = <String>{};
          if (item.trazabilidadDig != null && item.trazabilidadDig!.isNotEmpty) {
            digSet.add(item.trazabilidadDig!);
          }
          final proSet = <String>{};
          if (item.trazabilidadProd != null && item.trazabilidadProd!.isNotEmpty) {
            proSet.add(item.trazabilidadProd!);
          }

          map[key] = DigitadorConsolidatedItem(
            key: key,
            itemCode: item.itemCode ?? '—',
            productoNombre: item.productoNombre,
            unidad: item.unidadMedida ?? 'UND',
            cantSolicitada: item.cantidadUnidad,
            cantDespacho: item.cantidad,
            deudorCodigo: item.deudorCodigo,
            deudorNombre: item.deudorNombre.isNotEmpty ? item.deudorNombre : item.tienda,
            fecha: rawDate,
            pais: item.pais,
            etapaId: 3,
            completo: item.completo,
            docNum: null,
            trazabilidadesDig: digSet,
            trazabilidadesPro: proSet,
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

  ProduccionDigitadorState copyWith({
    ProduccionDigitadorStatus? status,
    String? errorMessage,
    String? successMessage,
    List<PedidoAgrupadoModel>? allGroups,
    String? searchTerm,
    String? countryFilter,
    String? clientFilter,
    String? deuFilter,
    String? dateMode,
    String? selectedDate,
    String? dateType,
    String? viewMode,
    Set<String>? collapsedSections,
    PedidoAgrupadoModel? selectedOrder,
    bool clearCountry = false,
    bool clearClient = false,
    bool clearDeu = false,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearSelectedOrder = false,
  }) {
    return ProduccionDigitadorState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      allGroups: allGroups ?? this.allGroups,
      searchTerm: searchTerm ?? this.searchTerm,
      countryFilter: clearCountry ? null : (countryFilter ?? this.countryFilter),
      clientFilter: clearClient ? null : (clientFilter ?? this.clientFilter),
      deuFilter: clearDeu ? null : (deuFilter ?? this.deuFilter),
      dateMode: dateMode ?? this.dateMode,
      selectedDate: selectedDate ?? this.selectedDate,
      dateType: dateType ?? this.dateType,
      viewMode: viewMode ?? this.viewMode,
      collapsedSections: collapsedSections ?? this.collapsedSections,
      selectedOrder: clearSelectedOrder ? null : (selectedOrder ?? this.selectedOrder),
    );
  }
}

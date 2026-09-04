class PedidoProduccionModel {
  final int id;
  final int? productoId;
  final int? idAsigArea;
  final double cantidadUnidad;
  final int? idUnidadMedida;
  final int? noBatch;
  final bool completo;
  final double? despacho;
  final double? faltante;
  final double cantidad; // cantidad procesada
  final String? trazabilidadProd;
  final String? trazabilidadDig;
  final double? mpUtilizada;
  final double? mp1ra;
  final double? mp2da;
  final double? mp3ra;
  final double? mpSobrante;
  final int? rechazoId;
  final double? cantidadRechazada;
  final double? basura;
  final double? detergente;
  final double? desinfectante;
  final double? conservante;
  final double? antioxidante;
  final String? createdAt;
  final String? updatedAt;
  final int? createdBy;
  final int? updatedBy;
  final bool state;
  final int? idDetallePedido;
  final String? itemCode;
  final String productoNombre;
  final String tienda;
  final String pais;
  final String deudorCodigo;
  final String deudorNombre;
  final String? unidadMedida;
  final String? fechaPedido;
  final String? fechaOrdenSap;
  final int? idAlmacen;
  final String? codigoAlmacen;

  PedidoProduccionModel({
    required this.id,
    this.productoId,
    this.idAsigArea,
    required this.cantidadUnidad,
    this.idUnidadMedida,
    this.noBatch,
    required this.completo,
    this.despacho,
    this.faltante,
    required this.cantidad,
    this.trazabilidadProd,
    this.trazabilidadDig,
    this.mpUtilizada,
    this.mp1ra,
    this.mp2da,
    this.mp3ra,
    this.mpSobrante,
    this.rechazoId,
    this.cantidadRechazada,
    this.basura,
    this.detergente,
    this.desinfectante,
    this.conservante,
    this.antioxidante,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    required this.state,
    this.idDetallePedido,
    this.itemCode,
    required this.productoNombre,
    required this.tienda,
    required this.pais,
    required this.deudorCodigo,
    required this.deudorNombre,
    this.unidadMedida,
    this.fechaPedido,
    this.fechaOrdenSap,
    this.idAlmacen,
    this.codigoAlmacen,
  });

  factory PedidoProduccionModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value, [double defaultValue = 0.0]) {
      if (value == null) return defaultValue;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? defaultValue;
    }

    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    return PedidoProduccionModel(
      id: parseInt(json['id']) ?? 0,
      productoId: parseInt(json['productoId']),
      idAsigArea: parseInt(json['id_asigArea']),
      cantidadUnidad: parseDouble(json['cantidadUnidad']),
      idUnidadMedida: parseInt(json['id_unidadMedida']),
      noBatch: parseInt(json['NoBatch']),
      completo: json['completo'] == true || json['completo'] == 1 || json['completo'] == 'true',
      despacho: json['despacho'] != null ? parseDouble(json['despacho']) : null,
      faltante: json['faltante'] != null ? parseDouble(json['faltante']) : null,
      cantidad: parseDouble(json['cantidad']),
      trazabilidadProd: json['trazabilidad_Prod']?.toString(),
      trazabilidadDig: json['trazabilidad_Dig']?.toString(),
      mpUtilizada: json['mpUtilizada'] != null ? parseDouble(json['mpUtilizada']) : null,
      mp1ra: json['mp1ra'] != null ? parseDouble(json['mp1ra']) : null,
      mp2da: json['mp2da'] != null ? parseDouble(json['mp2da']) : null,
      mp3ra: json['mp3ra'] != null ? parseDouble(json['mp3ra']) : null,
      mpSobrante: json['mpSobrante'] != null ? parseDouble(json['mpSobrante']) : null,
      rechazoId: parseInt(json['rechazoId']),
      cantidadRechazada: json['cantidadRechazada'] != null ? parseDouble(json['cantidadRechazada']) : null,
      basura: json['basura'] != null ? parseDouble(json['basura']) : null,
      detergente: json['detergente'] != null ? parseDouble(json['detergente']) : null,
      desinfectante: json['Desinfectante'] != null ? parseDouble(json['Desinfectante']) : null,
      conservante: json['conservante'] != null ? parseDouble(json['conservante']) : null,
      antioxidante: json['Antioxidante'] != null ? parseDouble(json['Antioxidante']) : null,
      createdAt: json['create_at']?.toString(),
      updatedAt: json['update_at']?.toString(),
      createdBy: parseInt(json['create_by']),
      updatedBy: parseInt(json['update_by']),
      state: json['state'] != false,
      idDetallePedido: parseInt(json['id_detallePedido']),
      itemCode: json['itemCode']?.toString(),
      productoNombre: json['productoNombre']?.toString() ?? '',
      tienda: json['tienda']?.toString() ?? '',
      pais: json['pais']?.toString() ?? '',
      deudorCodigo: json['deudorCodigo']?.toString() ?? '',
      deudorNombre: json['deudorNombre']?.toString() ?? '',
      unidadMedida: json['unidadMedida']?.toString(),
      fechaPedido: json['fechaPedido']?.toString(),
      fechaOrdenSap: json['fecha_orden_sap']?.toString(),
      idAlmacen: parseInt(json['id_almacen'] ?? json['almacen']?['id']),
      codigoAlmacen: json['codigoAlmacen']?.toString(),
    );
  }

  PedidoProduccionModel copyWith({
    double? cantidad,
    bool? completo,
    String? trazabilidadProd,
    String? trazabilidadDig,
    int? idAlmacen,
  }) {
    return PedidoProduccionModel(
      id: id,
      productoId: productoId,
      idAsigArea: idAsigArea,
      cantidadUnidad: cantidadUnidad,
      idUnidadMedida: idUnidadMedida,
      noBatch: noBatch,
      completo: completo ?? this.completo,
      despacho: despacho,
      faltante: faltante,
      cantidad: cantidad ?? this.cantidad,
      trazabilidadProd: trazabilidadProd ?? this.trazabilidadProd,
      trazabilidadDig: trazabilidadDig ?? this.trazabilidadDig,
      mpUtilizada: mpUtilizada,
      mp1ra: mp1ra,
      mp2da: mp2da,
      mp3ra: mp3ra,
      mpSobrante: mpSobrante,
      rechazoId: rechazoId,
      cantidadRechazada: cantidadRechazada,
      basura: basura,
      detergente: detergente,
      desinfectante: desinfectante,
      conservante: conservante,
      antioxidante: antioxidante,
      createdAt: createdAt,
      updatedAt: updatedAt,
      createdBy: createdBy,
      updatedBy: updatedBy,
      state: state,
      idDetallePedido: idDetallePedido,
      itemCode: itemCode,
      productoNombre: productoNombre,
      tienda: tienda,
      pais: pais,
      deudorCodigo: deudorCodigo,
      deudorNombre: deudorNombre,
      unidadMedida: unidadMedida,
      fechaPedido: fechaPedido,
      fechaOrdenSap: fechaOrdenSap,
      idAlmacen: idAlmacen ?? this.idAlmacen,
      codigoAlmacen: codigoAlmacen,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productoId': productoId,
      'id_asigArea': idAsigArea,
      'cantidadUnidad': cantidadUnidad,
      'id_unidadMedida': idUnidadMedida,
      'NoBatch': noBatch,
      'completo': completo,
      'despacho': despacho,
      'faltante': faltante,
      'cantidad': cantidad,
      'trazabilidad_Prod': trazabilidadProd,
      'trazabilidad_Dig': trazabilidadDig,
      'mpUtilizada': mpUtilizada,
      'mp1ra': mp1ra,
      'mp2da': mp2da,
      'mp3ra': mp3ra,
      'mpSobrante': mpSobrante,
      'rechazoId': rechazoId,
      'cantidadRechazada': cantidadRechazada,
      'basura': basura,
      'detergente': detergente,
      'Desinfectante': desinfectante,
      'conservante': conservante,
      'Antioxidante': antioxidante,
      'create_at': createdAt,
      'update_at': updatedAt,
      'create_by': createdBy,
      'update_by': updatedBy,
      'state': state,
      'id_detallePedido': idDetallePedido,
      'itemCode': itemCode,
      'productoNombre': productoNombre,
      'tienda': tienda,
      'pais': pais,
      'deudorCodigo': deudorCodigo,
      'deudorNombre': deudorNombre,
      'unidadMedida': unidadMedida,
      'fechaPedido': fechaPedido,
      'fecha_orden_sap': fechaOrdenSap,
      'id_almacen': idAlmacen,
      'codigoAlmacen': codigoAlmacen,
    };
  }
}

class PedidoAgrupadoModel {
  final int pedidoId;
  final String tienda;
  final String pais;
  final String deudorCodigo;
  final String deudorNombre;
  final String? fechaPedido;
  final String? fechaOrdenSap;
  final List<PedidoProduccionModel> items;

  PedidoAgrupadoModel({
    required this.pedidoId,
    required this.tienda,
    required this.pais,
    required this.deudorCodigo,
    required this.deudorNombre,
    this.fechaPedido,
    this.fechaOrdenSap,
    required this.items,
  });

  factory PedidoAgrupadoModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final itemsList = rawItems
        .map((i) => PedidoProduccionModel.fromJson(i as Map<String, dynamic>))
        .toList();

    return PedidoAgrupadoModel(
      pedidoId: json['pedidoId'] is int ? json['pedidoId'] : int.tryParse(json['pedidoId']?.toString() ?? '0') ?? 0,
      tienda: json['tienda']?.toString() ?? '',
      pais: json['pais']?.toString() ?? '',
      deudorCodigo: json['deudorCodigo']?.toString() ?? '',
      deudorNombre: json['deudorNombre']?.toString() ?? '',
      fechaPedido: json['fechaPedido']?.toString() ?? json['fecha']?.toString(),
      fechaOrdenSap: json['fecha_orden_sap']?.toString(),
      items: itemsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pedidoId': pedidoId,
      'tienda': tienda,
      'pais': pais,
      'deudorCodigo': deudorCodigo,
      'deudorNombre': deudorNombre,
      'fechaPedido': fechaPedido,
      'fecha_orden_sap': fechaOrdenSap,
      'items': items.map((i) => i.toJson()).toList(),
    };
  }
}

class ConsolidatedProductModel {
  final String key;
  final String deudorCodigo;
  final String deudorNombre;
  final String tienda;
  final String pais;
  final String productoNombre;
  final String? itemCode;
  final double cantidadUnidadTotal;
  final double cantidadProcesada;
  final bool completo;
  final String trazabilidadDig;
  final String trazabilidadProd;
  final int? idAlmacen;
  final List<PedidoProduccionModel> originalItems;

  ConsolidatedProductModel({
    required this.key,
    required this.deudorCodigo,
    required this.deudorNombre,
    required this.tienda,
    required this.pais,
    required this.productoNombre,
    this.itemCode,
    required this.cantidadUnidadTotal,
    required this.cantidadProcesada,
    required this.completo,
    required this.trazabilidadDig,
    required this.trazabilidadProd,
    this.idAlmacen,
    required this.originalItems,
  });

  double get faltante {
    final diff = cantidadUnidadTotal - cantidadProcesada;
    return diff > 0 ? diff : 0.0;
  }

  ConsolidatedProductModel copyWith({
    double? cantidadProcesada,
    bool? completo,
    String? trazabilidadDig,
    String? trazabilidadProd,
    int? idAlmacen,
    List<PedidoProduccionModel>? originalItems,
  }) {
    return ConsolidatedProductModel(
      key: key,
      deudorCodigo: deudorCodigo,
      deudorNombre: deudorNombre,
      tienda: tienda,
      pais: pais,
      productoNombre: productoNombre,
      itemCode: itemCode,
      cantidadUnidadTotal: cantidadUnidadTotal,
      cantidadProcesada: cantidadProcesada ?? this.cantidadProcesada,
      completo: completo ?? this.completo,
      trazabilidadDig: trazabilidadDig ?? this.trazabilidadDig,
      trazabilidadProd: trazabilidadProd ?? this.trazabilidadProd,
      idAlmacen: idAlmacen ?? this.idAlmacen,
      originalItems: originalItems ?? this.originalItems,
    );
  }
}

class RecetaLineaModel {
  final int id;
  final String item;
  final int idAlmacen;
  final String? almacenNombre;
  final String? descripcion;
  final double cantidadBase;
  final double cantidadRequerida;
  final String nombreUnidad;
  final bool state;
  final int pedidoProduccionId;
  final int? rechazoId;
  final List<ProveedorRecetaModel> proveedores;

  RecetaLineaModel({
    required this.id,
    required this.item,
    required this.idAlmacen,
    this.almacenNombre,
    this.descripcion,
    required this.cantidadBase,
    required this.cantidadRequerida,
    required this.nombreUnidad,
    required this.state,
    required this.pedidoProduccionId,
    this.rechazoId,
    this.proveedores = const [],
  });

  factory RecetaLineaModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val, [double def = 0.0]) {
      if (val == null) return def;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? def;
    }

    int parseInt(dynamic val, [int def = 0]) {
      if (val == null) return def;
      if (val is int) return val;
      return int.tryParse(val.toString()) ?? def;
    }

    final rawProvs = json['proveedores'] as List<dynamic>? ?? [];
    final provList = rawProvs
        .map((p) => ProveedorRecetaModel.fromJson(p as Map<String, dynamic>))
        .toList();

    return RecetaLineaModel(
      id: parseInt(json['id']),
      item: json['item']?.toString() ?? '',
      idAlmacen: parseInt(json['id_almacen'] ?? json['almacen']?['id']),
      almacenNombre: json['almacen']?['name']?.toString() ?? json['almacen']?['nombre']?.toString(),
      descripcion: json['descripcion']?.toString(),
      cantidadBase: parseDouble(json['cantidad_base']),
      cantidadRequerida: parseDouble(json['cantidad_requerida']),
      nombreUnidad: json['nombre_unidad']?.toString() ?? '',
      state: json['state'] != false,
      pedidoProduccionId: parseInt(json['pedido_produccionid']),
      rechazoId: json['rechazoId'] != null ? parseInt(json['rechazoId']) : null,
      proveedores: provList,
    );
  }

  RecetaLineaModel copyWith({
    bool? state,
    double? cantidadBase,
    double? cantidadRequerida,
    int? idAlmacen,
    List<ProveedorRecetaModel>? proveedores,
  }) {
    return RecetaLineaModel(
      id: id,
      item: item,
      idAlmacen: idAlmacen ?? this.idAlmacen,
      almacenNombre: almacenNombre,
      descripcion: descripcion,
      cantidadBase: cantidadBase ?? this.cantidadBase,
      cantidadRequerida: cantidadRequerida ?? this.cantidadRequerida,
      nombreUnidad: nombreUnidad,
      state: state ?? this.state,
      pedidoProduccionId: pedidoProduccionId,
      rechazoId: rechazoId,
      proveedores: proveedores ?? this.proveedores,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item': item,
      'id_almacen': idAlmacen,
      'almacen': {'id': idAlmacen, 'name': almacenNombre},
      'descripcion': descripcion,
      'cantidad_base': cantidadBase,
      'cantidad_requerida': cantidadRequerida,
      'nombre_unidad': nombreUnidad,
      'state': state,
      'pedido_produccionid': pedidoProduccionId,
      'rechazoId': rechazoId,
      'proveedores': proveedores.map((p) => p.toJson()).toList(),
    };
  }
}

class ProveedorRecetaModel {
  final int id;
  final int? proveedorId;
  final String? proveedorCode;
  final String? proveedorName;
  final double cantidad;
  final String? trazabilidad;

  ProveedorRecetaModel({
    required this.id,
    this.proveedorId,
    this.proveedorCode,
    this.proveedorName,
    required this.cantidad,
    this.trazabilidad,
  });

  factory ProveedorRecetaModel.fromJson(Map<String, dynamic> json) {
    return ProveedorRecetaModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      proveedorId: json['proveedorId'] != null ? int.tryParse(json['proveedorId'].toString()) : null,
      proveedorCode: json['proveedorCode']?.toString(),
      proveedorName: json['proveedorName']?.toString(),
      cantidad: (json['cantidad'] is num)
          ? (json['cantidad'] as num).toDouble()
          : double.tryParse(json['cantidad']?.toString() ?? '0') ?? 0.0,
      trazabilidad: json['trazabilidad']?.toString(),
    );
  }

  ProveedorRecetaModel copyWith({
    int? id,
    int? proveedorId,
    String? proveedorCode,
    String? proveedorName,
    double? cantidad,
    String? trazabilidad,
  }) {
    return ProveedorRecetaModel(
      id: id ?? this.id,
      proveedorId: proveedorId ?? this.proveedorId,
      proveedorCode: proveedorCode ?? this.proveedorCode,
      proveedorName: proveedorName ?? this.proveedorName,
      cantidad: cantidad ?? this.cantidad,
      trazabilidad: trazabilidad ?? this.trazabilidad,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'proveedorId': proveedorId,
      'proveedorCode': proveedorCode,
      'proveedorName': proveedorName,
      'cantidad': cantidad,
      'trazabilidad': trazabilidad,
    };
  }
}

class AlmacenModel {
  final int id;
  final String nombre;

  AlmacenModel({required this.id, required this.nombre});

  factory AlmacenModel.fromJson(Map<String, dynamic> json) {
    return AlmacenModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      nombre: json['nombre']?.toString() ?? json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
    };
  }
}

class MesaActivaAsignadaModel {
  final int idAsignacionMesa;
  final int areaId;
  final String areaNombre;
  final int mesaId;
  final String mesaNombre;
  final int? encargadoId;
  final String encargadoNombre;

  MesaActivaAsignadaModel({
    required this.idAsignacionMesa,
    required this.areaId,
    required this.areaNombre,
    required this.mesaId,
    required this.mesaNombre,
    this.encargadoId,
    required this.encargadoNombre,
  });

  factory MesaActivaAsignadaModel.fromJson(Map<String, dynamic> json) {
    return MesaActivaAsignadaModel(
      idAsignacionMesa: json['idAsignacionMesa'] is int ? json['idAsignacionMesa'] : int.tryParse(json['idAsignacionMesa']?.toString() ?? '0') ?? 0,
      areaId: json['areaId'] is int ? json['areaId'] : int.tryParse(json['areaId']?.toString() ?? '0') ?? 0,
      areaNombre: json['areaNombre']?.toString() ?? '',
      mesaId: json['mesaId'] is int ? json['mesaId'] : int.tryParse(json['mesaId']?.toString() ?? '0') ?? 0,
      mesaNombre: json['mesaNombre']?.toString() ?? '',
      encargadoId: json['encargadoId'] != null ? int.tryParse(json['encargadoId'].toString()) : null,
      encargadoNombre: json['encargadoNombre']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idAsignacionMesa': idAsignacionMesa,
      'areaId': areaId,
      'areaNombre': areaNombre,
      'mesaId': mesaId,
      'mesaNombre': mesaNombre,
      'encargadoId': encargadoId,
      'encargadoNombre': encargadoNombre,
    };
  }
}

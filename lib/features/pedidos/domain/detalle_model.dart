class DetalleModel {
  final int id;
  final int pedidoId;
  final int productoId;
  final int cantidad;
  final double precio;
  final String productoNombre;
  final String productoCodigo;

  DetalleModel({
    required this.id,
    required this.pedidoId,
    required this.productoId,
    required this.cantidad,
    required this.precio,
    required this.productoNombre,
    required this.productoCodigo,
  });

  DetalleModel copyWith({
    int? cantidad,
  }) {
    return DetalleModel(
      id: id,
      pedidoId: pedidoId,
      productoId: productoId,
      cantidad: cantidad ?? this.cantidad,
      precio: precio,
      productoNombre: productoNombre,
      productoCodigo: productoCodigo,
    );
  }

  factory DetalleModel.fromJson(Map<String, dynamic> json) {
    final prod = json['producto'] ?? {};
    return DetalleModel(
      id: json['id'] as int,
      pedidoId: json['pedidoId'] ?? json['pedido_id'] ?? 0,
      productoId: json['productoId'] ?? json['producto_id'] ?? 0,
      cantidad: json['cantidad'] as int,
      precio: double.tryParse(json['precio']?.toString() ?? '0') ?? 0.0,
      productoNombre:
          (json['nombreProducto'] ??
                  json['productoNombre'] ??
                  prod['nombre'] ??
                  '')
              .toString(),
      productoCodigo:
          (json['codigo'] ?? json['productoCodigo'] ?? prod['codigo'] ?? '')
              .toString(),
    );
  }
}

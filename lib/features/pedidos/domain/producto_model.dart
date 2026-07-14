class ProductoModel {
  final int id;
  final String nombre;
  final String codigo;

  ProductoModel({
    required this.id,
    required this.nombre,
    required this.codigo,
  });

  factory ProductoModel.fromJson(Map<String, dynamic> json) {
    return ProductoModel(
      id: json['id'] as int,
      nombre: (json['nombre'] ?? '') as String,
      codigo: (json['codigo'] ?? '') as String,
    );
  }
}

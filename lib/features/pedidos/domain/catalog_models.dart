class CatalogCiudad {
  final int id;
  final String nombre;
  CatalogCiudad({required this.id, required this.nombre});
  factory CatalogCiudad.fromJson(Map<String, dynamic> json) {
    return CatalogCiudad(id: json['id'] as int, nombre: json['nombre'] as String);
  }
}

class CatalogDeudor {
  final int id;
  final String nombre;
  final String correlativo;
  CatalogDeudor({required this.id, required this.nombre, required this.correlativo});
  factory CatalogDeudor.fromJson(Map<String, dynamic> json) {
    return CatalogDeudor(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      correlativo: (json['correlativo'] ?? '') as String,
    );
  }
}

class CatalogTienda {
  final int id;
  final String nombre;
  final int deudorId;
  final int ciudadId;
  final int rutaId;
  final int paisId;

  CatalogTienda({
    required this.id,
    required this.nombre,
    required this.deudorId,
    required this.ciudadId,
    required this.rutaId,
    required this.paisId,
  });

  factory CatalogTienda.fromJson(Map<String, dynamic> json) {
    return CatalogTienda(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      deudorId: json['deudorId'] ?? json['deudor_id'] ?? 0,
      ciudadId: json['ciudadId'] ?? json['ciudad_id'] ?? 0,
      rutaId: json['rutaId'] ?? json['ruta_id'] ?? 0,
      paisId: json['paisId'] ?? json['pais_id'] ?? 0,
    );
  }
}

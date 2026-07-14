class UserModel {
  final int id;
  final int roleId;
  final String nombre;
  final String? correo;
  final String rolNombre;

  UserModel({
    required this.id,
    required this.roleId,
    required this.nombre,
    this.correo,
    required this.rolNombre,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      roleId: json['roleId'] as int,
      nombre: json['nombre'] as String,
      correo: json['correo'] as String?,
      rolNombre: (json['role']?['nombre'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roleId': roleId,
      'nombre': nombre,
      'correo': correo,
      'role': {'nombre': rolNombre},
    };
  }
}

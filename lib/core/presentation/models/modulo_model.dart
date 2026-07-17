import 'opcion_model.dart';

class ModuloModel {
  final int id;
  final String nombre;
  final String icono;
  final List<OpcionModel> opciones;

  ModuloModel({
    required this.id,
    required this.nombre,
    required this.icono,
    required this.opciones,
  });
}

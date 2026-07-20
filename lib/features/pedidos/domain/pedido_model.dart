class PedidoModel {
  final int id;
  final int deudorId;
  final int tiendaId;
  final int estadoId;
  final DateTime creadoEl;
  final String? comentario;
  final String? comentarioDisplay;
  final String deudorNombre;
  final String tiendaNombre;
  final String estadoNombre;
  final int? docNum;
  final int? usuarioId;

  PedidoModel({
    required this.id,
    required this.deudorId,
    required this.tiendaId,
    required this.estadoId,
    required this.creadoEl,
    this.comentario,
    this.comentarioDisplay,
    required this.deudorNombre,
    required this.tiendaNombre,
    required this.estadoNombre,
    this.docNum,
    this.usuarioId,
  });

  factory PedidoModel.fromJson(Map<String, dynamic> json) {
    final estadoIdVal = json['estadoId'] as int;
    String statusName = '';
    if (json['tipoEstado'] != null && json['tipoEstado']['nombre'] != null) {
      statusName = json['tipoEstado']['nombre'] as String;
    } else {
      switch (estadoIdVal) {
        case 1:
          statusName = 'Creado';
          break;
        case 2:
          statusName = 'Realizado';
          break;
        case 3:
          statusName = 'Aprobado';
          break;
        case 4:
          statusName = 'Rechazado';
          break;
        case 5:
          statusName = 'Calidad';
          break;
        case 6:
          statusName = 'Completado';
          break;
        default:
          statusName = 'Pendiente';
      }
    }

    return PedidoModel(
      id: json['id'] as int,
      deudorId: json['deudorId'] as int,
      tiendaId: json['tiendaId'] as int,
      estadoId: estadoIdVal,
      creadoEl: DateTime.parse(json['creadoEl'] as String),
      comentario: json['comentario'] as String?,
      comentarioDisplay: json['comentarioDisplay'] as String?,
      deudorNombre: (json['nombreDeu'] ?? (json['deudor']?['nombre'] ?? '')) as String,
      tiendaNombre: (json['nombreTienda'] ?? (json['tienda']?['nombre'] ?? '')) as String,
      estadoNombre: statusName,
      docNum: json['docNum'] as int?,
      usuarioId: json['usuarioId'] ?? json['usuario_id'],
    );
  }
}

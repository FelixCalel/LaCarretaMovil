class NotificationModel {
  final int id;
  final String titulo;
  final String mensaje;
  final String? tipo;
  final bool leido;
  final DateTime creadoEl;
  final int? pedidoId;

  NotificationModel({
    required this.id,
    required this.titulo,
    required this.mensaje,
    this.tipo,
    required this.leido,
    required this.creadoEl,
    this.pedidoId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int,
      titulo: json['titulo']?.toString() ?? '',
      mensaje: json['mensaje']?.toString() ?? '',
      tipo: json['tipo']?.toString(),
      leido: json['leido'] as bool? ?? false,
      creadoEl: DateTime.parse(json['creadoEl'] as String),
      pedidoId: json['pedidoId'] as int?,
    );
  }
}

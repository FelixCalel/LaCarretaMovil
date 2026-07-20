import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../domain/pedido_model.dart';

class PedidoCard extends StatelessWidget {
  final PedidoModel pedido;
  final VoidCallback onViewDetails;

  const PedidoCard({
    super.key,
    required this.pedido,
    required this.onViewDetails,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'aprobado':
        return Colors.green;
      case 'completado':
        return Colors.blue;
      case 'pendiente':
      case 'realizado':
        return Colors.amber;
      case 'qa':
      case 'calidad':
        return Colors.blue;
      case 'rechazado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    if (status.toLowerCase() == 'completado') {
      return 'EXPORTADO';
    }
    return status.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 3.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.0),
        onTap: onViewDetails,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pedido #${pedido.docNum ?? pedido.id}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(pedido.estadoNombre).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: _getStatusColor(pedido.estadoNombre),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      _getStatusText(pedido.estadoNombre),
                      style: TextStyle(
                        color: _getStatusColor(pedido.estadoNombre),
                        fontWeight: FontWeight.bold,
                        fontSize: 11.0,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20.0),
              Row(
                children: [
                  const Icon(
                    Icons.store,
                    size: 18.0,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      'Tienda: ${pedido.tiendaNombre}',
                      style: const TextStyle(
                        fontSize: 14.0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6.0),
              Row(
                children: [
                  const Icon(
                    Icons.business,
                    size: 18.0,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      'Cliente: ${pedido.deudorNombre}',
                      style: const TextStyle(
                        fontSize: 14.0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6.0),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 18.0,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    'Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(pedido.creadoEl)}',
                    style: const TextStyle(
                      fontSize: 14.0,
                    ),
                  ),
                ],
              ),
              if ((pedido.comentario != null && pedido.comentario!.isNotEmpty) ||
                  (pedido.comentarioDisplay != null && pedido.comentarioDisplay!.isNotEmpty)) ...[
                const SizedBox(height: 10.0),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white10
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white24
                          : Colors.grey[300]!,
                      width: 0.8,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (pedido.comentario != null && pedido.comentario!.isNotEmpty) ...[
                        const Text(
                          'Comentario Vendedor:',
                          style: TextStyle(
                            fontSize: 12.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          pedido.comentario!,
                          style: TextStyle(
                            fontSize: 13.0,
                            fontStyle: FontStyle.italic,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ],
                      if (pedido.comentario != null &&
                          pedido.comentario!.isNotEmpty &&
                          pedido.comentarioDisplay != null &&
                          pedido.comentarioDisplay!.isNotEmpty)
                        const SizedBox(height: 8.0),
                      if (pedido.comentarioDisplay != null && pedido.comentarioDisplay!.isNotEmpty) ...[
                        const Text(
                          'Comentario Display:',
                          style: TextStyle(
                            fontSize: 12.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          pedido.comentarioDisplay!,
                          style: TextStyle(
                            fontSize: 13.0,
                            fontStyle: FontStyle.italic,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8.0),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onViewDetails,
                  icon: const Icon(
                    Icons.visibility,
                    size: 16.0,
                  ),
                  label: const Text('Ver Detalles'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fade(duration: 400.ms).slideX(begin: 0.1, end: 0, curve: Curves.easeOutQuad);
  }
}

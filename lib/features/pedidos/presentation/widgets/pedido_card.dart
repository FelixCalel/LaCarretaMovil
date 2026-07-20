import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../domain/pedido_model.dart';
import '../../../../core/theme/app_theme.dart';

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
        return AppTheme.successColor;
      case 'completado':
        return AppTheme.accentColor;
      case 'pendiente':
      case 'realizado':
        return AppTheme.warningColor;
      case 'qa':
      case 'calidad':
        return AppTheme.accentColor;
      case 'rechazado':
        return AppTheme.errorColor;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _getStatusColor(pedido.estadoNombre);

    return Container(
      margin: const EdgeInsets.only(bottom: 14.0),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardColor : Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(20.0),
          onTap: onViewDetails,
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Icon(
                            Icons.receipt_long_rounded,
                            size: 20.0,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(width: 10.0),
                        Text(
                          'Pedido #${pedido.docNum ?? pedido.id}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 5.0),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Text(
                        _getStatusText(pedido.estadoNombre),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 11.0,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14.0),
                Divider(height: 1.0, color: isDark ? Colors.white12 : Colors.black12),
                const SizedBox(height: 14.0),
                
                Row(
                  children: [
                    Icon(
                      Icons.storefront_rounded,
                      size: 18.0,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        pedido.tiendaNombre,
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                Row(
                  children: [
                    Icon(
                      Icons.business_center_rounded,
                      size: 18.0,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        'Cliente: ${pedido.deudorNombre}',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 18.0,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      DateFormat('dd/MM/yyyy • HH:mm').format(pedido.creadoEl),
                      style: TextStyle(
                        fontSize: 13.0,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
                if ((pedido.comentario != null && pedido.comentario!.isNotEmpty) ||
                    (pedido.comentarioDisplay != null && pedido.comentarioDisplay!.isNotEmpty)) ...[
                  const SizedBox(height: 12.0),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF131C38) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (pedido.comentario != null && pedido.comentario!.isNotEmpty) ...[
                          const Text(
                            'Comentario Vendedor:',
                            style: TextStyle(fontSize: 11.0, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            pedido.comentario!,
                            style: const TextStyle(fontSize: 13.0, fontStyle: FontStyle.italic),
                          ),
                        ],
                        if (pedido.comentarioDisplay != null && pedido.comentarioDisplay!.isNotEmpty) ...[
                          if (pedido.comentario != null && pedido.comentario!.isNotEmpty)
                            const SizedBox(height: 6.0),
                          const Text(
                            'Comentario Display:',
                            style: TextStyle(fontSize: 11.0, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            pedido.comentarioDisplay!,
                            style: const TextStyle(fontSize: 13.0, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 10.0),
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Ver detalles',
                        style: TextStyle(
                          fontSize: 13.0,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 20.0,
                        color: Theme.of(context).primaryColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fade(duration: 350.ms).slideY(begin: 0.05, end: 0);
  }
}

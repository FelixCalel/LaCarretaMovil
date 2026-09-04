import 'package:flutter/material.dart';
import '../../domain/produccion_model.dart';

const Color _emeraldColor = Color(0xFF10B981);

class DigitadorOrderDetailModal extends StatelessWidget {
  final PedidoAgrupadoModel order;

  const DigitadorOrderDetailModal({
    super.key,
    required this.order,
  });

  Widget _buildStatusBadge(PedidoProduccionModel item) {
    if (item.despacho != null && item.despacho! > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.purple.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'EXPORTADO',
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
            color: Colors.purple,
          ),
        ),
      );
    }
    if (item.completo) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: _emeraldColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'FABRICADO',
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
            color: _emeraldColor,
          ),
        ),
      );
    }
    if (item.cantidad > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'EN PROCESO',
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'PENDIENTE',
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          color: Colors.amber,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: 650,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              children: [
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pedido #${order.pedidoId}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${order.deudorCodigo} - ${order.tienda}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: order.items.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = order.items[index];
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item.productoNombre,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            _buildStatusBadge(item),
                          ],
                        ),
                        if (item.itemCode != null && item.itemCode!.isNotEmpty)
                          Text(
                            item.itemCode!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Solicitado: ${item.cantidadUnidad}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            Text(
                              'Fabricado: ${item.cantidad}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: _emeraldColor,
                              ),
                            ),
                            Text(
                              'Faltante: ${item.faltante ?? 0}',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: (item.faltante ?? 0) > 0
                                    ? Colors.red.shade600
                                    : Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                        if ((item.trazabilidadDig != null &&
                                item.trazabilidadDig!.isNotEmpty) ||
                            (item.trazabilidadProd != null &&
                                item.trazabilidadProd!.isNotEmpty)) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            children: [
                              if (item.trazabilidadDig != null &&
                                  item.trazabilidadDig!.isNotEmpty)
                                Text(
                                  'DIG: ${item.trazabilidadDig}',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                              if (item.trazabilidadProd != null &&
                                  item.trazabilidadProd!.isNotEmpty)
                                Text(
                                  'PRO: ${item.trazabilidadProd}',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
      ),
    );
  }
}

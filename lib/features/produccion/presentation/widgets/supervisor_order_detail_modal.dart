import 'package:flutter/material.dart';
import '../../domain/produccion_model.dart';

const Color _emeraldColor = Color(0xFF10B981);

class SupervisorOrderDetailModal extends StatefulWidget {
  final PedidoAgrupadoModel order;
  final bool isSaving;
  final Function(String? comentario) onAcceptOrder;

  const SupervisorOrderDetailModal({
    super.key,
    required this.order,
    this.isSaving = false,
    required this.onAcceptOrder,
  });

  @override
  State<SupervisorOrderDetailModal> createState() =>
      _SupervisorOrderDetailModalState();
}

class _SupervisorOrderDetailModalState
    extends State<SupervisorOrderDetailModal> {
  final TextEditingController _commentCtrl = TextEditingController();

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allDone = widget.order.items.every((i) => i.completo);

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
            // Barra superior modal
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
                        'Pedido #${widget.order.pedidoId}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${widget.order.deudorCodigo} - ${widget.order.tienda}',
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

            // Lista de productos del pedido
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: widget.order.items.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = widget.order.items[index];
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: item.completo
                            ? _emeraldColor.withValues(alpha: 0.5)
                            : (isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item.completo
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: item.completo ? _emeraldColor : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productoNombre,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Solicitado: ${item.cantidadUnidad}  |  Procesado: ${item.cantidad}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (item.completo)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _emeraldColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Listo',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _emeraldColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Campo de comentario y botón de acción
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _commentCtrl,
                    decoration: InputDecoration(
                      hintText: 'Comentario opcional de validación...',
                      hintStyle: const TextStyle(fontSize: 12),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: widget.isSaving
                          ? null
                          : () {
                              if (!allDone) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Aviso: Algunos productos no están marcados como completos.',
                                    ),
                                    backgroundColor: Colors.amber,
                                  ),
                                );
                              }
                              widget.onAcceptOrder(
                                _commentCtrl.text.trim().isEmpty
                                    ? null
                                    : _commentCtrl.text.trim(),
                              );
                              Navigator.pop(context);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _emeraldColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: widget.isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Aceptar Pedido (Pasar a Digitador)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
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

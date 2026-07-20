import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/pedido_model.dart';
import '../../domain/detalle_model.dart';
import '../../domain/producto_model.dart';

class DraftPedidoCard extends StatelessWidget {
  final PedidoModel pedido;
  final bool isExpanded;
  final bool isDetailsLoading;
  final List<DetalleModel> details;
  final List<ProductoModel> products;
  final VoidCallback onToggleExpand;
  final VoidCallback onDeletePedido;
  final VoidCallback onRealizarPedido;
  final Function(DetalleModel, int) onUpdateQuantity;
  final Function(DetalleModel) onDeleteItem;
  final int? selectedProductId;
  final ValueSetter<int?> onProductChanged;
  final TextEditingController quantityController;
  final VoidCallback onAddItem;

  const DraftPedidoCard({
    super.key,
    required this.pedido,
    required this.isExpanded,
    required this.isDetailsLoading,
    required this.details,
    required this.products,
    required this.onToggleExpand,
    required this.onDeletePedido,
    required this.onRealizarPedido,
    required this.onUpdateQuantity,
    required this.onDeleteItem,
    required this.selectedProductId,
    required this.onProductChanged,
    required this.quantityController,
    required this.onAddItem,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardColor : Colors.white,
        borderRadius: BorderRadius.circular(22.0),
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
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.edit_note_rounded, color: Theme.of(context).primaryColor, size: 26),
            ),
            title: Text(
              pedido.tiendaNombre,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cliente: ${pedido.deudorNombre}', style: TextStyle(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary, fontSize: 13)),
                  Text(
                    'Borrador • ${DateFormat('dd/MM/yyyy HH:mm').format(pedido.creadoEl)}',
                    style: TextStyle(fontSize: 12.0, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                  ),
                ],
              ),
            ),
            trailing: IconButton(
              icon: Icon(isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, size: 28),
              onPressed: onToggleExpand,
            ),
          ),

          // Acciones de Borrador M3
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 6.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppTheme.errorColor,
                  ),
                  onPressed: onDeletePedido,
                  tooltip: 'Eliminar Borrador',
                ),
                ElevatedButton.icon(
                  onPressed: onRealizarPedido,
                  icon: const Icon(Icons.send_rounded, size: 16.0, color: Colors.white),
                  label: const Text(
                    'Realizar Pedido',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.0),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                ),
              ],
            ),
          ),

          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
              child: Row(
                children: [
                  Icon(Icons.list_alt_rounded, size: 18, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'PRODUCTOS EN BORRADOR',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            if (isDetailsLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: CircularProgressIndicator(),
              )
            else if (details.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Text('No hay productos agregados a este pedido.', style: TextStyle(color: Colors.grey)),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: details.length,
                itemBuilder: (context, dIndex) {
                  final d = details[dIndex];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF131C38) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14.0),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                d.productoNombre,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.0,
                                ),
                              ),
                              Text(
                                d.productoCodigo,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(4.0),
                              icon: const Icon(
                                Icons.remove_circle_outline_rounded,
                                size: 22.0,
                              ),
                              onPressed: () => onUpdateQuantity(d, d.cantidad - 1),
                            ),
                            const SizedBox(width: 4.0),
                            GestureDetector(
                              onTap: () => _showQuantityEditDialog(context, d),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10.0,
                                  vertical: 4.0,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8.0),
                                  border: Border.all(
                                    color: Theme.of(context).primaryColor,
                                    width: 1.0,
                                  ),
                                ),
                                child: Text(
                                  '${d.cantidad}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15.0,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4.0),
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(4.0),
                              icon: const Icon(
                                Icons.add_circle_outline_rounded,
                                size: 22.0,
                              ),
                              onPressed: () => onUpdateQuantity(d, d.cantidad + 1),
                            ),
                          ],
                        ),
                        const SizedBox(width: 6.0),
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4.0),
                          icon: const Icon(
                            Icons.delete_rounded,
                            color: AppTheme.errorColor,
                            size: 20.0,
                          ),
                          onPressed: () => onDeleteItem(d),
                        ),
                      ],
                    ),
                  );
                },
              ),

            const Divider(height: 24),

            // Formulario M3 de agregar producto
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownMenu<int>(
                    key: ValueKey(selectedProductId),
                    expandedInsets: EdgeInsets.zero,
                    menuHeight: 250,
                    label: const Text('Seleccionar o buscar producto...'),
                    enableFilter: true,
                    enableSearch: true,
                    requestFocusOnTap: true,
                    initialSelection: selectedProductId,
                    onSelected: onProductChanged,
                    dropdownMenuEntries: products
                        .map(
                          (p) => DropdownMenuEntry<int>(
                            value: p.id,
                            label: p.nombre,
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12.0),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: quantityController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Cantidad',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 12.0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      ElevatedButton.icon(
                        onPressed: onAddItem,
                        icon: const Icon(Icons.add_rounded, color: Colors.white),
                        label: const Text(
                          'Agregar',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.0),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12.0),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showQuantityEditDialog(BuildContext context, DetalleModel detail) {
    final controller = TextEditingController(text: '${detail.cantidad}');
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
          title: const Text('Editar Cantidad'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Ingrese la cantidad',
              labelText: 'Cantidad',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                final val = int.tryParse(controller.text);
                if (val != null && val > 0) {
                  onUpdateQuantity(detail, val);
                }
                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
              child: const Text('Guardar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}

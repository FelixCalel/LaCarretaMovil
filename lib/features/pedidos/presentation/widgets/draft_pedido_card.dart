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
    final colorScheme = Theme.of(context).colorScheme;
    final sectionTextColor = colorScheme.onSurface;
    final mutedTextColor = colorScheme.onSurfaceVariant;

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 3.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              child: const Icon(Icons.assignment, color: AppTheme.primaryColor),
            ),
            title: Text(
              pedido.tiendaNombre,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cliente: ${pedido.deudorNombre}'),
                Text(
                  'Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(pedido.creadoEl)}',
                  style: const TextStyle(fontSize: 12.0),
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
              onPressed: onToggleExpand,
            ),
          ),

          // Acciones de Borrador
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  onPressed: onDeletePedido,
                  tooltip: 'Eliminar Borrador',
                ),
                ElevatedButton.icon(
                  onPressed: onRealizarPedido,
                  icon: const Icon(Icons.send, size: 16.0, color: Colors.white),
                  label: const Text(
                    'Realizar Pedido',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (isExpanded) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                'DETALLES DEL PEDIDO',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.0,
                  color: mutedTextColor,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            if (isDetailsLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: CircularProgressIndicator(),
              )
            else if (details.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Text('No hay productos agregados a este pedido.'),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: details.length,
                itemBuilder: (context, dIndex) {
                  final d = details[dIndex];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                d.productoNombre,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: sectionTextColor,
                                ),
                              ),
                              Text(
                                d.productoCodigo,
                                style: TextStyle(
                                  fontSize: 11.0,
                                  color: mutedTextColor,
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
                              icon: Icon(
                                Icons.remove_circle_outline,
                                size: 20.0,
                                color: mutedTextColor,
                              ),
                              onPressed: () =>
                                  onUpdateQuantity(d, d.cantidad - 1),
                            ),
                            const SizedBox(width: 6.0),
                            Text(
                              '${d.cantidad}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15.0,
                                color: sectionTextColor,
                              ),
                            ),
                            const SizedBox(width: 6.0),
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(4.0),
                              icon: Icon(
                                Icons.add_circle_outline,
                                size: 20.0,
                                color: mutedTextColor,
                              ),
                              onPressed: () =>
                                  onUpdateQuantity(d, d.cantidad + 1),
                            ),
                          ],
                        ),
                        const SizedBox(width: 4.0),
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4.0),
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.redAccent,
                            size: 20.0,
                          ),
                          onPressed: () => onDeleteItem(d),
                        ),
                      ],
                    ),
                  );
                },
              ),

            const Divider(),

            // Formulario de agregar ítem al detalle
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownMenu<int>(
                    key: ValueKey(selectedProductId),
                    expandedInsets: EdgeInsets.zero,
                    menuHeight: 250, // Límite de altura para no tapar toda la pantalla
                    label: const Text('Seleccione un item o busque por nombre'),
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
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: quantityController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Cantidad',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12.0,
                              vertical: 8.0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      ElevatedButton.icon(
                        onPressed: onAddItem,
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text(
                          'Agregar',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

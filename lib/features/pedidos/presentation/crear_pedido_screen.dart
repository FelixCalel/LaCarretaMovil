import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/presentation/main_layout.dart';
import '../../../core/theme/app_theme.dart';
import '../data/pedidos_datasource.dart';
import '../domain/pedido_model.dart';
import 'widgets/draft_pedido_card.dart';
import 'widgets/crear_pedido_modal.dart';
import 'crear_pedido_cubit.dart';
import 'crear_pedido_state.dart';

class CrearPedidoScreen extends StatelessWidget {
  const CrearPedidoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient();
    final datasource = PedidosDatasource(apiClient: apiClient);

    return BlocProvider(
      create: (context) => CrearPedidoCubit(datasource: datasource)..loadData(),
      child: const _CrearPedidoScreenView(),
    );
  }
}

class _CrearPedidoScreenView extends StatefulWidget {
  const _CrearPedidoScreenView();

  @override
  State<_CrearPedidoScreenView> createState() => _CrearPedidoScreenViewState();
}

class _CrearPedidoScreenViewState extends State<_CrearPedidoScreenView> {
  final Map<int, TextEditingController> _quantityControllers = {};

  @override
  void dispose() {
    for (var controller in _quantityControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _getQuantityController(int pedidoId) {
    if (!_quantityControllers.containsKey(pedidoId)) {
      _quantityControllers[pedidoId] = TextEditingController(text: '1');
    }
    return _quantityControllers[pedidoId]!;
  }

  Future<void> _realizarPedidoDialog(BuildContext context, PedidoModel pedido) async {
    final formKey = GlobalKey<FormState>();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    final commentController = TextEditingController();
    final dateController = TextEditingController(text: DateFormat('yyyy-MM-dd').format(selectedDate));

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Realizar Pedido'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: dateController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Fecha de Entrega',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedDate = picked;
                            dateController.text = DateFormat('yyyy-MM-dd').format(picked);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: commentController,
                      decoration: const InputDecoration(
                        labelText: 'Comentario / Observaciones',
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                  child: const Text('Confirmar Pedido', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirm == true && context.mounted) {
      context.read<CrearPedidoCubit>().realizarPedido(
        pedido.id,
        commentController.text,
        dateController.text,
      );
    }
  }

  Future<void> _deletePedidoDialog(BuildContext context, int pedidoId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Borrador'),
        content: const Text('¿Está seguro de que desea eliminar este borrador de pedido?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      context.read<CrearPedidoCubit>().deletePedido(pedidoId);
    }
  }

  void _showCrearPedidoModal(BuildContext context, CrearPedidoState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (modalContext) {
        return CrearPedidoModal(
          ciudades: state.ciudades,
          deudores: state.deudores,
          tiendas: state.tiendas,
          userRoutes: state.userRoutes,
          userPaisId: state.userPaisId,
          onSave: (ciudadId, deudorId, tiendaId) {
            Navigator.pop(modalContext);
            context.read<CrearPedidoCubit>().createPedido(
              ciudadId: ciudadId,
              deudorId: deudorId,
              tiendaId: tiendaId,
            );
          },
          onCopyLastPedido: (ciudadId, deudorId, tiendaId) {
            Navigator.pop(modalContext);
            context.read<CrearPedidoCubit>().copiarUltimoPedido(
              ciudadId: ciudadId,
              deudorId: deudorId,
              tiendaId: tiendaId,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CrearPedidoCubit, CrearPedidoState>(
      listenWhen: (previous, current) => previous.error != current.error || previous.successMessage != current.successMessage,
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!), backgroundColor: Colors.red),
          );
          context.read<CrearPedidoCubit>().clearError();
        }
        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.successMessage!), backgroundColor: Colors.green),
          );
          context.read<CrearPedidoCubit>().clearSuccess();
        }
      },
      child: BlocBuilder<CrearPedidoCubit, CrearPedidoState>(
        builder: (context, state) {
          return MainLayout(
            title: 'Crear Pedido',
            body: state.isLoading && state.draftPedidos.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.draftPedidos.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_basket_outlined, size: 80.0, color: Colors.grey[400]),
                            const SizedBox(height: 16.0),
                            Text(
                              'No tienes borradores activos',
                              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              'Presiona el botón + para crear uno nuevo.',
                              style: TextStyle(fontSize: 14.0, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => context.read<CrearPedidoCubit>().loadData(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: state.draftPedidos.length,
                          itemBuilder: (context, index) {
                            final pedido = state.draftPedidos[index];
                            final isExpanded = state.expandedPedidos[pedido.id] ?? false;
                            final isDetailsLoading = state.loadingDetails[pedido.id] ?? false;
                            final details = state.pedidoDetalles[pedido.id] ?? [];
                            final products = state.deudorProductos[pedido.deudorId] ?? [];
                            final quantityController = _getQuantityController(pedido.id);

                            return DraftPedidoCard(
                              pedido: pedido,
                              isExpanded: isExpanded,
                              isDetailsLoading: isDetailsLoading,
                              details: details,
                              products: products,
                              onToggleExpand: () => context.read<CrearPedidoCubit>().toggleExpand(pedido.id, pedido.deudorId),
                              onDeletePedido: () => _deletePedidoDialog(context, pedido.id),
                              onRealizarPedido: () => _realizarPedidoDialog(context, pedido),
                              onUpdateQuantity: (detail, newQty) => context.read<CrearPedidoCubit>().updateItemQuantity(pedido.id, detail, newQty),
                              onDeleteItem: (detail) => context.read<CrearPedidoCubit>().deleteItem(pedido.id, detail),
                              selectedProductId: state.selectedProductForPedido[pedido.id],
                              onProductChanged: (val) {
                                context.read<CrearPedidoCubit>().selectProduct(pedido.id, val);
                              },
                              quantityController: quantityController,
                              onAddItem: () {
                                final qty = int.tryParse(quantityController.text) ?? 1;
                                context.read<CrearPedidoCubit>().addItemToPedido(pedido.id, pedido.deudorId, qty);
                                quantityController.text = '1';
                              },
                            );
                          },
                        ),
                      ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => _showCrearPedidoModal(context, state),
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          );
        },
      ),
    );
  }
}

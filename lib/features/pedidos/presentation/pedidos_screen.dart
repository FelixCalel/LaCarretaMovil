import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:go_router/go_router.dart';
import '../../../core/presentation/main_layout.dart';
import '../data/pedidos_datasource.dart';
import '../../../core/network/api_client.dart';
import 'pedidos_cubit.dart';
import '../domain/pedido_model.dart';
import 'widgets/pedido_details_modal.dart';
import 'widgets/pedidos_filter_panel.dart';
import 'widgets/pedido_card.dart';

class PedidosScreen extends StatefulWidget {
  const PedidosScreen({super.key});

  @override
  State<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends State<PedidosScreen> {
  String? _selectedDeudor;
  String? _selectedTienda;
  String? _selectedEstado;
  int _limit = 10;

  void _showPedidoDetails(BuildContext context, PedidoModel pedido) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (modalContext) {
        return PedidoDetailsModal(pedido: pedido);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient();
    final datasource = PedidosDatasource(apiClient: apiClient);

    return BlocProvider(
      create: (context) => PedidosCubit(datasource: datasource)..fetchPedidos(),
      child: MainLayout(
        title: 'Historial Pedido',
        actions: [
          Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  context.read<PedidosCubit>().fetchPedidos();
                },
              );
            },
          ),
        ],
        floatingActionButton: FloatingActionButton(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          onPressed: () {
            context.go('/pedidos/crear');
          },
          child: const Icon(Icons.add),
        ),
        body: BlocBuilder<PedidosCubit, PedidosState>(
          builder: (context, state) {
            if (state is PedidosLoading) {
              final mockPedidos = List.generate(
                5,
                (index) => PedidoModel(
                  id: index,
                  creadoEl: DateTime.now(),
                  estadoId: 1,
                  estadoNombre: 'Pendiente',
                  deudorId: 1,
                  deudorNombre: 'Cargando...',
                  tiendaId: 1,
                  tiendaNombre: 'Cargando...',
                ),
              );
              return Skeletonizer(
                enabled: true,
                child: ListView.builder(
                  padding: const EdgeInsets.all(12.0),
                  itemCount: mockPedidos.length,
                  itemBuilder: (context, index) {
                    return PedidoCard(
                      pedido: mockPedidos[index],
                      onViewDetails: () {},
                    );
                  },
                ),
              );
            } else if (state is PedidosLoaded) {
              final allPedidos = state.pedidos;

              final deudores = allPedidos.map((p) => p.deudorNombre).toSet().toList();
              final tiendas = allPedidos.map((p) => p.tiendaNombre).toSet().toList();
              final estados = allPedidos.map((p) => p.estadoNombre).toSet().toList();

              final filteredPedidos = allPedidos.where((pedido) {
                final matchDeudor = _selectedDeudor == null || pedido.deudorNombre == _selectedDeudor;
                final matchTienda = _selectedTienda == null || pedido.tiendaNombre == _selectedTienda;
                final matchEstado = _selectedEstado == null || pedido.estadoNombre == _selectedEstado;
                return matchDeudor && matchTienda && matchEstado;
              }).toList();

              return Column(
                children: [
                  PedidosFilterPanel(
                    selectedDeudor: _selectedDeudor,
                    selectedTienda: _selectedTienda,
                    selectedEstado: _selectedEstado,
                    deudores: deudores,
                    tiendas: tiendas,
                    estados: estados,
                    onDeudorChanged: (val) => setState(() {
                      _selectedDeudor = val;
                      _limit = 10;
                    }),
                    onTiendaChanged: (val) => setState(() {
                      _selectedTienda = val;
                      _limit = 10;
                    }),
                    onEstadoChanged: (val) => setState(() {
                      _selectedEstado = val;
                      _limit = 10;
                    }),
                    onClearFilters: () {
                      setState(() {
                        _selectedDeudor = null;
                        _selectedTienda = null;
                        _selectedEstado = null;
                        _limit = 10;
                      });
                    },
                  ),
                  Expanded(
                    child: filteredPedidos.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64.0,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 12.0),
                                Text(
                                  'No se encontraron pedidos',
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () async {
                              context.read<PedidosCubit>().fetchPedidos();
                            },
                            child: () {
                              final displayedPedidos = filteredPedidos.take(_limit).toList();
                              final hasMore = filteredPedidos.length > _limit;

                              return ListView.builder(
                                padding: const EdgeInsets.all(12.0),
                                itemCount: displayedPedidos.length + (hasMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == displayedPedidos.length) {
                                    final remaining = filteredPedidos.length - _limit;
                                    return InkWell(
                                      onTap: () {
                                        setState(() {
                                          _limit += 10;
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                                        child: Center(
                                          child: Text(
                                            'Cargar más ($remaining restantes)',
                                            style: TextStyle(
                                              color: Theme.of(context).primaryColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }

                                  final pedido = displayedPedidos[index];
                                  return PedidoCard(
                                    pedido: pedido,
                                    onViewDetails: () => _showPedidoDetails(context, pedido),
                                  );
                                },
                              );
                            }(),
                          ),
                  ),
                ],
              );
            } else if (state is PedidosError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48.0,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(height: 12.0),
                      Text(
                        state.error,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                      const SizedBox(height: 16.0),
                      ElevatedButton(
                        onPressed: () {
                          context.read<PedidosCubit>().fetchPedidos();
                        },
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }
}

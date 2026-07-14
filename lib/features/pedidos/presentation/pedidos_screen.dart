import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/environment.dart';
import '../../../core/presentation/main_layout.dart';
import '../data/pedidos_datasource.dart';
import '../../../core/network/api_client.dart';
import 'pedidos_cubit.dart';
import '../domain/pedido_model.dart';
import '../domain/detalle_model.dart';

class PedidosScreen extends StatefulWidget {
  const PedidosScreen({super.key});

  @override
  State<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends State<PedidosScreen> {
  String? _selectedDeudor;
  String? _selectedTienda;
  String? _selectedEstado;

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'aprobado':
      case 'completado':
        return Colors.green;
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

  void _showPedidoDetails(BuildContext context, PedidoModel pedido) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (modalContext) {
        final apiClient = ApiClient(baseUrl: Environment.apiBaseUrl);
        return FutureBuilder(
          future: apiClient.dio.get('/detalle/pedido/listar/${pedido.id}'),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 250,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return SizedBox(
                height: 250,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Error al cargar detalles: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ),
              );
            }

            final List<dynamic> data = snapshot.data?.data ?? [];
            if (data.isEmpty) {
              return const SizedBox(
                height: 250,
                child: Center(
                  child: Text(
                    'No hay detalles registrados para este pedido.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }

            final details = data.map((j) => DetalleModel.fromJson(j)).toList();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
                top: 24.0,
                left: 24.0,
                right: 24.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Detalles del Pedido #${pedido.docNum ?? pedido.id}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 12.0),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.4,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: details.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1.0),
                      itemBuilder: (context, index) {
                        final item = details[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.productoNombre.isNotEmpty
                                          ? item.productoNombre
                                          : 'Producto #${item.productoId}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2.0),
                                    Text(
                                      item.productoCodigo.isNotEmpty
                                          ? item.productoCodigo
                                          : 'Sin código',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'Cant: ${item.cantidad}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15.0,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient(baseUrl: Environment.apiBaseUrl);
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
              return const Center(child: CircularProgressIndicator());
            } else if (state is PedidosLoaded) {
              final allPedidos = state.pedidos;

              // Obtener opciones de filtros dinámicamente de los pedidos cargados
              final deudores = allPedidos
                  .map((p) => p.deudorNombre)
                  .toSet()
                  .toList();
              final tiendas = allPedidos
                  .map((p) => p.tiendaNombre)
                  .toSet()
                  .toList();
              final estados = allPedidos
                  .map((p) => p.estadoNombre)
                  .toSet()
                  .toList();

              // Aplicar filtros locales
              final filteredPedidos = allPedidos.where((pedido) {
                final matchDeudor =
                    _selectedDeudor == null ||
                    pedido.deudorNombre == _selectedDeudor;
                final matchTienda =
                    _selectedTienda == null ||
                    pedido.tiendaNombre == _selectedTienda;
                final matchEstado =
                    _selectedEstado == null ||
                    pedido.estadoNombre == _selectedEstado;
                return matchDeudor && matchTienda && matchEstado;
              }).toList();

              return Column(
                children: [
                  // Panel de Filtros
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4.0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // Dropdown Deudor
                          DropdownButton<String>(
                            value: _selectedDeudor,
                            hint: const Text(
                              'Cliente',
                              style: TextStyle(fontSize: 13.0),
                            ),
                            underline: const SizedBox(),
                            style: TextStyle(
                              fontSize: 13.0,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                            ),
                            items: deudores
                                .map(
                                  (d) => DropdownMenuItem(
                                    value: d,
                                    child: Text(d),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              setState(() => _selectedDeudor = val);
                            },
                          ),
                          const SizedBox(width: 16.0),

                          // Dropdown Tienda
                          DropdownButton<String>(
                            value: _selectedTienda,
                            hint: const Text(
                              'Tienda',
                              style: TextStyle(fontSize: 13.0),
                            ),
                            underline: const SizedBox(),
                            style: TextStyle(
                              fontSize: 13.0,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                            ),
                            items: tiendas
                                .map(
                                  (t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              setState(() => _selectedTienda = val);
                            },
                          ),
                          const SizedBox(width: 16.0),

                          // Dropdown Estado
                          DropdownButton<String>(
                            value: _selectedEstado,
                            hint: const Text(
                              'Estado',
                              style: TextStyle(fontSize: 13.0),
                            ),
                            underline: const SizedBox(),
                            style: TextStyle(
                              fontSize: 13.0,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                            ),
                            items: estados
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              setState(() => _selectedEstado = val);
                            },
                          ),

                          if (_selectedDeudor != null ||
                              _selectedTienda != null ||
                              _selectedEstado != null) ...[
                            const SizedBox(width: 16.0),
                            IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Colors.redAccent,
                                size: 20.0,
                              ),
                              tooltip: 'Limpiar Filtros',
                              onPressed: () {
                                setState(() {
                                  _selectedDeudor = null;
                                  _selectedTienda = null;
                                  _selectedEstado = null;
                                });
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
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
                            child: ListView.builder(
                              padding: const EdgeInsets.all(12.0),
                              itemCount: filteredPedidos.length,
                              itemBuilder: (context, index) {
                                final pedido = filteredPedidos[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12.0),
                                  elevation: 3.0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16.0),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16.0),
                                    onTap: () =>
                                        _showPedidoDetails(context, pedido),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Pedido #${pedido.docNum ?? pedido.id}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16.0,
                                                  color: Theme.of(
                                                    context,
                                                  ).primaryColor,
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10.0,
                                                      vertical: 4.0,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: _getStatusColor(
                                                    pedido.estadoNombre,
                                                  ).withValues(alpha: 0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        12.0,
                                                      ),
                                                  border: Border.all(
                                                    color: _getStatusColor(
                                                      pedido.estadoNombre,
                                                    ),
                                                    width: 1.5,
                                                  ),
                                                ),
                                                child: Text(
                                                  pedido.estadoNombre
                                                      .toUpperCase(),
                                                  style: TextStyle(
                                                    color: _getStatusColor(
                                                      pedido.estadoNombre,
                                                    ),
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
                                          if (pedido.comentario != null &&
                                              pedido
                                                  .comentario!
                                                  .isNotEmpty) ...[
                                            const SizedBox(height: 10.0),
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.all(
                                                10.0,
                                              ),
                                              decoration: BoxDecoration(
                                                color:
                                                    Theme.of(
                                                          context,
                                                        ).brightness ==
                                                        Brightness.dark
                                                    ? Colors.white10
                                                    : Colors.grey[100],
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                              ),
                                              child: Text(
                                                'Comentario: ${pedido.comentario}',
                                                style: TextStyle(
                                                  fontSize: 13.0,
                                                  fontStyle: FontStyle.italic,
                                                  color: Theme.of(
                                                    context,
                                                  ).textTheme.bodyMedium?.color,
                                                ),
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 8.0),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: TextButton.icon(
                                              onPressed: () =>
                                                  _showPedidoDetails(
                                                    context,
                                                    pedido,
                                                  ),
                                              icon: const Icon(
                                                Icons.visibility,
                                                size: 16.0,
                                              ),
                                              label: const Text('Ver Detalles'),
                                              style: TextButton.styleFrom(
                                                foregroundColor: Theme.of(
                                                  context,
                                                ).primaryColor,
                                                padding: EdgeInsets.zero,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
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

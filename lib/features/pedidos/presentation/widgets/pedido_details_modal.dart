import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/pedido_model.dart';
import '../../domain/detalle_model.dart';

class PedidoDetailsModal extends StatelessWidget {
  final PedidoModel pedido;

  const PedidoDetailsModal({super.key, required this.pedido});

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient();
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
                  Expanded(
                    child: Text(
                      'Detalles del Pedido #${pedido.docNum ?? pedido.id}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
  }
}

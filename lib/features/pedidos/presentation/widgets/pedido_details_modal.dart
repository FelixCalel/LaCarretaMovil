import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/pedido_model.dart';
import '../../domain/detalle_model.dart';
import '../../../../core/theme/app_theme.dart';

class PedidoDetailsModal extends StatelessWidget {
  final PedidoModel pedido;

  const PedidoDetailsModal({super.key, required this.pedido});

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder(
      future: apiClient.dio.get('/detalle/pedido/listar/${pedido.id}'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 280,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando ítems del pedido...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
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
                  style: const TextStyle(color: AppTheme.errorColor),
                ),
              ),
            ),
          );
        }

        final List<dynamic> data = snapshot.data?.data ?? [];
        if (data.isEmpty) {
          return const SizedBox(
            height: 220,
            child: Center(
              child: Text(
                'No hay detalles registrados para este pedido.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          );
        }

        final details = data.map((j) => DetalleModel.fromJson(j)).toList()
          ..sort((a, b) => a.productoNombre.toLowerCase().compareTo(b.productoNombre.toLowerCase()));

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20.0,
            top: 12.0,
            left: 20.0,
            right: 20.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detalles de Pedido #${pedido.docNum ?? pedido.id}',
                          style: const TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${details.length} productos registrados',
                          style: TextStyle(
                            fontSize: 13.0,
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: details.length,
                  itemBuilder: (context, index) {
                    final item = details[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10.0),
                      padding: const EdgeInsets.all(14.0),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF131C38) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Icon(
                              Icons.inventory_2_rounded,
                              color: Theme.of(context).primaryColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productoNombre.isNotEmpty
                                      ? item.productoNombre
                                      : 'Producto #${item.productoId}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.5,
                                  ),
                                ),
                                const SizedBox(height: 2.0),
                                Text(
                                  item.productoCodigo.isNotEmpty
                                      ? 'Código: ${item.productoCodigo}'
                                      : 'Sin código',
                                  style: TextStyle(
                                    fontSize: 12.0,
                                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Text(
                              '${item.cantidad}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12.0),
            ],
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';

class PedidosFilterPanel extends StatelessWidget {
  final String? selectedDeudor;
  final String? selectedTienda;
  final String? selectedEstado;
  final List<String> deudores;
  final List<String> tiendas;
  final List<String> estados;
  final ValueChanged<String?> onDeudorChanged;
  final ValueChanged<String?> onTiendaChanged;
  final ValueChanged<String?> onEstadoChanged;
  final VoidCallback onClearFilters;

  const PedidosFilterPanel({
    super.key,
    required this.selectedDeudor,
    required this.selectedTienda,
    required this.selectedEstado,
    required this.deudores,
    required this.tiendas,
    required this.estados,
    required this.onDeudorChanged,
    required this.onTiendaChanged,
    required this.onEstadoChanged,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            DropdownButton<String>(
              value: selectedDeudor,
              hint: const Text(
                'Cliente',
                style: TextStyle(fontSize: 13.0),
              ),
              underline: const SizedBox(),
              style: TextStyle(
                fontSize: 13.0,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              items: deudores
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: onDeudorChanged,
            ),
            const SizedBox(width: 16.0),
            DropdownButton<String>(
              value: selectedTienda,
              hint: const Text(
                'Tienda',
                style: TextStyle(fontSize: 13.0),
              ),
              underline: const SizedBox(),
              style: TextStyle(
                fontSize: 13.0,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              items: tiendas
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: onTiendaChanged,
            ),
            const SizedBox(width: 16.0),
            DropdownButton<String>(
              value: selectedEstado,
              hint: const Text(
                'Estado',
                style: TextStyle(fontSize: 13.0),
              ),
              underline: const SizedBox(),
              style: TextStyle(
                fontSize: 13.0,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              items: estados
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: onEstadoChanged,
            ),
            if (selectedDeudor != null ||
                selectedTienda != null ||
                selectedEstado != null) ...[
              const SizedBox(width: 16.0),
              IconButton(
                icon: const Icon(
                  Icons.clear,
                  color: Colors.redAccent,
                  size: 20.0,
                ),
                tooltip: 'Limpiar Filtros',
                onPressed: onClearFilters,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

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

  Widget _buildFilterChip(
    BuildContext context, {
    required String hint,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    final isSelected = value != null;
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      decoration: BoxDecoration(
        color: isSelected
            ? primaryColor.withValues(alpha: 0.1)
            : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: isSelected
              ? primaryColor
              : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.w500,
              color: isSelected ? primaryColor : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
            ),
          ),
          style: TextStyle(
            fontSize: 12.0,
            fontWeight: FontWeight.w600,
            color: isSelected ? primaryColor : (isDark ? Colors.white : Colors.black87),
          ),
          icon: Icon(
            Icons.arrow_drop_down,
            color: isSelected ? primaryColor : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
            size: 18,
          ),
          items: options
              .map((val) => DropdownMenuItem(value: val, child: Text(val)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12.0,
        vertical: 8.0,
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
            _buildFilterChip(
              context,
              hint: 'Cliente',
              value: selectedDeudor,
              options: deudores,
              onChanged: onDeudorChanged,
            ),
            const SizedBox(width: 8.0),
            _buildFilterChip(
              context,
              hint: 'Tienda',
              value: selectedTienda,
              options: tiendas,
              onChanged: onTiendaChanged,
            ),
            const SizedBox(width: 8.0),
            _buildFilterChip(
              context,
              hint: 'Estado',
              value: selectedEstado,
              options: estados,
              onChanged: onEstadoChanged,
            ),
            if (selectedDeudor != null ||
                selectedTienda != null ||
                selectedEstado != null) ...[
              const SizedBox(width: 8.0),
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

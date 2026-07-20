import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

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
    required String label,
    required IconData icon,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    final isSelected = value != null;
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.only(left: 10.0, right: 8.0),
      height: 38.0,
      decoration: BoxDecoration(
        color: isSelected
            ? primaryColor.withValues(alpha: 0.15)
            : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: isSelected
              ? primaryColor
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16.0,
            color: isSelected
                ? primaryColor
                : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
          ),
          const SizedBox(width: 6.0),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? primaryColor : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                ),
              ),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: isSelected ? primaryColor : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
              ),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: isSelected ? primaryColor : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                size: 18,
              ),
              items: options
                  .map((val) => DropdownMenuItem(value: val, child: Text(val)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardColor : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              context,
              label: 'Cliente',
              icon: Icons.person_outline_rounded,
              value: selectedDeudor,
              options: deudores,
              onChanged: onDeudorChanged,
            ),
            const SizedBox(width: 8.0),
            _buildFilterChip(
              context,
              label: 'Tienda',
              icon: Icons.storefront_rounded,
              value: selectedTienda,
              options: tiendas,
              onChanged: onTiendaChanged,
            ),
            const SizedBox(width: 8.0),
            _buildFilterChip(
              context,
              label: 'Estado',
              icon: Icons.flag_outlined,
              value: selectedEstado,
              options: estados,
              onChanged: onEstadoChanged,
            ),
            if (selectedDeudor != null ||
                selectedTienda != null ||
                selectedEstado != null) ...[
              const SizedBox(width: 8.0),
              InkWell(
                onTap: onClearFilters,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(7.0),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: AppTheme.errorColor,
                    size: 18.0,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

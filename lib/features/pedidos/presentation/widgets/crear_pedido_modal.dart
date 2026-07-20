import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/catalog_models.dart';

class CrearPedidoModal extends StatefulWidget {
  final List<CatalogCiudad> ciudades;
  final List<CatalogDeudor> deudores;
  final List<CatalogTienda> tiendas;
  final List<int> userRoutes;
  final int userPaisId;
  final Function(int ciudadId, int deudorId, int tiendaId) onSave;
  final Function(int ciudadId, int deudorId, int tiendaId) onCopyLastPedido;

  const CrearPedidoModal({
    super.key,
    required this.ciudades,
    required this.deudores,
    required this.tiendas,
    required this.userRoutes,
    required this.userPaisId,
    required this.onSave,
    required this.onCopyLastPedido,
  });

  @override
  State<CrearPedidoModal> createState() => _CrearPedidoModalState();
}

class _CrearPedidoModalState extends State<CrearPedidoModal> {
  int? selectedAssignedTiendaId;
  int? selectedUnassignedTiendaId;

  List<CatalogTienda> assignedTiendas = [];
  List<CatalogTienda> unassignedTiendas = [];

  @override
  void initState() {
    super.initState();
    final baseTiendas = widget.tiendas.where((t) {
      if (widget.userPaisId != 0 && t.paisId != widget.userPaisId) {
        return false;
      }
      return true;
    }).toList();

    assignedTiendas = baseTiendas
        .where((t) => widget.userRoutes.contains(t.rutaId))
        .toList();
    unassignedTiendas = baseTiendas;
  }

  CatalogTienda? getSelectedTienda() {
    if (selectedAssignedTiendaId != null) {
      return widget.tiendas.firstWhere((t) => t.id == selectedAssignedTiendaId);
    }
    if (selectedUnassignedTiendaId != null) {
      return widget.tiendas.firstWhere((t) => t.id == selectedUnassignedTiendaId);
    }
    return null;
  }

  CatalogDeudor? getSelectedDeudor(CatalogTienda? tienda) {
    if (tienda == null) return null;
    return widget.deudores.firstWhere((d) => d.id == tienda.deudorId,
        orElse: () => CatalogDeudor(id: 0, nombre: 'Sin Deudor', correlativo: ''));
  }

  @override
  Widget build(BuildContext context) {
    final selectedTienda = getSelectedTienda();
    final selectedDeudor = getSelectedDeudor(selectedTienda);

    final isTiendaAsignadaDisabled = selectedUnassignedTiendaId != null;
    final isTiendaNoAsignadaDisabled = selectedAssignedTiendaId != null;

    final hasSelection = selectedTienda != null;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final assignedActiveColor = AppTheme.primaryColor;
    final assignedBgColor = isDark ? const Color(0xFF09290B) : const Color(0xFFF0FDF4);

    final unassignedActiveColor = const Color(0xFFD97706);
    final unassignedBgColor = isDark ? const Color(0xFF321A04) : const Color(0xFFFFFBEB);

    final disabledBgColor = isDark ? const Color(0xFF131C38) : const Color(0xFFF1F5F9);
    final disabledBorderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final normalTextColor = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final disabledTextColor = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20.0,
        top: 12.0,
        left: 20.0,
        right: 20.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Agregar Nuevo Pedido',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.primaryDarkColor,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16.0),

          // Tiendas Asignadas (Dropdown M3)
          DropdownButtonFormField<int>(
            isExpanded: true,
            dropdownColor: isDark ? AppTheme.darkCardColor : Colors.white,
            style: TextStyle(
              color: isTiendaAsignadaDisabled ? disabledTextColor : normalTextColor,
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              labelText: 'Tiendas Asignadas (Ruta activa)',
              labelStyle: TextStyle(
                color: isTiendaAsignadaDisabled ? Colors.grey : assignedActiveColor,
                fontWeight: FontWeight.bold,
              ),
              prefixIcon: Icon(
                Icons.store_rounded,
                color: isTiendaAsignadaDisabled ? Colors.grey : assignedActiveColor,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.0),
                borderSide: BorderSide(
                  color: isTiendaAsignadaDisabled ? disabledBorderColor : assignedActiveColor,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.0),
                borderSide: BorderSide(color: assignedActiveColor, width: 2.0),
              ),
              filled: true,
              fillColor: isTiendaAsignadaDisabled ? disabledBgColor : assignedBgColor,
            ),
            initialValue: selectedAssignedTiendaId,
            items: isTiendaAsignadaDisabled
                ? []
                : assignedTiendas
                    .map((t) => DropdownMenuItem(
                          value: t.id,
                          child: Text(
                            t.nombre,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: normalTextColor),
                          ),
                        ))
                    .toList(),
            onChanged: isTiendaAsignadaDisabled
                ? null
                : (val) {
                    setState(() {
                      selectedAssignedTiendaId = val;
                    });
                  },
          ),
          const SizedBox(height: 16.0),

          // Tiendas NO asignadas (Dropdown M3)
          DropdownButtonFormField<int>(
            isExpanded: true,
            dropdownColor: isDark ? AppTheme.darkCardColor : Colors.white,
            style: TextStyle(
              color: isTiendaNoAsignadaDisabled ? disabledTextColor : normalTextColor,
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              labelText: 'Otras Tiendas (Fuera de ruta)',
              labelStyle: TextStyle(
                color: isTiendaNoAsignadaDisabled ? Colors.grey : unassignedActiveColor,
                fontWeight: FontWeight.bold,
              ),
              prefixIcon: Icon(
                Icons.storefront_rounded,
                color: isTiendaNoAsignadaDisabled ? Colors.grey : unassignedActiveColor,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.0),
                borderSide: BorderSide(
                  color: isTiendaNoAsignadaDisabled ? disabledBorderColor : unassignedActiveColor,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.0),
                borderSide: BorderSide(color: unassignedActiveColor, width: 2.0),
              ),
              filled: true,
              fillColor: isTiendaNoAsignadaDisabled ? disabledBgColor : unassignedBgColor,
            ),
            initialValue: selectedUnassignedTiendaId,
            items: isTiendaNoAsignadaDisabled
                ? []
                : unassignedTiendas
                    .map((t) => DropdownMenuItem(
                          value: t.id,
                          child: Text(
                            t.nombre,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: normalTextColor),
                          ),
                        ))
                    .toList(),
            onChanged: isTiendaNoAsignadaDisabled
                ? null
                : (val) {
                    setState(() {
                      selectedUnassignedTiendaId = val;
                    });
                  },
          ),
          const SizedBox(height: 16.0),

          // Deudor de la tienda
          TextFormField(
            controller: TextEditingController(
              text: selectedDeudor != null
                  ? '${selectedDeudor.correlativo} - ${selectedDeudor.nombre}'
                  : '',
            ),
            key: ValueKey(selectedDeudor?.id ?? -1),
            enabled: false,
            style: TextStyle(
              color: disabledTextColor,
              fontWeight: FontWeight.bold,
              fontSize: 14.5,
            ),
            decoration: InputDecoration(
              labelText: 'Cliente / Deudor asociado',
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              prefixIcon: const Icon(Icons.person_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.0),
                borderSide: BorderSide(color: disabledBorderColor, width: 1.0),
              ),
              filled: true,
              fillColor: disabledBgColor,
            ),
          ),
          const SizedBox(height: 24.0),

          // Acciones de Botones
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: !hasSelection
                      ? null
                      : () {
                          widget.onCopyLastPedido(
                            selectedTienda.ciudadId,
                            selectedTienda.deudorId,
                            selectedTienda.id,
                          );
                        },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.accentColor,
                    side: BorderSide(
                      color: hasSelection ? AppTheme.accentColor : Colors.grey.shade400,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.0),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                  ),
                  child: const Text(
                    'Copiar Último',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.0),
                  ),
                ),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: ElevatedButton(
                  onPressed: !hasSelection
                      ? null
                      : () {
                          widget.onSave(
                            selectedTienda.ciudadId,
                            selectedTienda.deudorId,
                            selectedTienda.id,
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.0),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                  ),
                  child: const Text(
                    'Crear Borrador',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
        ],
      ),
    );
  }
}

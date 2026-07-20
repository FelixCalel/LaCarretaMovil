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
    // Filter tiendas by country first if a valid country ID is provided
    final baseTiendas = widget.tiendas.where((t) {
      if (widget.userPaisId != 0 && t.paisId != widget.userPaisId) {
        return false;
      }
      return true;
    }).toList();

    debugPrint('DEBUG: userRoutes=${widget.userRoutes}');
    if (baseTiendas.isNotEmpty) {
      debugPrint('DEBUG: First tienda name="${baseTiendas.first.nombre}" rutaId=${baseTiendas.first.rutaId}');
      debugPrint('DEBUG: baseTiendas rutaIds=${baseTiendas.map((t) => t.rutaId).toSet().toList()}');
    }

    // Filter into assigned vs unassigned
    assignedTiendas = baseTiendas
        .where((t) => widget.userRoutes.contains(t.rutaId))
        .toList();
    unassignedTiendas = baseTiendas;
    debugPrint('DEBUG: assignedTiendas count=${assignedTiendas.length}, unassignedTiendas count=${unassignedTiendas.length}');
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

    // Define colors for high-contrast premium UI
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final assignedActiveColor = const Color(0xFF025205); // Dark Green
    final assignedBgColor = isDark ? const Color(0xFF0A2E0C) : const Color(0xFFE8F5E9);

    final unassignedActiveColor = const Color(0xFFD35400); // Orange
    final unassignedBgColor = isDark ? const Color(0xFF381A08) : const Color(0xFFFFF3E0);

    final disabledBgColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final disabledBorderColor = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);

    final normalTextColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final disabledTextColor = isDark ? Colors.grey.shade400 : const Color(0xFF475569);

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
                'Agregar Pedido',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppTheme.primaryDarkColor,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 20.0),

          // Tiendas Asignadas (Dropdown)
          DropdownButtonFormField<int>(
            isExpanded: true,
            dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            style: TextStyle(
              color: isTiendaAsignadaDisabled ? disabledTextColor : normalTextColor,
              fontSize: 15.0,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              labelText: 'Tiendas asignadas',
              labelStyle: TextStyle(
                color: isTiendaAsignadaDisabled ? Colors.grey : assignedActiveColor,
                fontWeight: FontWeight.bold,
              ),
              prefixIcon: Icon(
                Icons.store,
                color: isTiendaAsignadaDisabled ? Colors.grey : assignedActiveColor,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(
                  color: isTiendaAsignadaDisabled ? disabledBorderColor : assignedActiveColor,
                  width: 2.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: assignedActiveColor, width: 2.0),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: disabledBorderColor, width: 1.0),
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
          const SizedBox(height: 20.0),

          // Tiendas NO asignadas (Dropdown)
          DropdownButtonFormField<int>(
            isExpanded: true,
            dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            style: TextStyle(
              color: isTiendaNoAsignadaDisabled ? disabledTextColor : normalTextColor,
              fontSize: 15.0,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              labelText: 'Tiendas NO asignadas',
              labelStyle: TextStyle(
                color: isTiendaNoAsignadaDisabled ? Colors.grey : unassignedActiveColor,
                fontWeight: FontWeight.bold,
              ),
              prefixIcon: Icon(
                Icons.store_mall_directory,
                color: isTiendaNoAsignadaDisabled ? Colors.grey : unassignedActiveColor,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(
                  color: isTiendaNoAsignadaDisabled ? disabledBorderColor : unassignedActiveColor,
                  width: 2.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: unassignedActiveColor, width: 2.0),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: disabledBorderColor, width: 1.0),
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
          const SizedBox(height: 20.0),

          // Deu de la tienda (Info Display)
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
              fontSize: 15.0,
            ),
            decoration: InputDecoration(
              labelText: 'Deu de la tienda',
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: disabledBorderColor, width: 1.5),
              ),
              filled: true,
              fillColor: disabledBgColor,
            ),
          ),
          const SizedBox(height: 24.0),

          // Buttons Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Copiar Último Pedido
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
                    side: BorderSide(
                      color: hasSelection ? Colors.blue : Colors.grey.shade400,
                      width: 2.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                  ),
                  child: Text(
                    'Copiar Último Pedido',
                    style: TextStyle(
                      color: hasSelection ? Colors.blue : Colors.grey.shade500,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(width: 8.0),

              // Cancelar
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: isDark ? Colors.grey.shade600 : Colors.grey.shade500, width: 2.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
                ),
                child: Text(
                  'Cancelar',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.grey.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8.0),

              // Nuevo
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
                    disabledBackgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                  ),
                  child: Text(
                    'Nuevo',
                    style: TextStyle(
                      color: hasSelection ? Colors.white : Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

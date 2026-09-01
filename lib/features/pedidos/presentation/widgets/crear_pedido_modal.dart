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
  CatalogTienda? selectedAssignedTienda;
  CatalogTienda? selectedUnassignedTienda;

  List<CatalogTienda> assignedTiendas = [];
  List<CatalogTienda> unassignedTiendas = [];

  @override
  void initState() {
    super.initState();
    final baseTiendas = widget.tiendas.where((t) {
      if (widget.userPaisId != 0 && t.paisId != 0 && t.paisId != widget.userPaisId) {
        return false;
      }
      return true;
    }).toList();

    assignedTiendas = baseTiendas
        .where((t) => widget.userRoutes.contains(t.rutaId))
        .toList();
    unassignedTiendas = baseTiendas.isNotEmpty ? baseTiendas : widget.tiendas;
  }

  CatalogTienda? getSelectedTienda() {
    return selectedAssignedTienda ?? selectedUnassignedTienda;
  }

  CatalogDeudor? getSelectedDeudor(CatalogTienda? tienda) {
    if (tienda == null) return null;
    return widget.deudores.firstWhere(
      (d) => d.id == tienda.deudorId,
      orElse: () => CatalogDeudor(id: 0, nombre: 'Sin Deudor', correlativo: ''),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedTienda = getSelectedTienda();
    final selectedDeudor = getSelectedDeudor(selectedTienda);

    final isTiendaAsignadaDisabled = selectedUnassignedTienda != null;
    final isTiendaNoAsignadaDisabled = selectedAssignedTienda != null;

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
      child: SingleChildScrollView(
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

            // Tiendas Asignadas (Searchable Selector)
            SearchableTiendaField(
              label: 'Tiendas Asignadas (Ruta activa)',
              hintText: 'Escribe o selecciona tienda...',
              icon: Icons.store_rounded,
              activeColor: assignedActiveColor,
              activeBgColor: assignedBgColor,
              tiendas: assignedTiendas,
              selectedTienda: selectedAssignedTienda,
              isDisabled: isTiendaAsignadaDisabled,
              onSelected: (tienda) {
                setState(() {
                  selectedAssignedTienda = tienda;
                  if (tienda != null) selectedUnassignedTienda = null;
                });
              },
            ),
            const SizedBox(height: 16.0),

            // Tiendas NO asignadas (Searchable Selector)
            SearchableTiendaField(
              label: 'Tiendas No Asignadas (Fuera de ruta)',
              hintText: 'Escribe o selecciona tienda...',
              icon: Icons.storefront_rounded,
              activeColor: unassignedActiveColor,
              activeBgColor: unassignedBgColor,
              tiendas: unassignedTiendas,
              selectedTienda: selectedUnassignedTienda,
              isDisabled: isTiendaNoAsignadaDisabled,
              onSelected: (tienda) {
                setState(() {
                  selectedUnassignedTienda = tienda;
                  if (tienda != null) selectedAssignedTienda = null;
                });
              },
            ),
            const SizedBox(height: 16.0),

            // Deudor asociado
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person_rounded, size: 16, color: disabledTextColor),
                    const SizedBox(width: 6),
                    Text(
                      'CLIENTE / DEUDOR ASOCIADO',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: disabledTextColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: TextEditingController(
                    text: selectedDeudor != null
                        ? '${selectedDeudor.correlativo} - ${selectedDeudor.nombre}'
                        : '',
                  ),
                  key: ValueKey(selectedDeudor?.id ?? -1),
                  enabled: false,
                  style: TextStyle(
                    color: normalTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.0,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Se asigna automáticamente al elegir tienda',
                    hintStyle: TextStyle(
                      color: disabledTextColor.withValues(alpha: 0.6),
                      fontSize: 13.0,
                      fontWeight: FontWeight.normal,
                    ),
                    prefixIcon: const Icon(Icons.badge_rounded, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.0),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.0),
                      borderSide: BorderSide(color: disabledBorderColor, width: 1.0),
                    ),
                    filled: true,
                    fillColor: disabledBgColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24.0),

            // Botones de acción
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
      ),
    );
  }
}

class SearchableTiendaField extends StatefulWidget {
  final String label;
  final String hintText;
  final IconData icon;
  final Color activeColor;
  final Color activeBgColor;
  final List<CatalogTienda> tiendas;
  final CatalogTienda? selectedTienda;
  final bool isDisabled;
  final ValueChanged<CatalogTienda?> onSelected;

  const SearchableTiendaField({
    super.key,
    required this.label,
    required this.hintText,
    required this.icon,
    required this.activeColor,
    required this.activeBgColor,
    required this.tiendas,
    required this.selectedTienda,
    required this.isDisabled,
    required this.onSelected,
  });

  @override
  State<SearchableTiendaField> createState() => _SearchableTiendaFieldState();
}

class _SearchableTiendaFieldState extends State<SearchableTiendaField> {
  late TextEditingController _textController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.selectedTienda?.nombre ?? '');
  }

  @override
  void didUpdateWidget(covariant SearchableTiendaField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedTienda != oldWidget.selectedTienda) {
      final newText = widget.selectedTienda?.nombre ?? '';
      if (_textController.text != newText) {
        _textController.text = newText;
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final normalTextColor = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final disabledTextColor = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final disabledBgColor = isDark ? const Color(0xFF131C38) : const Color(0xFFF1F5F9);
    final disabledBorderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(widget.icon, size: 16, color: widget.isDisabled ? Colors.grey : widget.activeColor),
            const SizedBox(width: 6),
            Text(
              widget.label.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: widget.isDisabled ? Colors.grey : widget.activeColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        RawAutocomplete<CatalogTienda>(
          textEditingController: _textController,
          focusNode: _focusNode,
          displayStringForOption: (option) => option.nombre,
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (widget.isDisabled) return const Iterable<CatalogTienda>.empty();
            if (textEditingValue.text.isEmpty) {
              return widget.tiendas;
            }
            final query = textEditingValue.text.toLowerCase().trim();
            return widget.tiendas.where((t) => t.nombre.toLowerCase().contains(query));
          },
          onSelected: (CatalogTienda selection) {
            _textController.text = selection.nombre;
            widget.onSelected(selection);
            _focusNode.unfocus();
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            final hasText = controller.text.isNotEmpty;
            return TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: !widget.isDisabled,
              style: TextStyle(
                color: widget.isDisabled ? disabledTextColor : normalTextColor,
                fontSize: 14.0,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  color: widget.isDisabled ? disabledTextColor.withValues(alpha: 0.5) : Colors.grey,
                  fontSize: 13.5,
                  fontWeight: FontWeight.normal,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: widget.isDisabled ? Colors.grey : widget.activeColor,
                  size: 20,
                ),
                suffixIcon: widget.isDisabled
                    ? null
                    : (hasText || widget.selectedTienda != null)
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              controller.clear();
                              widget.onSelected(null);
                            },
                          )
                        : Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: widget.activeColor,
                          ),
                filled: true,
                fillColor: widget.isDisabled ? disabledBgColor : widget.activeBgColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.0),
                  borderSide: BorderSide(
                    color: widget.isDisabled ? disabledBorderColor : widget.activeColor.withValues(alpha: 0.6),
                    width: 1.2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.0),
                  borderSide: BorderSide(color: widget.activeColor, width: 2.0),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.0),
                  borderSide: BorderSide(color: disabledBorderColor, width: 1.0),
                ),
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            final optionsList = options.toList();
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 8.0,
                borderRadius: BorderRadius.circular(14.0),
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                shadowColor: Colors.black45,
                child: Container(
                  width: MediaQuery.of(context).size.width - 40,
                  constraints: const BoxConstraints(maxHeight: 220),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14.0),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: optionsList.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'No se encontraron tiendas',
                            style: TextStyle(
                              color: disabledTextColor,
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          shrinkWrap: true,
                          itemCount: optionsList.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            thickness: 0.5,
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                          ),
                          itemBuilder: (context, index) {
                            final option = optionsList[index];
                            final isSelected = option.id == widget.selectedTienda?.id;
                            return InkWell(
                              onTap: () => onSelected(option),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                                color: isSelected
                                    ? (isDark ? const Color(0xFF09290B) : const Color(0xFFF0FDF4))
                                    : null,
                                child: Row(
                                  children: [
                                    Icon(
                                      widget.icon,
                                      size: 18,
                                      color: isSelected ? widget.activeColor : Colors.grey,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        option.nombre,
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          color: isSelected ? widget.activeColor : normalTextColor,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(Icons.check_rounded, color: widget.activeColor, size: 18),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

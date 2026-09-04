import 'package:flutter/material.dart';
import '../../domain/produccion_model.dart';
import 'receta_materials_view.dart';

const Color _emeraldColor = Color(0xFF10B981);

class ConsolidadoProductCard extends StatefulWidget {
  final ConsolidatedProductModel item;
  final bool isSelected;
  final bool isExpanded;
  final bool isLoadingReceta;
  final List<RecetaLineaModel>? recetaLineas;
  final List<AlmacenModel> almacenes;
  final Function(bool isSelected) onToggleSelection;
  final VoidCallback onToggleExpand;
  final Function(double newQty) onUpdateProcesado;
  final Function(String newTrazab) onUpdateTrazabDig;
  final Function(bool isComplete) onUpdateCompleto;
  final Function(int almacenId) onUpdateAlmacen;
  final Function(int recetaId, bool newState) onToggleMaterialState;
  final Function(RecetaLineaModel linea)? onOpenRechazo;
  final Function(RecetaLineaModel linea)? onOpenProveedores;

  const ConsolidadoProductCard({
    super.key,
    required this.item,
    required this.isSelected,
    required this.isExpanded,
    this.isLoadingReceta = false,
    this.recetaLineas,
    required this.almacenes,
    required this.onToggleSelection,
    required this.onToggleExpand,
    required this.onUpdateProcesado,
    required this.onUpdateTrazabDig,
    required this.onUpdateCompleto,
    required this.onUpdateAlmacen,
    required this.onToggleMaterialState,
    this.onOpenRechazo,
    this.onOpenProveedores,
  });

  @override
  State<ConsolidadoProductCard> createState() => _ConsolidadoProductCardState();
}

class _ConsolidadoProductCardState extends State<ConsolidadoProductCard> {
  late TextEditingController _procesadoCtrl;
  late TextEditingController _trazabCtrl;
  bool _isEditingProcesado = false;

  @override
  void initState() {
    super.initState();
    _procesadoCtrl = TextEditingController(
      text: widget.item.cantidadProcesada == 0
          ? ''
          : _formatNumber(widget.item.cantidadProcesada),
    );
    _trazabCtrl = TextEditingController(text: widget.item.trazabilidadDig);
  }

  @override
  void didUpdateWidget(covariant ConsolidadoProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditingProcesado &&
        oldWidget.item.cantidadProcesada != widget.item.cantidadProcesada) {
      _procesadoCtrl.text = widget.item.cantidadProcesada == 0
          ? ''
          : _formatNumber(widget.item.cantidadProcesada);
    }
    if (oldWidget.item.trazabilidadDig != widget.item.trazabilidadDig) {
      _trazabCtrl.text = widget.item.trazabilidadDig;
    }
  }

  @override
  void dispose() {
    _procesadoCtrl.dispose();
    _trazabCtrl.dispose();
    super.dispose();
  }

  String _formatNumber(double n) {
    if (n % 1 == 0) return n.toInt().toString();
    return n.toStringAsFixed(2);
  }

  void _submitProcesado() {
    final parsed = double.tryParse(_procesadoCtrl.text.trim()) ?? 0.0;
    if (parsed != widget.item.cantidadProcesada) {
      widget.onUpdateProcesado(parsed);
    }
    setState(() {
      _isEditingProcesado = false;
    });
  }

  void _showTrazabDialog() {
    final controller = TextEditingController(text: widget.item.trazabilidadDig);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Trazabilidad Digitador', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Ej. 0260234',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              widget.onUpdateTrazabDig(controller.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final faltante = widget.item.faltante;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: widget.isSelected
              ? _emeraldColor
              : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
          width: widget.isSelected ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fila Superior: Checkbox Selección, Expand, Nombre Producto y Almacén
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Checkbox de selección
                    Checkbox(
                      value: widget.isSelected,
                      activeColor: _emeraldColor,
                      visualDensity: VisualDensity.compact,
                      onChanged: (val) {
                        if (val != null) widget.onToggleSelection(val);
                      },
                    ),
                    // Botón expandir receta
                    IconButton(
                      icon: Icon(
                        widget.isExpanded
                            ? Icons.keyboard_arrow_down_rounded
                            : Icons.keyboard_arrow_right_rounded,
                        color: Colors.grey.shade600,
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: widget.onToggleExpand,
                    ),
                    const SizedBox(width: 6),
                    // Producto y código
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.item.productoNombre,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          if (widget.item.itemCode != null &&
                              widget.item.itemCode!.isNotEmpty)
                            Text(
                              widget.item.itemCode!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Selector Almacén Destino
                    _buildAlmacenDropdown(isDark),
                  ],
                ),
                const SizedBox(height: 8),

                // Fila Inferior: Trazab. Dig, Solic. Ventas, Completado, Procesado y Faltante
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Trazabilidad Digitador
                    InkWell(
                      onTap: _showTrazabDialog,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isDark
                                ? Colors.grey.shade700
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              widget.item.trazabilidadDig.isEmpty
                                  ? '—'
                                  : widget.item.trazabilidadDig,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'TRAZAB. DIG',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Solic. Ventas
                    Column(
                      children: [
                        Text(
                          _formatNumber(widget.item.cantidadUnidadTotal),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        Text(
                          'SOLICITA',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),

                    // Completado Checkbox
                    Column(
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: widget.item.completo,
                            activeColor: _emeraldColor,
                            visualDensity: VisualDensity.compact,
                            onChanged: (val) {
                              if (val != null) widget.onUpdateCompleto(val);
                            },
                          ),
                        ),
                        Text(
                          'COMPLETO',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),

                    // Cantidad Procesada (Input rápido)
                    Column(
                      children: [
                        SizedBox(
                          width: 65,
                          height: 30,
                          child: TextField(
                            controller: _procesadoCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 4),
                              isDense: true,
                              hintText: '0',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade400),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(
                                    color: _emeraldColor, width: 1.5),
                              ),
                            ),
                            onTap: () => setState(() => _isEditingProcesado = true),
                            onSubmitted: (_) => _submitProcesado(),
                            onTapOutside: (_) => _submitProcesado(),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'PROCESADO',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),

                    // Faltante
                    Column(
                      children: [
                        Text(
                          _formatNumber(faltante),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: faltante > 0
                                ? Colors.red.shade600
                                : Colors.grey.shade400,
                          ),
                        ),
                        Text(
                          'FALTANTE',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Sección de Receta Expandible
          if (widget.isExpanded)
            RecetaMaterialsView(
              lineas: widget.recetaLineas ?? [],
              isLoading: widget.isLoadingReceta,
              onToggleState: widget.onToggleMaterialState,
              onOpenRechazo: widget.onOpenRechazo,
              onOpenProveedores: widget.onOpenProveedores,
            ),
        ],
      ),
    );
  }

  Widget _buildAlmacenDropdown(bool isDark) {
    final currentId = widget.item.idAlmacen;
    final validAlmacen =
        widget.almacenes.any((a) => a.id == currentId) ? currentId : null;

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: validAlmacen,
          hint: const Text(
            'Almacén',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
          isDense: true,
          icon: const Icon(Icons.arrow_drop_down, size: 18),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
          items: widget.almacenes.map((a) {
            return DropdownMenuItem<int>(
              value: a.id,
              child: Text(a.nombre, style: const TextStyle(fontSize: 11)),
            );
          }).toList(),
          onChanged: (newId) {
            if (newId != null) widget.onUpdateAlmacen(newId);
          },
        ),
      ),
    );
  }
}

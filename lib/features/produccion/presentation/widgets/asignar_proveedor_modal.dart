import 'package:flutter/material.dart';
import '../../domain/produccion_model.dart';

const Color _emeraldColor = Color(0xFF10B981);

class AsignarProveedorModal extends StatefulWidget {
  final RecetaLineaModel recetaLinea;
  final int pedidoId;
  final double? cantidadProcesada;
  final Function(List<ProveedorRecetaModel> proveedores) onSave;

  const AsignarProveedorModal({
    super.key,
    required this.recetaLinea,
    required this.pedidoId,
    this.cantidadProcesada,
    required this.onSave,
  });

  @override
  State<AsignarProveedorModal> createState() => _AsignarProveedorModalState();
}

class _AsignarProveedorModalState extends State<AsignarProveedorModal> {
  late List<ProveedorRecetaModel> _proveedores;
  bool _isAdding = false;
  bool _isSaving = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _trazController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _proveedores = List<ProveedorRecetaModel>.from(widget.recetaLinea.proveedores);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    _trazController.dispose();
    super.dispose();
  }

  double get _totalAsignado {
    return _proveedores.fold<double>(0.0, (sum, p) => sum + p.cantidad);
  }

  void _addProveedor() {
    final name = _nameController.text.trim();
    final qty = double.tryParse(_qtyController.text.trim()) ?? 0.0;
    final traz = _trazController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingrese el nombre o código del proveedor'),
          backgroundColor: Colors.amber,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingrese una cantidad mayor a 0'),
          backgroundColor: Colors.amber,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _proveedores.add(
        ProveedorRecetaModel(
          id: DateTime.now().millisecondsSinceEpoch,
          proveedorName: name,
          proveedorCode: name,
          cantidad: qty,
          trazabilidad: traz.isNotEmpty ? traz : null,
        ),
      );
      _isAdding = false;
      _nameController.clear();
      _qtyController.clear();
      _trazController.clear();
    });
  }

  void _removeProveedor(int index) {
    setState(() {
      _proveedores.removeAt(index);
    });
  }

  void _updateCantidad(int index, String val) {
    final qty = double.tryParse(val);
    if (qty != null && qty >= 0) {
      setState(() {
        _proveedores[index] = _proveedores[index].copyWith(cantidad: qty);
      });
    }
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    try {
      await widget.onSave(_proveedores);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final requiredQty = widget.recetaLinea.cantidadBase;
    final unit = widget.recetaLinea.nombreUnidad;

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      insetPadding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: isLandscape ? 8 : 20,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: 520,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Asignar Proveedores y Lotes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.recetaLinea.item,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Resumen de cantidad requerida vs asignada
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Requerido',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        Text(
                          '${requiredQty.toStringAsFixed(2)} $unit',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Total Asignado',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        Text(
                          '${_totalAsignado.toStringAsFixed(2)} $unit',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _totalAsignado >= requiredQty
                                ? _emeraldColor
                                : Colors.amber.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Lista de proveedores asignados
              Expanded(
                child: _proveedores.isEmpty && !_isAdding
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline_rounded,
                              size: 40,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Sin proveedores asignados a este material.',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () => setState(() => _isAdding = true),
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Agregar Proveedor'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _emeraldColor,
                                side: const BorderSide(color: _emeraldColor),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        shrinkWrap: true,
                        children: [
                          ..._proveedores.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final p = entry.value;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                                ),
                              ),
                              color: isDark ? const Color(0xFF0F172A) : Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p.proveedorName ?? p.proveedorCode ?? 'Proveedor',
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (p.trazabilidad != null && p.trazabilidad!.isNotEmpty)
                                            Text(
                                              'Traz: ${p.trazabilidad}',
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                color: Colors.grey.shade400,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: 90,
                                      child: TextFormField(
                                        initialValue: p.cantidad.toString(),
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        style: const TextStyle(fontSize: 12),
                                        decoration: InputDecoration(
                                          isDense: true,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                          suffixText: unit,
                                          suffixStyle: const TextStyle(fontSize: 10),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                        ),
                                        onChanged: (v) => _updateCantidad(idx, v),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                      onPressed: () => _removeProveedor(idx),
                                      tooltip: 'Eliminar',
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),

                          // Formulario para agregar nuevo proveedor
                          if (_isAdding) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(top: 8),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _emeraldColor.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Nuevo Proveedor / Lote',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _emeraldColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _nameController,
                                    style: const TextStyle(fontSize: 12),
                                    decoration: const InputDecoration(
                                      labelText: 'Nombre o Código del Proveedor',
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _qtyController,
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          style: const TextStyle(fontSize: 12),
                                          decoration: InputDecoration(
                                            labelText: 'Cantidad ($unit)',
                                            isDense: true,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _trazController,
                                          style: const TextStyle(fontSize: 12),
                                          decoration: const InputDecoration(
                                            labelText: 'Trazabilidad (opcional)',
                                            isDense: true,
                                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: () => setState(() => _isAdding = false),
                                        child: const Text('Cancelar', style: TextStyle(fontSize: 12)),
                                      ),
                                      const SizedBox(width: 6),
                                      ElevatedButton(
                                        onPressed: _addProveedor,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _emeraldColor,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        ),
                                        child: const Text('Añadir', style: TextStyle(fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ] else if (_proveedores.isNotEmpty) ...[
                            TextButton.icon(
                              onPressed: () => setState(() => _isAdding = true),
                              icon: const Icon(Icons.add, size: 16, color: _emeraldColor),
                              label: const Text(
                                'Añadir otro proveedor',
                                style: TextStyle(color: _emeraldColor, fontSize: 12),
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
              const SizedBox(height: 16),

              // Botones de acción inferiores
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _emeraldColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Guardar Asignación',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

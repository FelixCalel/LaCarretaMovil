import 'package:flutter/material.dart';

class RegistrarRechazoModal extends StatefulWidget {
  final String title;
  final String subtitle;
  final double maxQuantity;
  final String unit;
  final Future<void> Function(double cantidad, String comentario) onConfirm;

  const RegistrarRechazoModal({
    super.key,
    required this.title,
    required this.subtitle,
    required this.maxQuantity,
    this.unit = 'unidades',
    required this.onConfirm,
  });

  @override
  State<RegistrarRechazoModal> createState() => _RegistrarRechazoModalState();
}

class _RegistrarRechazoModalState extends State<RegistrarRechazoModal> {
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _comentarioController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _qtyController.dispose();
    _comentarioController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final qty = double.tryParse(_qtyController.text.trim()) ?? 0.0;
    final comentario = _comentarioController.text.trim();

    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingrese una cantidad a rechazar mayor a 0'),
          backgroundColor: Colors.amber,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (comentario.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingrese el motivo o comentario del rechazo'),
          backgroundColor: Colors.amber,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await widget.onConfirm(qty, comentario);
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

    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      insetPadding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: isLandscape ? 10 : 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 440,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.red,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                widget.subtitle,
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),

              // Campo de cantidad a rechazar
              TextFormField(
                controller: _qtyController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Cantidad rechazada (${widget.unit})',
                  hintText: 'Ej. 2.50',
                  suffixText: widget.unit,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 14),

              // Campo de motivo / comentario
              TextFormField(
                controller: _comentarioController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Motivo o Comentario del Rechazo',
                  hintText: 'Describa el motivo del rechazo...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 20),

              // Botones de acción
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
                      onPressed: _isSaving ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
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
                              'Registrar Rechazo',
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

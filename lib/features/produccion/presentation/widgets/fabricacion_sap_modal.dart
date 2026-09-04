import 'package:flutter/material.dart';

const Color _emeraldColor = Color(0xFF10B981);

class FabricacionSapModal extends StatefulWidget {
  final int count;
  final bool isProcessing;
  final Function(String fecha, String comentario) onConfirm;

  const FabricacionSapModal({
    super.key,
    required this.count,
    this.isProcessing = false,
    required this.onConfirm,
  });

  @override
  State<FabricacionSapModal> createState() => _FabricacionSapModalState();
}

class _FabricacionSapModalState extends State<FabricacionSapModal> {
  late DateTime _selectedDate;
  final TextEditingController _commentCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateStr = _formatDate(_selectedDate);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 550,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Cargar a SAP (${widget.count} productos)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Selector de fecha
                  const Text(
                    'Fecha de Orden (Obligatorio)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(dateStr, style: const TextStyle(fontSize: 13)),
                          const Icon(Icons.calendar_today_rounded, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Comentario para SAP
                  const Text(
                    'Comentario (Obligatorio para SAP)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _commentCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Ingrese el comentario obligatorio para SAP...',
                      hintStyle: const TextStyle(fontSize: 12),
                      contentPadding: const EdgeInsets.all(10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Botón de envío
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: widget.isProcessing || _commentCtrl.text.trim().isEmpty
                          ? null
                          : () {
                              widget.onConfirm(dateStr, _commentCtrl.text.trim());
                              Navigator.pop(context);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _emeraldColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: widget.isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Confirmar Envío a SAP',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

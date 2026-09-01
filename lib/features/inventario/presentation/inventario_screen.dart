import 'package:flutter/material.dart';
import '../../../core/presentation/main_layout.dart';
import '../../../core/presentation/widgets/coming_soon_view.dart';

class InventarioScreen extends StatelessWidget {
  final String? opcion;

  const InventarioScreen({super.key, this.opcion});

  @override
  Widget build(BuildContext context) {
    final title = opcion != null && opcion!.isNotEmpty
        ? 'Inventario: $opcion'
        : 'Módulo de Inventario';

    return MainLayout(
      title: title,
      body: ComingSoonView(
        moduleName: opcion ?? 'Inventario',
        icon: Icons.inventory_2_rounded,
        accentColor: const Color(0xFF10B981),
      ),
    );
  }
}

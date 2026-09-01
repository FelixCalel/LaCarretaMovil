import 'package:flutter/material.dart';
import '../../../core/presentation/main_layout.dart';
import '../../../core/presentation/widgets/coming_soon_view.dart';

class GestionAreaScreen extends StatelessWidget {
  final String? opcion;

  const GestionAreaScreen({super.key, this.opcion});

  @override
  Widget build(BuildContext context) {
    final title = opcion != null && opcion!.isNotEmpty
        ? 'Gestión Área: $opcion'
        : 'Gestión de Área';

    return MainLayout(
      title: title,
      body: ComingSoonView(
        moduleName: opcion ?? 'Gestión de Área',
        icon: Icons.apartment_rounded,
        accentColor: const Color(0xFF06B6D4),
      ),
    );
  }
}

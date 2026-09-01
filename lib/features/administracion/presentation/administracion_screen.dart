import 'package:flutter/material.dart';
import '../../../core/presentation/main_layout.dart';
import '../../../core/presentation/widgets/coming_soon_view.dart';

class AdministracionScreen extends StatelessWidget {
  final String? opcion;

  const AdministracionScreen({super.key, this.opcion});

  @override
  Widget build(BuildContext context) {
    final title = opcion != null && opcion!.isNotEmpty
        ? 'Administración: $opcion'
        : 'Módulo de Administración';

    return MainLayout(
      title: title,
      body: ComingSoonView(
        moduleName: opcion ?? 'Administración',
        icon: Icons.admin_panel_settings_rounded,
        accentColor: const Color(0xFF3B82F6),
      ),
    );
  }
}

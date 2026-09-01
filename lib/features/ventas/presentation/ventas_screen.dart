import 'package:flutter/material.dart';
import '../../../core/presentation/main_layout.dart';
import '../../../core/presentation/widgets/coming_soon_view.dart';

class VentasScreen extends StatelessWidget {
  const VentasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainLayout(
      title: 'Módulo de Ventas',
      body: ComingSoonView(
        moduleName: 'Ventas',
        icon: Icons.monetization_on_rounded,
        accentColor: Color(0xFF8B5CF6),
      ),
    );
  }
}

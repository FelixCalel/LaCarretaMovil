import 'package:flutter/material.dart';
import '../../../core/presentation/main_layout.dart';
import '../../../core/presentation/widgets/coming_soon_view.dart';

class ProduccionScreen extends StatelessWidget {
  const ProduccionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainLayout(
      title: 'Módulo de Producción',
      body: ComingSoonView(
        moduleName: 'Producción',
        icon: Icons.precision_manufacturing_rounded,
        accentColor: Color(0xFFF59E0B),
      ),
    );
  }
}

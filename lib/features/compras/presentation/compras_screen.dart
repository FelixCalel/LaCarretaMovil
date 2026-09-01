import 'package:flutter/material.dart';
import '../../../core/presentation/main_layout.dart';
import '../../../core/presentation/widgets/coming_soon_view.dart';

class ComprasScreen extends StatelessWidget {
  const ComprasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainLayout(
      title: 'Módulo de Compras',
      body: ComingSoonView(
        moduleName: 'Compras',
        icon: Icons.shopping_cart_checkout_rounded,
        accentColor: Color(0xFFEC4899),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/modulo_model.dart';

class MainBottomNav extends StatelessWidget {
  final List<ModuloModel> groupedModules;
  final String location;
  final Color primaryColor;

  const MainBottomNav({
    super.key,
    required this.groupedModules,
    required this.location,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasPedidosModule = groupedModules.any((m) => m.id == 2);
    final bool hasVentasModule = groupedModules.any((m) => m.id == 3);
    final bool hasProduccionModule = groupedModules.any((m) => m.id == 13);
    final bool hasComprasModule = groupedModules.any((m) => m.id == 9);

    final List<String> barRoutes = ['/home'];
    final List<NavigationDestination> destinations = [
      const NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home_rounded),
        label: 'Inicio',
      ),
    ];

    if (hasPedidosModule) {
      barRoutes.add('/pedidos');
      destinations.add(const NavigationDestination(
        icon: Icon(Icons.shopping_basket_outlined),
        selectedIcon: Icon(Icons.shopping_basket_rounded),
        label: 'Pedidos',
      ));
    }
    if (hasVentasModule) {
      barRoutes.add('/ventas');
      destinations.add(const NavigationDestination(
        icon: Icon(Icons.monetization_on_outlined),
        selectedIcon: Icon(Icons.monetization_on_rounded),
        label: 'Ventas',
      ));
    }
    if (hasProduccionModule) {
      barRoutes.add('/produccion');
      destinations.add(const NavigationDestination(
        icon: Icon(Icons.precision_manufacturing_outlined),
        selectedIcon: Icon(Icons.precision_manufacturing_rounded),
        label: 'Producción',
      ));
    }
    if (hasComprasModule) {
      barRoutes.add('/compras');
      destinations.add(const NavigationDestination(
        icon: Icon(Icons.shopping_cart_checkout_outlined),
        selectedIcon: Icon(Icons.shopping_cart_checkout_rounded),
        label: 'Compras',
      ));
    }

    if (destinations.length < 2) return const SizedBox.shrink();

    int getSelectedIndex() {
      final index = barRoutes.indexOf(location);
      if (index != -1) return index;
      for (int i = 0; i < barRoutes.length; i++) {
        if (location.startsWith(barRoutes[i]) && barRoutes[i] != '/home') {
          return i;
        }
      }
      return 0;
    }

    void onItemTapped(int index) {
      if (index >= 0 && index < barRoutes.length) {
        context.go(barRoutes[index]);
      }
    }

    return NavigationBar(
      selectedIndex: getSelectedIndex(),
      onDestinationSelected: onItemTapped,
      destinations: destinations,
    );
  }
}

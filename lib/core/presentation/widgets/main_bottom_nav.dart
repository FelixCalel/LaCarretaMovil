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

    final List<String> barRoutes = ['/home'];
    final List<BottomNavigationBarItem> barItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: 'Inicio',
      ),
    ];

    if (hasPedidosModule) {
      barRoutes.add('/pedidos');
      barItems.add(const BottomNavigationBarItem(
        icon: Icon(Icons.shopping_basket),
        label: 'Pedidos',
      ));
    }
    if (hasVentasModule) {
      barRoutes.add('/ventas');
      barItems.add(const BottomNavigationBarItem(
        icon: Icon(Icons.monetization_on),
        label: 'Ventas',
      ));
    }
    if (hasProduccionModule) {
      barRoutes.add('/produccion');
      barItems.add(const BottomNavigationBarItem(
        icon: Icon(Icons.precision_manufacturing),
        label: 'Producción',
      ));
    }

    if (barItems.length < 2) return const SizedBox.shrink();

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

    return BottomNavigationBar(
      currentIndex: getSelectedIndex(),
      onTap: onItemTapped,
      selectedItemColor: primaryColor,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      items: barItems,
    );
  }
}

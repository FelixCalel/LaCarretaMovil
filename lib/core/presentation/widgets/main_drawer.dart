import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/modulo_model.dart';
import '../../theme/app_theme.dart';

class MainDrawer extends StatelessWidget {
  final String userName;
  final String userRole;
  final List<ModuloModel> groupedModules;
  final String location;
  final Color primaryColor;
  final VoidCallback onLogout;

  const MainDrawer({
    super.key,
    required this.userName,
    required this.userRole,
    required this.groupedModules,
    required this.location,
    required this.primaryColor,
    required this.onLogout,
  });

  IconData _getIconData(String name) {
    switch (name) {
      case 'FaTools': return Icons.build;
      case 'MdPerson': return Icons.person;
      case 'FiShoppingCart': return Icons.shopping_cart;
      case 'FaCashRegister': return Icons.point_of_sale;
      case 'FiClipboard': return Icons.assignment;
      case 'AiFillDashboard': return Icons.dashboard;
      case 'FaClipboardList': return Icons.assignment;
      case 'BsFillHouseDoorFill': return Icons.home;
      case 'FaShippingFast': return Icons.local_shipping;
      case 'BsGraphUp': return Icons.trending_up;
      case 'MdApproval': return Icons.check_circle;
      case 'FaCheckCircle': return Icons.done;
      case 'BsPersonCheckFill': return Icons.person_pin;
      case 'FiArchive': return Icons.archive;
      case 'MdEvent': return Icons.event;
      case 'FaBook': return Icons.book;
      case 'MdShoppingCart': return Icons.shopping_basket;
      case 'FaUsers': return Icons.people;
      case 'AiOutlinePhone': return Icons.phone;
      case 'MdAssignmentTurnedIn': return Icons.assignment_turned_in;
      case 'FaNetworkWired': return Icons.lan;
      default: return Icons.folder_open;
    }
  }

  void _navigateToOption(BuildContext context, String routePath, String optionName) {
    if (optionName == 'Crear Pedido' || optionName == 'Historial Pedido') {
      context.go('/pedidos');
    } else if (optionName == 'Pedidos Entrantes' || optionName == 'Exportar Pedido') {
      context.go('/ventas');
    } else if (optionName == 'Asignación de Áreas' || optionName == 'Pendiente') {
      context.go('/produccion');
    } else if (optionName == 'Comprador' || optionName == 'Jefe de compras' || optionName == 'Control de Calidad') {
      context.go('/compras');
    } else {
      if (routePath.contains('pedido')) {
        context.go('/pedidos');
      } else if (routePath.contains('ventas') || routePath.contains('exportar')) {
        context.go('/ventas');
      } else if (routePath.contains('produccion') || routePath.contains('areas')) {
        context.go('/produccion');
      } else if (routePath.contains('compras') || routePath.contains('comprador')) {
        context.go('/compras');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.primaryLightColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/images/LogoLaCarreta.png',
                      height: 50.0,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Icon(Icons.store, color: AppTheme.primaryColor),
                        );
                      },
                    ),
                    const SizedBox(width: 12.0),
                    const Text(
                      'La Carreta',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12.0),
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
                Text(
                  userRole.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.home),
                  title: const Text('Inicio'),
                  selected: location == '/home',
                  selectedColor: primaryColor,
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/home');
                  },
                ),
                ...groupedModules.map((modulo) {
                  final bool isModuloSelected = (location == '/pedidos' && modulo.id == 2) ||
                      (location == '/ventas' && modulo.id == 3) ||
                      (location == '/compras' && modulo.id == 9) ||
                      (location == '/produccion' && modulo.id == 13);

                  if (modulo.opciones.isEmpty) {
                    return ListTile(
                      leading: Icon(_getIconData(modulo.icono)),
                      title: Text(modulo.nombre),
                      selected: isModuloSelected,
                      selectedColor: primaryColor,
                      onTap: () {
                        Navigator.pop(context);
                        if (modulo.id == 2) context.go('/pedidos');
                        if (modulo.id == 3) context.go('/ventas');
                        if (modulo.id == 9) context.go('/compras');
                        if (modulo.id == 13) context.go('/produccion');
                      },
                    );
                  }

                  return ExpansionTile(
                    leading: Icon(
                      _getIconData(modulo.icono),
                      color: isModuloSelected ? primaryColor : null,
                    ),
                    title: Text(
                      modulo.nombre,
                      style: TextStyle(
                        color: isModuloSelected ? primaryColor : null,
                        fontWeight: isModuloSelected ? FontWeight.bold : null,
                      ),
                    ),
                    children: modulo.opciones.map((opcion) {
                      final bool isOptionSelected =
                          (location == '/pedidos' && (opcion.nombre == 'Crear Pedido' || opcion.nombre == 'Historial Pedido')) ||
                          (location == '/ventas' && (opcion.nombre == 'Pedidos Entrantes' || opcion.nombre == 'Exportar Pedido')) ||
                          (location == '/produccion' && (opcion.nombre == 'Asignación de Áreas' || opcion.nombre == 'Pendiente')) ||
                          (location == '/compras' && (opcion.nombre == 'Comprador' || opcion.nombre == 'Jefe de compras' || opcion.nombre == 'Control de Calidad'));

                      return ListTile(
                        contentPadding: const EdgeInsets.only(left: 32.0, right: 16.0),
                        leading: Icon(
                          _getIconData(opcion.icono),
                          size: 20.0,
                          color: isOptionSelected ? primaryColor : null,
                        ),
                        title: Text(
                          opcion.nombre,
                          style: TextStyle(
                            fontSize: 14.0,
                            color: isOptionSelected ? primaryColor : null,
                            fontWeight: isOptionSelected ? FontWeight.bold : null,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _navigateToOption(context, opcion.ruta, opcion.nombre);
                        },
                      );
                    }).toList(),
                  );
                }),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.redAccent)),
            onTap: () {
              Navigator.pop(context);
              onLogout();
            },
          ),
          const SizedBox(height: 12.0),
        ],
      ),
    );
  }
}

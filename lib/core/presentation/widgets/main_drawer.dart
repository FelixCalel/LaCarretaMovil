import 'dart:convert';
import 'dart:typed_data';
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
  final String? userAvatar;

  const MainDrawer({
    super.key,
    required this.userName,
    required this.userRole,
    required this.groupedModules,
    required this.location,
    required this.primaryColor,
    required this.onLogout,
    this.userAvatar,
  });

  IconData _getIconData(String name) {
    switch (name) {
      case 'FaTools': return Icons.build_rounded;
      case 'MdPerson': return Icons.person_rounded;
      case 'FiShoppingCart': return Icons.shopping_cart_rounded;
      case 'FaCashRegister': return Icons.point_of_sale_rounded;
      case 'FiClipboard': return Icons.assignment_rounded;
      case 'AiFillDashboard': return Icons.dashboard_rounded;
      case 'FaClipboardList': return Icons.assignment_rounded;
      case 'BsFillHouseDoorFill': return Icons.home_rounded;
      case 'FaShippingFast': return Icons.local_shipping_rounded;
      case 'BsGraphUp': return Icons.trending_up_rounded;
      case 'MdApproval': return Icons.check_circle_rounded;
      case 'FaCheckCircle': return Icons.done_all_rounded;
      case 'BsPersonCheckFill': return Icons.person_pin_rounded;
      case 'FiArchive': return Icons.archive_rounded;
      case 'MdEvent': return Icons.event_rounded;
      case 'FaBook': return Icons.menu_book_rounded;
      case 'MdShoppingCart': return Icons.shopping_basket_rounded;
      case 'FaUsers': return Icons.people_alt_rounded;
      case 'AiOutlinePhone': return Icons.phone_rounded;
      case 'MdAssignmentTurnedIn': return Icons.assignment_turned_in_rounded;
      case 'FaNetworkWired': return Icons.lan_rounded;
      default: return Icons.folder_rounded;
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

  Uint8List? _decodeBase64(String? base64Str) {
    if (base64Str == null || base64Str.isEmpty) return null;
    try {
      String cleanStr = base64Str;
      if (cleanStr.contains(',')) {
        cleanStr = cleanStr.split(',')[1];
      }
      return base64Decode(cleanStr.trim());
    } catch (e) {
      return null;
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final decodedBytes = _decodeBase64(userAvatar);

    return Drawer(
      child: Column(
        children: [
          // Header M3 con perfil
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              context.go('/profile');
            },
            child: UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF031604), const Color(0xFF09290B)]
                      : [AppTheme.primaryDarkColor, AppTheme.primaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              currentAccountPicture: Container(
                padding: const EdgeInsets.all(3.0),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: CircleAvatar(
                  backgroundColor: primaryColor,
                  backgroundImage: decodedBytes != null
                      ? MemoryImage(decodedBytes)
                      : null,
                  child: decodedBytes == null
                      ? Text(
                          _getInitials(userName),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22.0,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
              ),
              accountName: Text(
                userName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                  color: Colors.white,
                ),
              ),
              accountEmail: Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  userRole.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              children: [
                ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  leading: const Icon(Icons.home_rounded),
                  title: const Text('Inicio', style: TextStyle(fontWeight: FontWeight.w600)),
                  selected: location == '/home',
                  selectedTileColor: primaryColor.withValues(alpha: 0.15),
                  selectedColor: primaryColor,
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/home');
                  },
                ),
                const SizedBox(height: 4),
                ...groupedModules.map((modulo) {
                  final bool isModuloSelected = (location == '/pedidos' && modulo.id == 2) ||
                      (location == '/ventas' && modulo.id == 3) ||
                      (location == '/compras' && modulo.id == 9) ||
                      (location == '/produccion' && modulo.id == 13);

                  if (modulo.opciones.isEmpty) {
                    return ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      leading: Icon(_getIconData(modulo.icono)),
                      title: Text(modulo.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                      selected: isModuloSelected,
                      selectedTileColor: primaryColor.withValues(alpha: 0.15),
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

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: ExpansionTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      leading: Icon(
                        _getIconData(modulo.icono),
                        color: isModuloSelected ? primaryColor : null,
                      ),
                      title: Text(
                        modulo.nombre,
                        style: TextStyle(
                          color: isModuloSelected ? primaryColor : null,
                          fontWeight: isModuloSelected ? FontWeight.bold : FontWeight.w600,
                        ),
                      ),
                      children: modulo.opciones.map((opcion) {
                        final bool isOptionSelected =
                            (location == '/pedidos' && (opcion.nombre == 'Crear Pedido' || opcion.nombre == 'Historial Pedido')) ||
                            (location == '/ventas' && (opcion.nombre == 'Pedidos Entrantes' || opcion.nombre == 'Exportar Pedido')) ||
                            (location == '/produccion' && (opcion.nombre == 'Asignación de Áreas' || opcion.nombre == 'Pendiente')) ||
                            (location == '/compras' && (opcion.nombre == 'Comprador' || opcion.nombre == 'Jefe de compras' || opcion.nombre == 'Control de Calidad'));

                        return Container(
                          margin: const EdgeInsets.only(left: 12.0, bottom: 2.0),
                          child: ListTile(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            contentPadding: const EdgeInsets.only(left: 20.0, right: 16.0),
                            leading: Icon(
                              _getIconData(opcion.icono),
                              size: 20.0,
                              color: isOptionSelected ? primaryColor : null,
                            ),
                            title: Text(
                              opcion.nombre,
                              style: TextStyle(
                                fontSize: 13.5,
                                color: isOptionSelected ? primaryColor : null,
                                fontWeight: isOptionSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                            selected: isOptionSelected,
                            selectedTileColor: primaryColor.withValues(alpha: 0.12),
                            onTap: () {
                              Navigator.pop(context);
                              _navigateToOption(context, opcion.ruta, opcion.nombre);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  );
                }),
              ],
            ),
          ),
          
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              leading: const Icon(Icons.logout_rounded, color: AppTheme.errorColor),
              title: const Text(
                'Cerrar Sesión',
                style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(context);
                onLogout();
              },
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../theme/theme_cubit.dart';

class ModuloModel {
  final int id;
  final String nombre;
  final String icono;
  final List<OpcionModel> opciones;

  ModuloModel({
    required this.id,
    required this.nombre,
    required this.icono,
    required this.opciones,
  });
}

class OpcionModel {
  final int id;
  final String nombre;
  final String ruta;
  final String icono;

  OpcionModel({
    required this.id,
    required this.nombre,
    required this.ruta,
    required this.icono,
  });
}

class MainLayout extends StatefulWidget {
  final String title;
  final Widget body;
  final Widget? floatingActionButton;
  final List<Widget>? actions;

  const MainLayout({
    super.key,
    required this.title,
    required this.body,
    this.floatingActionButton,
    this.actions,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final _storage = const FlutterSecureStorage();
  String _userName = 'Cargando...';
  String _userRole = '';
  List<ModuloModel> _groupedModules = [];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final name = await _storage.read(key: 'user_name') ?? 'Usuario';
    final roleId = await _storage.read(key: 'user_role_id') ?? '';
    final permissionsJson = await _storage.read(key: 'user_permissions') ?? '[]';

    String role = 'Usuario';
    if (roleId == '1') {
      role = 'Administrador';
    } else if (roleId == '2') {
      role = 'Supervisor';
    } else if (roleId == '3') {
      role = 'Digitador';
    }

    final List<ModuloModel> modules = [];
    try {
      final List<dynamic> list = jsonDecode(permissionsJson) as List<dynamic>;
      final Map<int, ModuloModel> modulosMap = {};

      for (var entry in list) {
        final m = entry['modulo'];
        final op = entry['opcion'];
        if (m == null || m['id'] == null) continue;

        final moduloId = int.tryParse(m['id'].toString()) ?? 0;
        if (!modulosMap.containsKey(moduloId)) {
          modulosMap[moduloId] = ModuloModel(
            id: moduloId,
            nombre: m['nombre']?.toString() ?? '',
            icono: m['icono']?.toString() ?? '',
            opciones: [],
          );
        }

        if (op != null && op['id'] != null) {
          final opcionId = int.tryParse(op['id'].toString()) ?? 0;
          final yaExiste = modulosMap[moduloId]!.opciones.any((o) => o.id == opcionId);
          if (!yaExiste) {
            modulosMap[moduloId]!.opciones.add(OpcionModel(
              id: opcionId,
              nombre: op['nombre']?.toString() ?? '',
              ruta: op['ruta']?.toString() ?? '',
              icono: op['icono']?.toString() ?? '',
            ));
          }
        }
      }
      modules.addAll(modulosMap.values);
    } catch (e) {
      //
    }

    // Fallback completo para el Administrador (roleId == '1') si la respuesta de la API está vacía
    if (roleId == '1' && modules.isEmpty) {
      modules.addAll([
        ModuloModel(
          id: 1,
          nombre: "Administración",
          icono: "MdPerson",
          opciones: [
            OpcionModel(id: 1, nombre: "Pais", ruta: "/pais/listar", icono: "MdApproval"),
            OpcionModel(id: 2, nombre: "Departamento", ruta: "/ciudad/listar", icono: "BsFillHouseDoorFill"),
            OpcionModel(id: 3, nombre: "Rutas", ruta: "/ruta/listar", icono: "FaShippingFast"),
            OpcionModel(id: 4, nombre: "Tienda", ruta: "/tienda/listar", icono: "MdShoppingCart"),
            OpcionModel(id: 5, nombre: "Empresa", ruta: "/empresa/listar", icono: "BsGraphUp"),
            OpcionModel(id: 8, nombre: "Deus", ruta: "/deus/listar", icono: "BsPersonCheckFill"),
            OpcionModel(id: 10, nombre: "Productos", ruta: "/items/listar", icono: "FiArchive"),
            OpcionModel(id: 16, nombre: "Usuarios", ruta: "/admin/usuarios", icono: "FaUsers"),
          ],
        ),
        ModuloModel(
          id: 2,
          nombre: "Pedido",
          icono: "FaTools",
          opciones: [
            OpcionModel(id: 6, nombre: "Crear Pedido", ruta: "/pedido/listar", icono: "FaClipboardList"),
            OpcionModel(id: 11, nombre: "Historial Pedido", ruta: "/historialPedido/listar", icono: "MdEvent"),
          ],
        ),
        ModuloModel(
          id: 3,
          nombre: "Ventas",
          icono: "FiShoppingCart",
          opciones: [
            OpcionModel(id: 7, nombre: "Pedidos Entrantes", ruta: "/pedidos/entrantes", icono: "FaCheckCircle"),
            OpcionModel(id: 11, nombre: "Historial Pedido", ruta: "/historialPedido/listar", icono: "MdEvent"),
            OpcionModel(id: 12, nombre: "Exportar Pedido", ruta: "/exportarPedido/listar", icono: "FaBook"),
          ],
        ),
        ModuloModel(
          id: 9,
          nombre: "Compras",
          icono: "FaCashRegister",
          opciones: [
            OpcionModel(id: 13, nombre: "Comprador", ruta: "/comprasPedidos/listar", icono: "MdAssignmentTurnedIn"),
            OpcionModel(id: 14, nombre: "Jefe de compras", ruta: "/comprador/listar", icono: "AiOutlinePhone"),
            OpcionModel(id: 15, nombre: "Control de Calidad", ruta: "/ControlCalidad/listar", icono: "FiClipboard"),
          ],
        ),
        ModuloModel(
          id: 12,
          nombre: "Gestión área",
          icono: "FiClipboard",
          opciones: [
            OpcionModel(id: 18, nombre: "Asignación de Áreas", ruta: "/asignacion-areas", icono: "FaNetworkWired"),
          ],
        ),
        ModuloModel(
          id: 13,
          nombre: "Orden de Producción",
          icono: "AiFillDashboard",
          opciones: [
            OpcionModel(id: 23, nombre: "Pendiente", ruta: "/produccion/orden", icono: "FiArchive"),
          ],
        ),
      ]);
    }

    setState(() {
      _userName = name;
      _userRole = role;
      _groupedModules = modules;
    });
  }

  Future<void> _logout() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'user_id');
    await _storage.delete(key: 'user_name');
    await _storage.delete(key: 'user_role_id');
    await _storage.delete(key: 'user_routes');
    await _storage.delete(key: 'user_pais_id');
    await _storage.delete(key: 'user_permissions');
    if (mounted) {
      context.go('/login');
    }
  }

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

  void _navigateToOption(String routePath, String optionName) {
    if (optionName == 'Crear Pedido' || optionName == 'Historial Pedido') {
      context.go('/pedidos');
    } else if (optionName == 'Pedidos Entrantes' || optionName == 'Exportar Pedido') {
      context.go('/ventas');
    } else if (optionName == 'Asignación de Áreas' || optionName == 'Pendiente') {
      context.go('/produccion');
    } else if (optionName == 'Comprador' || optionName == 'Jefe de compras' || optionName == 'Control de Calidad') {
      context.go('/compras');
    } else {
      // Fallback por defecto según patrón de ruta
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
    final String location = GoRouterState.of(context).matchedLocation;
    final primaryColor = Theme.of(context).primaryColor;

    // Determinar visibilidad para BottomNavigationBar (Footer)
    final bool hasPedidosModule = _groupedModules.any((m) => m.id == 2);
    final bool hasVentasModule = _groupedModules.any((m) => m.id == 3);
    final bool hasProduccionModule = _groupedModules.any((m) => m.id == 13);

    // Configurar lista dinámica del BottomNavigationBar
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

    // Configurar acciones del AppBar con el botón de tema
    final List<Widget> actionsList = [];
    if (widget.actions != null) {
      actionsList.addAll(widget.actions!);
    }

    final themeMode = context.watch<ThemeCubit>().state;
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);

    actionsList.add(
      IconButton(
        icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
        tooltip: isDark ? 'Modo Claro' : 'Modo Oscuro',
        onPressed: () {
          context.read<ThemeCubit>().toggleTheme(context);
        },
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: actionsList,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            // Drawer Header con Logo de La Carreta
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
                    _userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                  Text(
                    _userRole.toUpperCase(),
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
                  ..._groupedModules.map((modulo) {
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
                            _navigateToOption(opcion.ruta, opcion.nombre);
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
                _logout();
              },
            ),
            const SizedBox(height: 12.0),
          ],
        ),
      ),
      body: widget.body,
      floatingActionButton: widget.floatingActionButton,
      bottomNavigationBar: barItems.length < 2
          ? null
          : BottomNavigationBar(
              currentIndex: getSelectedIndex(),
              onTap: onItemTapped,
              selectedItemColor: primaryColor,
              unselectedItemColor: Colors.grey,
              type: BottomNavigationBarType.fixed,
              items: barItems,
            ),
    );
  }
}

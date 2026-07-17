import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../theme/theme_cubit.dart';
import 'models/modulo_model.dart';
import 'models/opcion_model.dart';
import 'widgets/main_drawer.dart';
import 'widgets/main_bottom_nav.dart';

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

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    final primaryColor = Theme.of(context).primaryColor;

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
      drawer: MainDrawer(
        userName: _userName,
        userRole: _userRole,
        groupedModules: _groupedModules,
        location: location,
        primaryColor: primaryColor,
        onLogout: _logout,
      ),
      body: widget.body,
      floatingActionButton: widget.floatingActionButton,
      bottomNavigationBar: _groupedModules.any((m) => m.id == 2 || m.id == 3 || m.id == 13)
          ? MainBottomNav(
              groupedModules: _groupedModules,
              location: location,
              primaryColor: primaryColor,
            )
          : null,
    );
  }
}

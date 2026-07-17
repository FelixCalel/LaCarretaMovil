import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'notifications_cubit.dart';
import 'widgets/notifications_bottom_sheet.dart';
import '../services/secure_storage_service.dart';
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
  final _storage = SecureStorageService();
  String _userName = 'Cargando...';
  String _userRole = '';
  List<ModuloModel> _groupedModules = [];

  // Variables de conectividad
  bool _isConnected = true;
  bool _showConnectionBanner = false;
  late final StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _initConnectivityListener();
    _checkForShorebirdUpdates();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final cubit = context.read<NotificationsCubit>();
        cubit.listenToWebSocket();
        cubit.loadNotifications();
      }
    });
  }

  void _initConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final hasConnection = !results.contains(ConnectivityResult.none);
      if (hasConnection != _isConnected) {
        setState(() {
          _isConnected = hasConnection;
          _showConnectionBanner = true;
        });

        // Ocultar banner de "Conectado" después de 3 segundos
        if (hasConnection) {
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted && _isConnected) {
              setState(() {
                _showConnectionBanner = false;
              });
            }
          });
        }
      }
    });
  }

  Future<void> _checkForShorebirdUpdates() async {
    try {
      final updater = ShorebirdUpdater();
      final status = await updater.checkForUpdate();
      if (status == UpdateStatus.outdated) {
        await updater.update();
        if (mounted) {
          final primaryColor = Theme.of(context).primaryColor;
          _showUpdatePromptDialog(primaryColor);
        }
      }
    } catch (e) {
      // Ignorar de forma silenciosa
    }
  }

  void _showUpdatePromptDialog(Color primaryColor) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Actualización disponible'),
        content: const Text('Se ha descargado una actualización del sistema. ¿Deseas reiniciar la aplicación ahora para aplicar los cambios?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Más tarde', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              SystemNavigator.pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: const Text('Reiniciar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _loadUserInfo() async {
    final name = await _storage.getUserName() ?? 'Usuario';
    final roleId = await _storage.getUserRoleId() ?? '';
    final permissionsJson = await _storage.getUserPermissions() ?? '[]';

    String role = 'Usuario';
    if (roleId == '1') {
      role = 'Administrador';
    } else if (roleId == '2') {
      role = 'Display';
    } else if (roleId == '3') {
      role = 'Ventas';
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
    await _storage.clearAuthData();
    if (mounted) {
      context.read<NotificationsCubit>().reset();
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
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
      BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, state) {
          return Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                tooltip: 'Notificaciones',
                onPressed: () {
                  _showNotificationsBottomSheet(context);
                },
              ),
              if (state.unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${state.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ).animate().scale(delay: 200.ms, duration: 300.ms),
                ),
            ],
          );
        },
      ),
    );

    actionsList.add(
      IconButton(
        icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
        tooltip: isDark ? 'Modo Claro' : 'Modo Oscuro',
        onPressed: () {
          context.read<ThemeCubit>().toggleTheme(context);
        },
      ),
    );

    return BlocListener<NotificationsCubit, NotificationsState>(
      listenWhen: (previous, current) =>
          current.lastNewNotification != null &&
          current.lastNewNotification != previous.lastNewNotification,
      listener: (context, state) {
        final notif = state.lastNewNotification!;
        context.read<NotificationsCubit>().clearLastNewNotification();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: notif.tipo == 'success'
                ? Colors.green.shade800
                : notif.tipo == 'error'
                    ? Colors.red.shade800
                    : notif.tipo == 'warning'
                        ? Colors.orange.shade800
                        : Theme.of(context).primaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(12),
            content: Row(
              children: [
                Icon(
                  notif.tipo == 'success'
                      ? Icons.check_circle
                      : notif.tipo == 'error'
                          ? Icons.error
                          : notif.tipo == 'warning'
                              ? Icons.warning
                              : Icons.info,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notif.titulo,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        notif.mensaje,
                        style: const TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            action: SnackBarAction(
              label: 'Ver',
              textColor: Colors.white,
              onPressed: () {
                if (notif.pedidoId != null) {
                  context.go('/historialPedido/listar');
                }
              },
            ),
          ),
        );
      },
      child: Scaffold(
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
        body: Column(
          children: [
            if (_showConnectionBanner)
              Container(
                width: double.infinity,
                color: _isConnected ? Colors.green : Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isConnected ? Icons.wifi : Icons.wifi_off,
                        color: Colors.white,
                        size: 16.0,
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        _isConnected ? 'Conexión restablecida' : 'Sin conexión a Internet',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fade().slideY(begin: -0.5, end: 0, duration: 300.ms),
            Expanded(child: widget.body),
          ],
        ),
        floatingActionButton: widget.floatingActionButton,
        bottomNavigationBar: _groupedModules.any((m) => m.id == 2 || m.id == 3 || m.id == 13)
            ? MainBottomNav(
                groupedModules: _groupedModules,
                location: location,
                primaryColor: primaryColor,
              )
            : null,
      ),
    );
  }

  void _showNotificationsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return NotificationsBottomSheet(scrollController: scrollController);
          },
        );
      },
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/presentation/main_layout.dart';
import '../../../core/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storage = const FlutterSecureStorage();
  String _userName = 'Cargando...';
  String _userRole = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final name = await _storage.read(key: 'user_name') ?? 'Usuario';
    final roleId = await _storage.read(key: 'user_role_id') ?? '';
    String roleName = 'Usuario';
    if (roleId == '1') {
      roleName = 'Administrador';
    } else if (roleId == '2') {
      roleName = 'Display';
    } else if (roleId == '3') {
      roleName = 'Ventas';
    }

    setState(() {
      _userName = name;
      _userRole = roleName;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Inicio',
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila con Bienvenido + Nombre y Badge de Rol
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12.0,
                runSpacing: 8.0,
                children: [
                  Text(
                    'Bienvenido $_userName',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 26.0,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: AppTheme.primaryColor,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      _userRole.toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11.0,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              
              // Mensaje de bienvenida minimalista exactamente como en la web
              Text(
                '¡Nos alegra tenerte de vuelta! Explora el menú lateral para acceder a las secciones disponibles.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

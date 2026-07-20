import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/presentation/main_layout.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/secure_storage_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storage = SecureStorageService();
  String _userName = 'Cargando...';
  String _userRole = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final name = await _storage.getUserName() ?? 'Usuario';
    final roleId = await _storage.getUserRoleId() ?? '';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

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
                    style: TextStyle(
                      fontSize: 26.0,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                    ),
                  ).animate().fade(duration: 450.ms).slideX(begin: -0.05, end: 0),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: primaryColor,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      _userRole.toUpperCase(),
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11.0,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ).animate().fade(delay: 150.ms).scale(),
                ],
              ),
              const SizedBox(height: 16.0),

              // Mensaje de bienvenida minimalista
              Text(
                '¡Nos alegra tenerte de vuelta! Explora el menú lateral para acceder a las secciones disponibles.',
                style: TextStyle(
                  fontSize: 15.0,
                  color: isDark ? AppTheme.darkTextSecondary : Colors.grey[600],
                  height: 1.4,
                ),
              ).animate().fade(delay: 250.ms).slideY(begin: 0.1, end: 0),
            ],
          ),
        ),
      ),
    );
  }
}

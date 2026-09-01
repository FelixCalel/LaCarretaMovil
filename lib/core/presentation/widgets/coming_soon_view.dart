import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';

class ComingSoonView extends StatelessWidget {
  final String moduleName;
  final IconData icon;
  final Color accentColor;
  final String? customMessage;

  const ComingSoonView({
    super.key,
    required this.moduleName,
    required this.icon,
    this.accentColor = AppTheme.primaryColor,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor.withValues(alpha: 0.12),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.25),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.15),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(icon, size: 52, color: accentColor),
                  ),
                )
                .animate(
                  onPlay: (controller) => controller.repeat(reverse: true),
                )
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.05, 1.05),
                  duration: 2000.ms,
                  curve: Curves.easeInOut,
                ),

            const SizedBox(height: 28),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.amber.withValues(alpha: 0.15)
                    : Colors.amber.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.amber.shade700.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.construction_rounded,
                    size: 16,
                    color: Colors.amber.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'EN DESARROLLO',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: Colors.amber.shade800,
                    ),
                  ),
                ],
              ),
            ).animate().fade(delay: 200.ms).slideY(begin: 0.2, end: 0),

            const SizedBox(height: 20),

            // Título
            Text(
              'Módulo de $moduleName',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
                color: isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary,
              ),
            ).animate().fade(delay: 300.ms).slideY(begin: 0.2, end: 0),

            const SizedBox(height: 12),

            // Mensaje explicativo
            Text(
              customMessage ??
                  'Estamos trabajando en la optimización de las funciones de $moduleName para la versión móvil.\n\nPróximamente estará disponible.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.5,
                height: 1.5,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ).animate().fade(delay: 400.ms).slideY(begin: 0.2, end: 0),

            const SizedBox(height: 36),

            // Botón volver al inicio
            FilledButton.icon(
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Volver al Inicio'),
              style: FilledButton.styleFrom(
                backgroundColor: isDark
                    ? AppTheme.primaryColor
                    : AppTheme.primaryDarkColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ).animate().fade(delay: 500.ms).scale(),
          ],
        ),
      ),
    );
  }
}

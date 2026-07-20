import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/presentation/main_layout.dart';
import '../../../core/theme/app_theme.dart';

class VentasScreen extends StatelessWidget {
  const VentasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MainLayout(
      title: 'Módulo de Ventas',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.trending_up_rounded, color: Color(0xFF8B5CF6), size: 28),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumen de Ventas',
                      style: TextStyle(
                        fontSize: 22.0,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                      ),
                    ),
                    Text(
                      'Facturación y rendimiento en tiempo real',
                      style: TextStyle(
                        fontSize: 13.0,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ).animate().fade(duration: 400.ms).slideY(begin: 0.1, end: 0),
            
            const SizedBox(height: 24.0),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 14.0,
              mainAxisSpacing: 14.0,
              childAspectRatio: 1.15,
              children: [
                _buildSummaryCard(
                  context,
                  'Total Facturado',
                  'Q 12,450.00',
                  Icons.monetization_on_rounded,
                  AppTheme.successColor,
                ).animate().fade(delay: 100.ms).scale(),
                _buildSummaryCard(
                  context,
                  'Ventas Hoy',
                  '45 Trans.',
                  Icons.shopping_bag_rounded,
                  AppTheme.accentColor,
                ).animate().fade(delay: 200.ms).scale(),
                _buildSummaryCard(
                  context,
                  'Metas Diarias',
                  '82%',
                  Icons.leaderboard_rounded,
                  AppTheme.warningColor,
                ).animate().fade(delay: 300.ms).scale(),
                _buildSummaryCard(
                  context,
                  'Comisiones',
                  'Q 622.50',
                  Icons.percent_rounded,
                  const Color(0xFF8B5CF6),
                ).animate().fade(delay: 400.ms).scale(),
              ],
            ),
            
            const SizedBox(height: 28.0),
            Text(
              'Últimas Facturas Registradas',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 14.0),
            _buildInvoiceItem(context, 'FAC-0098', 'Cliente: UNISUPER S.A.', 'Q 1,200.00', 'Pagado').animate().fade(delay: 450.ms).slideX(begin: 0.05, end: 0),
            _buildInvoiceItem(context, 'FAC-0097', 'Cliente: Walmart Guatemala', 'Q 4,800.00', 'Pagado').animate().fade(delay: 500.ms).slideX(begin: 0.05, end: 0),
            _buildInvoiceItem(context, 'FAC-0096', 'Cliente: Super del Barrio', 'Q 950.00', 'Pendiente').animate().fade(delay: 550.ms).slideX(begin: 0.05, end: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, String title, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardColor : Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 10.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const Spacer(),
          Text(
            title,
            style: TextStyle(
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              fontSize: 12.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            value,
            style: TextStyle(
              fontSize: 17.0,
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceItem(BuildContext context, String id, String client, String total, String status) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = status == 'Pagado' ? AppTheme.successColor : AppTheme.warningColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 10.0),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardColor : Colors.white,
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.receipt_long_rounded, color: Theme.of(context).primaryColor),
        ),
        title: Text(id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(client, style: TextStyle(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary, fontSize: 13)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(total, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4.0),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                status,
                style: TextStyle(color: statusColor, fontSize: 10.5, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

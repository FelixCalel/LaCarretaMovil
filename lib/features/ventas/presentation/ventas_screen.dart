import 'package:flutter/material.dart';
import '../../../core/presentation/main_layout.dart';

class VentasScreen extends StatelessWidget {
  const VentasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Ventas La Carreta',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Módulo de Ventas',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF203A43),
              ),
            ),
            const SizedBox(height: 8.0),
            const Text(
              'Resumen general de facturación y facturas del día.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20.0),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12.0,
              mainAxisSpacing: 12.0,
              children: [
                _buildSummaryCard(
                  'Total Facturado',
                  'Q 12,450.00',
                  Icons.monetization_on,
                  Colors.green,
                ),
                _buildSummaryCard(
                  'Ventas Hoy',
                  '45 Trans.',
                  Icons.shopping_bag,
                  Colors.blue,
                ),
                _buildSummaryCard(
                  'Metas Diarias',
                  '82%',
                  Icons.trending_up,
                  Colors.orange,
                ),
                _buildSummaryCard(
                  'Comisiones',
                  'Q 622.50',
                  Icons.percent,
                  Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 24.0),
            const Text(
              'Últimas Facturas',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF203A43),
              ),
            ),
            const SizedBox(height: 12.0),
            _buildInvoiceItem('FAC-0098', 'Cliente: UNISUPER S.A.', 'Q 1,200.00', 'Pagado'),
            _buildInvoiceItem('FAC-0097', 'Cliente: Walmart Guatemala', 'Q 4,800.00', 'Pagado'),
            _buildInvoiceItem('FAC-0096', 'Cliente: Super del Barrio', 'Q 950.00', 'Pendiente'),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color),
            ),
            const Spacer(),
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13.0)),
            const SizedBox(height: 4.0),
            Text(
              value,
              style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Color(0xFF203A43)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceItem(String id, String client, String total, String status) {
    final statusColor = status == 'Pagado' ? Colors.green : Colors.amber;
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: const Icon(Icons.receipt_long, color: Color(0xFF203A43)),
        title: Text(id, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(client),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(total, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4.0),
            Text(
              status,
              style: TextStyle(color: statusColor, fontSize: 11.0, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

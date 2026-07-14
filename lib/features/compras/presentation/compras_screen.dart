import 'package:flutter/material.dart';
import '../../../core/presentation/main_layout.dart';

class ComprasScreen extends StatelessWidget {
  const ComprasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Compras La Carreta',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Módulo de Compras',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF203A43),
              ),
            ),
            const SizedBox(height: 8.0),
            const Text(
              'Gestión de proveedores, órdenes de compra y materia prima.',
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
                  'Órdenes Pendientes',
                  '5 Órdenes',
                  Icons.hourglass_empty,
                  Colors.amber,
                ),
                _buildSummaryCard(
                  'Proveedores',
                  '14 Activos',
                  Icons.local_shipping,
                  Colors.blue,
                ),
                _buildSummaryCard(
                  'Gastos Mes',
                  'Q 34,500.00',
                  Icons.account_balance_wallet,
                  Colors.redAccent,
                ),
                _buildSummaryCard(
                  'Entregas Hoy',
                  '3 Recibidas',
                  Icons.check_circle,
                  Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 24.0),
            const Text(
              'Órdenes de Compra Recientes',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF203A43),
              ),
            ),
            const SizedBox(height: 12.0),
            _buildPurchaseOrderItem('OC-304', 'Proveedor: Harinas de Centroamérica', 'Q 15,000.00', 'Entregado', Colors.green),
            _buildPurchaseOrderItem('OC-303', 'Proveedor: Azucarera El Pilar', 'Q 8,400.00', 'En Tránsito', Colors.blue),
            _buildPurchaseOrderItem('OC-302', 'Proveedor: Empaques de Guatemala', 'Q 3,200.00', 'Pendiente', Colors.amber),
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

  Widget _buildPurchaseOrderItem(String id, String supplier, String total, String status, Color statusColor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: const Icon(Icons.shopping_cart, color: Color(0xFF203A43)),
        title: Text(id, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(supplier),
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

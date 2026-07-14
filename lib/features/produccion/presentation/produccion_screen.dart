import 'package:flutter/material.dart';
import '../../../core/presentation/main_layout.dart';

class ProduccionScreen extends StatelessWidget {
  const ProduccionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Producción La Carreta',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Control de Producción',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF203A43),
              ),
            ),
            const SizedBox(height: 8.0),
            const Text(
              'Pedidos de producción y estado de la fabricación de recetas.',
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
                  'Ordenes Activas',
                  '12 Órdenes',
                  Icons.pending_actions,
                  Colors.orange,
                ),
                _buildSummaryCard(
                  'Recetas en Uso',
                  '8 Fórmulas',
                  Icons.restaurant_menu,
                  Colors.deepOrange,
                ),
                _buildSummaryCard(
                  'Procesados Hoy',
                  '1,850 kg',
                  Icons.scale,
                  Colors.blue,
                ),
                _buildSummaryCard(
                  'Eficiencia Lote',
                  '97.8%',
                  Icons.done_all,
                  Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 24.0),
            const Text(
              'Lotes en Proceso',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF203A43),
              ),
            ),
            const SizedBox(height: 12.0),
            _buildBatchItem('LOTE-9982', 'Receta: Pan de Rodaja Grande', 'Progreso: 65%', Colors.orange),
            _buildBatchItem('LOTE-9981', 'Receta: Baguette Francés', 'Progreso: 90%', Colors.orange),
            _buildBatchItem('LOTE-9980', 'Receta: Conchas de Chocolate', 'Finalizado', Colors.green),
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

  Widget _buildBatchItem(String id, String recipe, String progress, Color statusColor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: const Icon(Icons.precision_manufacturing, color: Color(0xFF203A43)),
        title: Text(id, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(recipe),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Text(
            progress,
            style: TextStyle(color: statusColor, fontSize: 11.0, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

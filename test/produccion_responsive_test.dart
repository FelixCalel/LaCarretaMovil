import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacarretamovil/features/produccion/domain/produccion_model.dart';
import 'package:lacarretamovil/features/produccion/presentation/widgets/registrar_rechazo_modal.dart';
import 'package:lacarretamovil/features/produccion/presentation/widgets/fabricacion_sap_modal.dart';
import 'package:lacarretamovil/features/produccion/presentation/widgets/asignar_proveedor_modal.dart';
import 'package:lacarretamovil/features/produccion/presentation/widgets/supervisor_order_detail_modal.dart';
import 'package:lacarretamovil/features/produccion/presentation/widgets/digitador_order_detail_modal.dart';
import 'package:lacarretamovil/features/pedidos/presentation/widgets/crear_pedido_modal.dart';

void main() {
  group('Producción Responsive & Rotation Tests', () {
    testWidgets('RegistrarRechazoModal renders cleanly in landscape without overflow',
        (WidgetTester tester) async {
      // Configurar pantalla en Landscape de teléfono pequeño (800x360)
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RegistrarRechazoModal(
              title: 'Rechazo Producto',
              subtitle: 'Merma de empaque',
              maxQuantity: 10.0,
              unit: 'KG',
              onConfirm: (qty, comment) async {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Rechazo Producto'), findsOneWidget);
      expect(find.text('Registrar Rechazo'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('FabricacionSapModal renders cleanly in landscape without overflow',
        (WidgetTester tester) async {
      // Landscape 800x360
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FabricacionSapModal(
              count: 5,
              onConfirm: (fecha, comment) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Cargar a SAP (5 productos)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('AsignarProveedorModal renders cleanly in tablet landscape (1280x800)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final linea = RecetaLineaModel(
        id: 1,
        pedidoProduccionId: 10,
        item: 'Caja Cartón 10kg',
        idAlmacen: 1,
        cantidadBase: 50.0,
        cantidadRequerida: 50.0,
        nombreUnidad: 'cajas',
        state: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AsignarProveedorModal(
              recetaLinea: linea,
              pedidoId: 10,
              onSave: (proveedores) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Asignar Proveedores y Lotes'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('SupervisorOrderDetailModal and DigitadorOrderDetailModal adapt to tablet width',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final order = PedidoAgrupadoModel(
        pedidoId: 300,
        tienda: 'Auto Mercado San José',
        pais: 'Costa Rica',
        deudorCodigo: 'DEU-007',
        deudorNombre: 'Auto Mercado',
        items: [
          PedidoProduccionModel(
            id: 1,
            productoId: 1,
            idAsigArea: 1,
            cantidadUnidad: 20.0,
            completo: true,
            cantidad: 20.0,
            state: true,
            productoNombre: 'Camarón Jumbo',
            tienda: 'Auto Mercado San José',
            pais: 'Costa Rica',
            deudorCodigo: 'DEU-007',
            deudorNombre: 'Auto Mercado',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SupervisorOrderDetailModal(
              order: order,
              onAcceptOrder: (comment) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Pedido #300'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DigitadorOrderDetailModal(
              order: order,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Pedido #300'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('CrearPedidoModal renders cleanly in landscape without overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CrearPedidoModal(
              ciudades: const [],
              deudores: const [],
              tiendas: const [],
              userRoutes: const [],
              userPaisId: 1,
              onSave: (_, a, b) {},
              onCopyLastPedido: (_, a, b) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Agregar Nuevo Pedido'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

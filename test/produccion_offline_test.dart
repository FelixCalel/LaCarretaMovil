import 'package:flutter_test/flutter_test.dart';
import 'package:lacarretamovil/features/produccion/domain/produccion_model.dart';

void main() {
  group('Producción Offline Models Serialization Tests', () {
    test('PedidoProduccionModel and PedidoAgrupadoModel serialize and deserialize accurately', () {
      final item = PedidoProduccionModel(
        id: 101,
        productoId: 50,
        idAsigArea: 2,
        cantidadUnidad: 12.5,
        completo: false,
        cantidad: 5.0,
        state: true,
        productoNombre: 'Pescado Empanizado',
        tienda: 'Tienda Central',
        pais: 'Costa Rica',
        deudorCodigo: 'DEU001',
        deudorNombre: 'Walmart',
        trazabilidadProd: 'PRO-1234',
        trazabilidadDig: 'DIG-5678',
      );

      final group = PedidoAgrupadoModel(
        pedidoId: 2001,
        tienda: 'Tienda Central',
        pais: 'Costa Rica',
        deudorCodigo: 'DEU001',
        deudorNombre: 'Walmart',
        items: [item],
      );

      final groupJson = group.toJson();
      expect(groupJson['pedidoId'], 2001);
      expect(groupJson['items'], isNotEmpty);

      final reconstructed = PedidoAgrupadoModel.fromJson(groupJson);
      expect(reconstructed.pedidoId, 2001);
      expect(reconstructed.items.length, 1);
      expect(reconstructed.items.first.id, 101);
      expect(reconstructed.items.first.productoNombre, 'Pescado Empanizado');
      expect(reconstructed.items.first.trazabilidadProd, 'PRO-1234');
    });

    test('RecetaLineaModel serializes and deserializes accurately', () {
      final prov = ProveedorRecetaModel(
        id: 1,
        proveedorCode: 'PRV01',
        proveedorName: 'Proveedor Marítimo',
        cantidad: 100.0,
        trazabilidad: 'TRZ-99',
      );

      final linea = RecetaLineaModel(
        id: 10,
        item: 'Filete de Pescado',
        idAlmacen: 5,
        almacenNombre: 'Almacén Frío',
        cantidadBase: 2.0,
        cantidadRequerida: 20.0,
        nombreUnidad: 'Kg',
        state: true,
        pedidoProduccionId: 101,
        proveedores: [prov],
      );

      final json = linea.toJson();
      expect(json['id'], 10);
      expect(json['item'], 'Filete de Pescado');

      final reconstructed = RecetaLineaModel.fromJson(json);
      expect(reconstructed.id, 10);
      expect(reconstructed.item, 'Filete de Pescado');
      expect(reconstructed.proveedores.length, 1);
      expect(reconstructed.proveedores.first.proveedorCode, 'PRV01');
    });

    test('AlmacenModel and MesaActivaAsignadaModel serialize and deserialize accurately', () {
      final almacen = AlmacenModel(id: 3, nombre: 'Bodega Principal');
      final alJson = almacen.toJson();
      expect(alJson['id'], 3);
      expect(alJson['nombre'], 'Bodega Principal');
      expect(AlmacenModel.fromJson(alJson).nombre, 'Bodega Principal');

      final mesa = MesaActivaAsignadaModel(
        idAsignacionMesa: 7,
        areaId: 1,
        areaNombre: 'Empaque',
        mesaId: 2,
        mesaNombre: 'Mesa 2',
        encargadoNombre: 'Carlos',
      );
      final mesaJson = mesa.toJson();
      expect(mesaJson['idAsignacionMesa'], 7);
      expect(mesaJson['mesaNombre'], 'Mesa 2');
      expect(MesaActivaAsignadaModel.fromJson(mesaJson).mesaNombre, 'Mesa 2');
    });

    test('RecetaLineaModel copyWith updates proveedores and quantity offline', () {
      final linea = RecetaLineaModel(
        id: 20,
        item: 'Especias Mix',
        idAlmacen: 1,
        cantidadBase: 1.0,
        cantidadRequerida: 5.0,
        nombreUnidad: 'Kg',
        state: true,
        pedidoProduccionId: 300,
      );

      expect(linea.proveedores, isEmpty);

      final newProvs = [
        ProveedorRecetaModel(
          id: 1,
          proveedorName: 'Condimentos SA',
          cantidad: 3.5,
          trazabilidad: 'TRZ-COND-1',
        ),
        ProveedorRecetaModel(
          id: 2,
          proveedorName: 'Especias del Norte',
          cantidad: 1.5,
          trazabilidad: 'TRZ-ESP-2',
        ),
      ];

      final total = newProvs.fold<double>(0.0, (s, p) => s + p.cantidad);
      final updated = linea.copyWith(
        cantidadBase: total,
        proveedores: newProvs,
      );

      expect(updated.proveedores.length, 2);
      expect(updated.cantidadBase, 5.0);
      expect(updated.proveedores.first.proveedorName, 'Condimentos SA');
      expect(updated.proveedores.last.cantidad, 1.5);
    });
  });
}

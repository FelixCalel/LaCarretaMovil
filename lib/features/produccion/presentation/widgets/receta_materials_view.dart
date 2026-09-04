import 'package:flutter/material.dart';
import '../../domain/produccion_model.dart';

const Color _emeraldColor = Color(0xFF10B981);

class RecetaMaterialsView extends StatelessWidget {
  final List<RecetaLineaModel> lineas;
  final bool isLoading;
  final Function(int recetaId, bool newState) onToggleState;
  final Function(int recetaId, double newQty)? onUpdateBaseQty;
  final Function(RecetaLineaModel linea)? onOpenRechazo;
  final Function(RecetaLineaModel linea)? onOpenProveedores;

  const RecetaMaterialsView({
    super.key,
    required this.lineas,
    this.isLoading = false,
    required this.onToggleState,
    this.onUpdateBaseQty,
    this.onOpenRechazo,
    this.onOpenProveedores,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text(
              'Cargando materiales y receta...',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (lineas.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        child: const Text(
          'No hay materiales asignados a esta receta.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900.withValues(alpha: 0.5) : Colors.grey.shade50,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MATERIALES Y LOTES ASIGNADOS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _emeraldColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${lineas.length} materiales',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _emeraldColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: lineas.length,
            separatorBuilder: (context, index) => Divider(
              height: 12,
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            ),
            itemBuilder: (context, index) {
              final linea = lineas[index];
              return _buildMaterialRow(context, linea, isDark);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialRow(
    BuildContext context,
    RecetaLineaModel linea,
    bool isDark,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Checkbox activo
        Checkbox(
          value: linea.state,
          activeColor: _emeraldColor,
          visualDensity: VisualDensity.compact,
          onChanged: (val) {
            if (val != null) {
              onToggleState(linea.id, val);
            }
          },
        ),
        // Nombre del material y almacén
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                linea.item,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Wrap(
                spacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (linea.almacenNombre != null && linea.almacenNombre!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        linea.almacenNombre!,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.blueGrey.shade200 : Colors.blueGrey.shade700,
                        ),
                      ),
                    ),
                  Text(
                    '${linea.cantidadBase.toStringAsFixed(2)} ${linea.nombreUnidad}',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Botones de acción (Rechazo / Prov)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () {
                if (onOpenProveedores != null) onOpenProveedores!(linea);
              },
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: linea.proveedores.isNotEmpty
                      ? _emeraldColor.withValues(alpha: 0.15)
                      : Colors.transparent,
                  border: Border.all(
                    color: linea.proveedores.isNotEmpty
                        ? _emeraldColor
                        : (isDark ? Colors.grey.shade700 : Colors.grey.shade400),
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.people_alt_outlined,
                      size: 12,
                      color: linea.proveedores.isNotEmpty
                          ? _emeraldColor
                          : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      linea.proveedores.isNotEmpty
                          ? 'Prov. (${linea.proveedores.length})'
                          : 'Prov.',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: linea.proveedores.isNotEmpty
                            ? _emeraldColor
                            : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              onTap: () {
                if (onOpenRechazo != null) onOpenRechazo!(linea);
              },
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red.shade400),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Rechazo',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/produccion_pendiente_cubit.dart';
import '../cubit/produccion_pendiente_state.dart';
import '../../domain/produccion_model.dart';
import '../widgets/consolidado_product_card.dart';
import '../widgets/asignar_proveedor_modal.dart';
import '../widgets/registrar_rechazo_modal.dart';

const Color _emeraldColor = Color(0xFF10B981);

class PendienteView extends StatelessWidget {
  const PendienteView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProduccionPendienteCubit, ProduccionPendienteState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.read<ProduccionPendienteCubit>().clearMessages();
        }
        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: _emeraldColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.read<ProduccionPendienteCubit>().clearMessages();
        }
      },
      builder: (context, state) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        if (state.isLoading && state.allGroups.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: _emeraldColor),
                SizedBox(height: 12),
                Text(
                  'Cargando pedidos de producción...',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: _emeraldColor,
          onRefresh: () =>
              context.read<ProduccionPendienteCubit>().loadData(silent: false),
          child: Column(
            children: [
              // Barra superior: Toggle Consolidado/Por Pedido y Badge Sin Asignar
              _buildTopControls(context, state, isDark),

              // Barra de filtros colapsable
              _buildFiltersBar(context, state, isDark),

              // Contenido principal según modo
              Expanded(
                child: state.viewMode == 'consolidado'
                    ? _buildConsolidadoView(context, state, isDark)
                    : _buildPorPedidoView(context, state, isDark),
              ),

              // Botón inferior flotante "Pasar a Supervisor"
              if (state.viewMode == 'consolidado' &&
                  state.selectedKeys.isNotEmpty)
                _buildBottomActionBar(context, state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopControls(
    BuildContext context,
    ProduccionPendienteState state,
    bool isDark,
  ) {
    final cubit = context.read<ProduccionPendienteCubit>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Segmented Switch: Por Pedido / Consolidado
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(2),
            child: Row(
              children: [
                _buildSegmentButton(
                  title: 'Por Pedido',
                  isSelected: state.viewMode == 'porPedido',
                  onTap: () => cubit.setViewMode('porPedido'),
                  isDark: isDark,
                ),
                _buildSegmentButton(
                  title: 'Consolidado',
                  isSelected: state.viewMode == 'consolidado',
                  onTap: () => cubit.setViewMode('consolidado'),
                  isDark: isDark,
                ),
              ],
            ),
          ),

          // Botón Sin Asignar (Amarillo)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.shade600,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  state.unassignedCount > 0
                      ? '${state.unassignedCount} Sin Asignar'
                      : 'Sin Asignar',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.grey.shade900 : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  )
                ]
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: isSelected
                ? _emeraldColor
                : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
          ),
        ),
      ),
    );
  }

  Widget _buildFiltersBar(
    BuildContext context,
    ProduccionPendienteState state,
    bool isDark,
  ) {
    final cubit = context.read<ProduccionPendienteCubit>();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          // Filtro País
          _buildFilterChip(
            label: state.countryFilter ?? 'País',
            isActive: state.countryFilter != null,
            isDark: isDark,
            onTap: () => _showOptionsDialog(
              context: context,
              title: 'Seleccionar País',
              options: state.availableCountries,
              selected: state.countryFilter,
              onSelect: (val) => cubit.setCountryFilter(val),
            ),
          ),
          const SizedBox(width: 6),

          // Filtro Cliente
          _buildFilterChip(
            label: state.clientFilter ?? 'Cliente',
            isActive: state.clientFilter != null,
            isDark: isDark,
            onTap: () => _showOptionsDialog(
              context: context,
              title: 'Seleccionar Cliente',
              options: state.availableClients,
              selected: state.clientFilter,
              onSelect: (val) => cubit.setClientFilter(val),
            ),
          ),
          const SizedBox(width: 6),

          // Filtro DEU
          _buildFilterChip(
            label: state.deuFilter ?? 'DEU',
            isActive: state.deuFilter != null,
            isDark: isDark,
            onTap: () => _showOptionsDialog(
              context: context,
              title: 'Seleccionar DEU',
              options: state.availableDeudores,
              selected: state.deuFilter,
              onSelect: (val) => cubit.setDeuFilter(val),
            ),
          ),
          const SizedBox(width: 6),

          // Filtro Fecha (Hoy / Todas)
          _buildFilterChip(
            label: state.dateMode == 'today' ? 'Hoy' : 'Todas las fechas',
            isActive: state.dateMode == 'today',
            isDark: isDark,
            onTap: () {
              if (state.dateMode == 'today') {
                cubit.setDateMode('all');
              } else {
                cubit.setDateMode('today');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isActive,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: isActive
              ? _emeraldColor.withValues(alpha: 0.12)
              : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive
                ? _emeraldColor
                : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isActive
                    ? _emeraldColor
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: isActive ? _emeraldColor : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsDialog({
    required BuildContext context,
    required String title,
    required List<String> options,
    required String? selected,
    required Function(String?) onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.75,
              maxWidth: 550,
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Todos / Ninguno'),
                    trailing: selected == null
                        ? const Icon(Icons.check, color: _emeraldColor)
                        : null,
                    onTap: () {
                      onSelect(null);
                      Navigator.pop(ctx);
                    },
                  ),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final opt = options[index];
                        return ListTile(
                          title: Text(opt),
                          trailing: selected == opt
                              ? const Icon(Icons.check, color: _emeraldColor)
                              : null,
                          onTap: () {
                            onSelect(opt);
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildConsolidadoView(
    BuildContext context,
    ProduccionPendienteState state,
    bool isDark,
  ) {
    final consolidated = state.consolidatedItems;
    final cubit = context.read<ProduccionPendienteCubit>();

    if (consolidated.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            const Text(
              'Sin pedidos consolidados',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'No hay pedidos para los filtros seleccionados.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    // Agrupar items por código de deudor
    final groupedByDeu = <String, List<ConsolidatedProductModel>>{};
    for (final item in consolidated) {
      groupedByDeu.putIfAbsent(item.deudorCodigo, () => []).add(item);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: groupedByDeu.keys.length,
      itemBuilder: (context, index) {
        final deuCode = groupedByDeu.keys.elementAt(index);
        final items = groupedByDeu[deuCode]!;
        final firstItem = items.first;
        final isCollapsed = state.collapsedDeus.contains(deuCode);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado DEU (Azul claro similar a Web)
            InkWell(
              onTap: () => cubit.toggleDeuCollapse(deuCode),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0C4A6E).withValues(alpha: 0.5)
                      : const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF0284C7)
                        : const Color(0xFFBAE6FD),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCollapsed
                          ? Icons.chevron_right_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: isDark ? Colors.lightBlue.shade200 : Colors.blue.shade900,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '$deuCode - ${firstItem.deudorNombre.isNotEmpty ? firstItem.deudorNombre : firstItem.tienda}',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? Colors.lightBlue.shade100
                              : Colors.blue.shade900,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade700,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${items.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Tarjetas de productos bajo este DEU
            if (!isCollapsed)
              ...items.map((item) {
                final isSelected = state.selectedKeys.contains(item.key);
                final isExpanded = state.expandedRecetas.containsKey(item.key);
                final isLoadingReceta =
                    state.loadingRecetaKeys.contains(item.key);
                final recetaLineas = state.expandedRecetas[item.key];

                return ConsolidadoProductCard(
                  key: ValueKey(item.key),
                  item: item,
                  isSelected: isSelected,
                  isExpanded: isExpanded,
                  isLoadingReceta: isLoadingReceta,
                  recetaLineas: recetaLineas,
                  almacenes: state.almacenes,
                  onToggleSelection: (_) => cubit.toggleSelectItem(item.key),
                  onToggleExpand: () => cubit.toggleExpandReceta(item),
                  onUpdateProcesado: (newQty) =>
                      cubit.updateProcesado(item, newQty),
                  onUpdateTrazabDig: (newTraz) =>
                      cubit.updateTrazabilidadDig(item, newTraz),
                  onUpdateCompleto: (isComplete) =>
                      cubit.updateCompleto(item, isComplete),
                  onUpdateAlmacen: (almacenId) =>
                      cubit.updateAlmacen(item, almacenId),
                  onToggleMaterialState: (recetaId, newState) =>
                      cubit.toggleMaterialState(recetaId, newState, item.key),
                  onOpenProveedores: (linea) =>
                      _mostrarModalProveedores(context, cubit, item, linea),
                  onOpenRechazo: (linea) =>
                      _mostrarModalRechazo(context, cubit, item, linea),
                );
              }),
          ],
        );
      },
    );
  }

  Widget _buildPorPedidoView(
    BuildContext context,
    ProduccionPendienteState state,
    bool isDark,
  ) {
    final groups = state.filteredGroups;

    if (groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined,
                size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            const Text(
              'Sin pedidos pendientes',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        final totalItems = group.items.length;
        final completedItems = group.items.where((i) => i.completo).length;
        final progress = totalItems > 0 ? completedItems / totalItems : 0.0;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pedido #${group.pedidoId}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _emeraldColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        group.pais,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _emeraldColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${group.deudorCodigo} - ${group.tienda}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          color: _emeraldColor,
                          backgroundColor: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade200,
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$completedItems / $totalItems',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomActionBar(
    BuildContext context,
    ProduccionPendienteState state,
  ) {
    final cubit = context.read<ProduccionPendienteCubit>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: state.isSaving ? null : () => cubit.avanzarASupervisor(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _emeraldColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 2,
                ),
                child: state.isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Pasar a Supervisor (${state.selectedKeys.length})',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarModalProveedores(
    BuildContext context,
    ProduccionPendienteCubit cubit,
    ConsolidatedProductModel item,
    RecetaLineaModel linea,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AsignarProveedorModal(
        recetaLinea: linea,
        pedidoId: linea.pedidoProduccionId,
        cantidadProcesada: item.cantidadProcesada,
        onSave: (proveedores) async {
          await cubit.saveRecetaProveedores(
            recetaId: linea.id,
            pedidoId: linea.pedidoProduccionId,
            productKey: item.key,
            proveedores: proveedores,
            cantidadProcesada: item.cantidadProcesada,
          );
        },
      ),
    );
  }

  void _mostrarModalRechazo(
    BuildContext context,
    ProduccionPendienteCubit cubit,
    ConsolidatedProductModel item,
    RecetaLineaModel linea,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) => RegistrarRechazoModal(
        title: 'Registrar Rechazo',
        subtitle: '${linea.item} (${item.productoNombre})',
        maxQuantity: linea.cantidadBase,
        unit: linea.nombreUnidad,
        onConfirm: (cantidad, comentario) async {
          await cubit.registrarRechazo(
            usuarioId: 1,
            cantidad: cantidad,
            comentario: comentario,
            idPedidoReceta: linea.id,
            pedidoId: linea.pedidoProduccionId,
          );
        },
      ),
    );
  }
}

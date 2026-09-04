import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/produccion_digitador_cubit.dart';
import '../cubit/produccion_digitador_state.dart';
import '../../domain/produccion_model.dart';
import '../widgets/digitador_order_detail_modal.dart';

const Color _emeraldColor = Color(0xFF10B981);

class DigitadorView extends StatelessWidget {
  const DigitadorView({super.key});

  void _showOrderDetail(BuildContext context, PedidoAgrupadoModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DigitadorOrderDetailModal(order: order),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    switch (status) {
      case 'EXPORTADO':
        bg = Colors.purple.withValues(alpha: 0.12);
        fg = Colors.purple;
        break;
      case 'FABRICADO':
        bg = _emeraldColor.withValues(alpha: 0.12);
        fg = _emeraldColor;
        break;
      case 'EN PROCESO':
        bg = Colors.blue.withValues(alpha: 0.12);
        fg = Colors.blue;
        break;
      default:
        bg = Colors.amber.withValues(alpha: 0.12);
        fg = Colors.amber.shade800;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProduccionDigitadorCubit, ProduccionDigitadorState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.read<ProduccionDigitadorCubit>().clearMessages();
        }
      },
      builder: (context, state) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        if (state.isLoading && state.allGroups.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.blue),
                SizedBox(height: 12),
                Text(
                  'Cargando historial de digitador...',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: Colors.blue,
          onRefresh: () =>
              context.read<ProduccionDigitadorCubit>().loadData(silent: false),
          child: Column(
            children: [
              // Barra de búsqueda rápida
              _buildSearchBar(context, state, isDark),

              // Controles superiores: Por Pedido / Consolidado
              _buildTopControls(context, state, isDark),

              // Filtros
              _buildFiltersBar(context, state, isDark),

              // Contenido
              Expanded(
                child: state.viewMode == 'consolidado'
                    ? _buildConsolidadoView(context, state, isDark)
                    : _buildPorPedidoView(context, state, isDark),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(
    BuildContext context,
    ProduccionDigitadorState state,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: TextField(
        onChanged: (val) =>
            context.read<ProduccionDigitadorCubit>().setSearchTerm(val),
        decoration: InputDecoration(
          hintText: 'Buscar por pedido, producto o trazabilidad...',
          hintStyle: const TextStyle(fontSize: 12),
          prefixIcon: const Icon(Icons.search, size: 20),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          filled: true,
          fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        ),
      ),
    );
  }

  Widget _buildTopControls(
    BuildContext context,
    ProduccionDigitadorState state,
    bool isDark,
  ) {
    final cubit = context.read<ProduccionDigitadorCubit>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(2),
            child: Row(
              children: [
                _buildSegmentButton(
                  title: 'Por Pedido (${state.filteredGroups.length})',
                  isSelected: state.viewMode == 'porPedido',
                  onTap: () => cubit.setViewMode('porPedido'),
                  isDark: isDark,
                ),
                _buildSegmentButton(
                  title: 'Consolidado por Fecha / DEU',
                  isSelected: state.viewMode == 'consolidado',
                  onTap: () => cubit.setViewMode('consolidado'),
                  isDark: isDark,
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
                ? Colors.blue.shade600
                : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
          ),
        ),
      ),
    );
  }

  Widget _buildFiltersBar(
    BuildContext context,
    ProduccionDigitadorState state,
    bool isDark,
  ) {
    final cubit = context.read<ProduccionDigitadorCubit>();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
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
              ? Colors.blue.withValues(alpha: 0.12)
              : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive
                ? Colors.blue
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
                    ? Colors.blue
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: isActive ? Colors.blue : Colors.grey,
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
                        ? const Icon(Icons.check, color: Colors.blue)
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
                              ? const Icon(Icons.check, color: Colors.blue)
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
    ProduccionDigitadorState state,
    bool isDark,
  ) {
    final consolidated = state.consolidatedItems;
    final cubit = context.read<ProduccionDigitadorCubit>();

    if (consolidated.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            const Text(
              'No se encontraron exportaciones',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      );
    }

    final groupedByDeu = <String, List<DigitadorConsolidatedItem>>{};
    for (final item in consolidated) {
      final sectionKey = "${item.deudorCodigo} - ${item.deudorNombre}";
      groupedByDeu.putIfAbsent(sectionKey, () => []).add(item);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: groupedByDeu.keys.length,
      itemBuilder: (context, index) {
        final sectionKey = groupedByDeu.keys.elementAt(index);
        final items = groupedByDeu[sectionKey]!;
        final isCollapsed = state.collapsedSections.contains(sectionKey);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => cubit.toggleSectionCollapse(sectionKey),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E3A8A).withValues(alpha: 0.3)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF3B82F6)
                        : const Color(0xFFBFDBFE),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCollapsed
                          ? Icons.chevron_right_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: isDark ? Colors.blue.shade300 : Colors.blue.shade900,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        sectionKey,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? Colors.blue.shade100
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
            if (!isCollapsed)
              ...items.map((prod) {
                final trazDig = prod.trazabilidadesDig.join(', ');
                final trazPro = prod.trazabilidadesPro.join(', ');

                return Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? Colors.grey.shade800
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              prod.productoNombre,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _buildStatusBadge(prod.estadoLabel),
                        ],
                      ),
                      Text(
                        'Código: ${prod.itemCode}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Pedido: ${prod.cantSolicitada} ${prod.unidad}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          Text(
                            'Despacho: ${prod.cantDespacho} ${prod.unidad}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: _emeraldColor,
                            ),
                          ),
                        ],
                      ),
                      if (trazDig.isNotEmpty || trazPro.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          children: [
                            if (trazDig.isNotEmpty)
                              Text(
                                'DIG: $trazDig',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blueGrey,
                                ),
                              ),
                            if (trazPro.isNotEmpty)
                              Text(
                                'PRO: $trazPro',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blueGrey,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  Widget _buildPorPedidoView(
    BuildContext context,
    ProduccionDigitadorState state,
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
              'Sin exportaciones registradas',
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
        final allDone = totalItems > 0 && completedItems == totalItems;
        final progress = totalItems > 0 ? completedItems / totalItems : 0.0;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _showOrderDetail(context, group),
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'DEU: ${group.deudorCodigo}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
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
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    group.tienda,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.grey.shade300
                          : Colors.grey.shade800,
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
                            color: Colors.blue,
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
                      const SizedBox(width: 6),
                      Icon(
                        allDone
                            ? Icons.check_circle_rounded
                            : Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: allDone ? _emeraldColor : Colors.grey,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/presentation/main_layout.dart';
import '../data/produccion_datasource.dart';
import 'cubit/produccion_pendiente_cubit.dart';
import 'cubit/produccion_supervisor_cubit.dart';
import 'cubit/produccion_digitador_cubit.dart';
import 'cubit/produccion_fabricacion_cubit.dart';
import 'views/pendiente_view.dart';
import 'views/supervisor_view.dart';
import 'views/digitador_view.dart';
import 'views/fabricacion_view.dart';

class ProduccionScreen extends StatefulWidget {
  final String? opcion;

  const ProduccionScreen({super.key, this.opcion});

  @override
  State<ProduccionScreen> createState() => _ProduccionScreenState();
}

class _ProduccionScreenState extends State<ProduccionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ProduccionDatasource _datasource = ProduccionDatasource();

  static const List<String> _tabs = [
    'Pendiente',
    'Orden de Producción',
    'Orden de Pedido',
    'Orden de Fabricación',
  ];

  @override
  void initState() {
    super.initState();
    int initialIndex = 0;
    if (widget.opcion != null) {
      final opLower = widget.opcion!.toLowerCase();
      if (opLower.contains('producci') || opLower.contains('supervisor')) {
        initialIndex = 1;
      } else if (opLower.contains('pedido') || opLower.contains('digitador')) {
        initialIndex = 2;
      } else if (opLower.contains('fabricaci')) {
        initialIndex = 3;
      }
    }

    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: initialIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              ProduccionPendienteCubit(datasource: _datasource)..loadData(),
        ),
        BlocProvider(
          create: (_) =>
              ProduccionSupervisorCubit(datasource: _datasource)..loadData(),
        ),
        BlocProvider(
          create: (_) =>
              ProduccionDigitadorCubit(datasource: _datasource)..loadData(),
        ),
        BlocProvider(
          create: (_) =>
              ProduccionFabricacionCubit(datasource: _datasource)..loadData(),
        ),
      ],
      child: Builder(
        builder: (blocContext) {
          return MainLayout(
            title: 'Módulo de Producción',
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Recargar',
                onPressed: () {
                  if (_tabController.index == 0) {
                    blocContext
                        .read<ProduccionPendienteCubit>()
                        .loadData(silent: false);
                  } else if (_tabController.index == 1) {
                    blocContext
                        .read<ProduccionSupervisorCubit>()
                        .loadData(silent: false);
                  } else if (_tabController.index == 2) {
                    blocContext
                        .read<ProduccionDigitadorCubit>()
                        .loadData(silent: false);
                  } else if (_tabController.index == 3) {
                    blocContext
                        .read<ProduccionFabricacionCubit>()
                        .loadData(silent: false);
                  }
                },
              ),
            ],
            body: Column(
              children: [
                // Barra de pestañas para las 4 páginas del módulo
                Container(
                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    indicatorColor: const Color(0xFF10B981),
                    indicatorWeight: 3,
                    labelColor: const Color(0xFF10B981),
                    unselectedLabelColor:
                        isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    labelStyle: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                    tabs: const [
                      Tab(text: 'Pendiente'),
                      Tab(text: 'Orden de Producción'),
                      Tab(text: 'Orden de Pedido'),
                      Tab(text: 'Orden de Fabricación'),
                    ],
                  ),
                ),

                // Vistas de cada pestaña
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: const [
                      // 1. Pendiente (Etapa 1 - Mesa / Empaque)
                      PendienteView(),

                      // 2. Orden de Producción (Etapa 2 - Supervisor)
                      SupervisorView(),

                      // 3. Orden de Pedido (Etapa 3 - Digitador)
                      DigitadorView(),

                      // 4. Orden de Fabricación (Cajas genéricas / SAP)
                      FabricacionView(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

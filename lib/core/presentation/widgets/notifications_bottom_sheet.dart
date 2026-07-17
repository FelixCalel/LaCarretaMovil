import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:go_router/go_router.dart';
import '../notifications_cubit.dart';

class NotificationsBottomSheet extends StatelessWidget {
  final ScrollController scrollController;

  const NotificationsBottomSheet({
    super.key,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, state) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Notificaciones',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (state.notifications.any((n) => !n.leido))
                      TextButton.icon(
                        onPressed: () {
                          context.read<NotificationsCubit>().markAllAsRead();
                        },
                        icon: const Icon(Icons.done_all, size: 18),
                        label: const Text('Marcar todo leido', style: TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: Skeletonizer(
                  enabled: state.isLoading,
                  child: () {
                    if (state.isLoading) {
                      return ListView.separated(
                        controller: scrollController,
                        itemCount: 5,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          return const ListTile(
                            title: Text('Cargando titulo...'),
                            subtitle: Text('Cargando mensaje de notificacion...'),
                          );
                        },
                      );
                    }

                    final unreadNotifs = state.notifications.where((n) => !n.leido).toList();
                    if (unreadNotifs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text('No tienes notificaciones', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      );
                    }

                    final displayedNotifs = unreadNotifs.take(state.limit).toList();
                    final hasMore = unreadNotifs.length > state.limit;

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: displayedNotifs.length + (hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == displayedNotifs.length) {
                          final remaining = unreadNotifs.length - state.limit;
                          return InkWell(
                            onTap: () {
                              context.read<NotificationsCubit>().loadMore();
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                              child: Center(
                                child: Text(
                                  'Cargar más ($remaining restantes)',
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }

                        final notif = displayedNotifs[index];
                        
                        Color color;
                        IconData icon;
                        final tipo = (notif.tipo ?? '').toLowerCase();
                        if (tipo == 'success') {
                          color = Colors.green;
                          icon = Icons.check_circle_outline;
                        } else if (tipo == 'error') {
                          color = Colors.red;
                          icon = Icons.error_outline;
                        } else if (tipo == 'warning') {
                          color = Colors.amber.shade700;
                          icon = Icons.warning_amber_outlined;
                        } else {
                          color = Colors.blue;
                          icon = Icons.info_outline;
                        }

                        final isDark = Theme.of(context).brightness == Brightness.dark;
                        final bg = isDark ? color.withValues(alpha: 0.15) : color.withValues(alpha: 0.08);
                        final border = color.withValues(alpha: 0.25);

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: border, width: 1),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: color.withValues(alpha: 0.15),
                              child: Icon(icon, color: color),
                            ),
                            title: Text(
                              notif.titulo,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(notif.mensaje),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('dd/MM/yyyy HH:mm').format(notif.creadoEl.toLocal()),
                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                              ],
                            ),
                            onTap: () {
                              if (!notif.leido) {
                                context.read<NotificationsCubit>().markAsRead(notif.id);
                              }
                              if (notif.pedidoId != null) {
                                Navigator.pop(context);
                                context.go('/historialPedido/listar');
                              }
                            },
                          ),
                        );
                      },
                    );
                  }(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

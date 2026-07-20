import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:go_router/go_router.dart';
import '../notifications_cubit.dart';
import '../../theme/app_theme.dart';

class NotificationsBottomSheet extends StatelessWidget {
  final ScrollController scrollController;

  const NotificationsBottomSheet({
    super.key,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardColor : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, state) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Notificaciones',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                    ),
                    if (state.notifications.any((n) => !n.leido))
                      TextButton.icon(
                        onPressed: () {
                          context.read<NotificationsCubit>().markAllAsRead();
                        },
                        icon: const Icon(Icons.done_all_rounded, size: 18),
                        label: const Text('Marcar todas leídas', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
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
                        padding: const EdgeInsets.all(16),
                        itemCount: 5,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
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
                            Icon(Icons.notifications_none_rounded, size: 64, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                            const SizedBox(height: 12),
                            const Text('No tienes notificaciones pendientes', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    }

                    final displayedNotifs = unreadNotifs.take(state.limit).toList();
                    final hasMore = unreadNotifs.length > state.limit;

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
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
                          color = AppTheme.successColor;
                          icon = Icons.check_circle_rounded;
                        } else if (tipo == 'error') {
                          color = AppTheme.errorColor;
                          icon = Icons.error_rounded;
                        } else if (tipo == 'warning') {
                          color = AppTheme.warningColor;
                          icon = Icons.warning_rounded;
                        } else {
                          color = AppTheme.accentColor;
                          icon = Icons.info_rounded;
                        }

                        final bg = isDark ? color.withValues(alpha: 0.15) : color.withValues(alpha: 0.08);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10.0),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon, color: color, size: 22),
                            ),
                            title: Text(
                              notif.titulo,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14.5,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  notif.mensaje,
                                  style: TextStyle(fontSize: 13, color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  DateFormat('dd/MM/yyyy • HH:mm').format(notif.creadoEl.toLocal()),
                                  style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                                ),
                              ],
                            ),
                            onTap: () {
                              if (!notif.leido) {
                                context.read<NotificationsCubit>().markAsRead(notif.id);
                              }
                              if (notif.pedidoId != null) {
                                Navigator.pop(context);
                                context.go('/pedidos');
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

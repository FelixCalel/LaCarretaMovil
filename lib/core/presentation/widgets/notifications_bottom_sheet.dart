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
                  child: state.notifications.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              const Text('No tienes notificaciones', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          controller: scrollController,
                          itemCount: state.isLoading ? 5 : state.notifications.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            if (state.isLoading) {
                              return const ListTile(
                                title: Text('Cargando titulo...'),
                                subtitle: Text('Cargando mensaje de notificacion...'),
                              );
                            }
                            final notif = state.notifications[index];
                            final colorScheme = notif.leido
                                ? Colors.grey
                                : notif.tipo == 'success'
                                    ? Colors.green
                                    : notif.tipo == 'error'
                                        ? Colors.red
                                        : notif.tipo == 'warning'
                                            ? Colors.orange
                                            : Theme.of(context).primaryColor;
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: colorScheme.withValues(alpha: 0.1),
                                child: Icon(
                                  notif.tipo == 'success'
                                      ? Icons.check_circle_outline
                                      : notif.tipo == 'error'
                                          ? Icons.error_outline
                                          : notif.tipo == 'warning'
                                              ? Icons.warning_amber_outlined
                                              : Icons.notifications_none,
                                  color: colorScheme,
                                ),
                              ),
                              title: Text(
                                notif.titulo,
                                style: TextStyle(
                                  fontWeight: notif.leido ? FontWeight.normal : FontWeight.bold,
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
                              trailing: notif.leido
                                  ? null
                                  : Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle,
                                      ),
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
                            );
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/notification_service.dart';
import 'models/notification_model.dart';

class NotificationsState {
  final List<NotificationModel> notifications;
  final bool isLoading;
  final NotificationModel? lastNewNotification;

  NotificationsState({
    required this.notifications,
    required this.isLoading,
    this.lastNewNotification,
  });

  int get unreadCount => notifications.where((n) => !n.leido).length;

  NotificationsState copyWith({
    List<NotificationModel>? notifications,
    bool? isLoading,
    NotificationModel? lastNewNotification,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      lastNewNotification: lastNewNotification,
    );
  }
}

class NotificationsCubit extends Cubit<NotificationsState> {
  final _service = NotificationService();
  StreamSubscription<NotificationModel>? _subscription;

  NotificationsCubit()
      : super(NotificationsState(notifications: [], isLoading: false));

  void listenToWebSocket() {
    _subscription?.cancel();
    _service.connect();
    _subscription = _service.notifications.listen((notification) {
      final updatedList = List<NotificationModel>.from(state.notifications)
        ..insert(0, notification);
      emit(state.copyWith(
        notifications: updatedList,
        lastNewNotification: notification,
      ));
    });
  }

  Future<void> loadNotifications() async {
    emit(state.copyWith(isLoading: true));
    final list = await _service.fetchNotifications();
    emit(state.copyWith(
      notifications: list,
      isLoading: false,
    ));
  }

  Future<void> markAsRead(int id) async {
    final updated = state.notifications.map((n) {
      if (n.id == id) {
        return NotificationModel(
          id: n.id,
          titulo: n.titulo,
          mensaje: n.mensaje,
          tipo: n.tipo,
          leido: true,
          creadoEl: n.creadoEl,
          pedidoId: n.pedidoId,
        );
      }
      return n;
    }).toList();
    emit(state.copyWith(notifications: updated));

    await _service.markAsRead(id);
  }

  Future<void> markAllAsRead() async {
    final updated = state.notifications.map((n) {
      return NotificationModel(
        id: n.id,
        titulo: n.titulo,
        mensaje: n.mensaje,
        tipo: n.tipo,
        leido: true,
        creadoEl: n.creadoEl,
        pedidoId: n.pedidoId,
      );
    }).toList();
    emit(state.copyWith(notifications: updated));

    await _service.markAllAsRead();
  }

  void clearLastNewNotification() {
    emit(state.copyWith(lastNewNotification: null));
  }

  void reset() {
    _subscription?.cancel();
    _subscription = null;
    _service.disconnect();
    emit(NotificationsState(notifications: [], isLoading: false));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    _service.disconnect();
    return super.close();
  }
}

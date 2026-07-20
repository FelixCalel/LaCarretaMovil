import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/notification_service.dart';
import '../data/pedidos_datasource.dart';
import '../domain/pedido_model.dart';

abstract class PedidosState {}

class PedidosInitial extends PedidosState {}

class PedidosLoading extends PedidosState {}

class PedidosLoaded extends PedidosState {
  final List<PedidoModel> pedidos;
  PedidosLoaded(this.pedidos);
}

class PedidosError extends PedidosState {
  final String error;
  PedidosError(this.error);
}

class PedidosCubit extends Cubit<PedidosState> {
  final PedidosDatasource datasource;
  StreamSubscription<Map<String, dynamic>>? _wsSubscription;

  PedidosCubit({required this.datasource}) : super(PedidosInitial()) {
    _listenToWS();
  }

  void _listenToWS() {
    _wsSubscription = NotificationService().wsEvents.listen((event) {
      final type = event['type'];
      if (type == 'on-order-status-changed') {
        fetchPedidos(isSilent: true);
      }
    });
  }

  Future<void> fetchPedidos({bool isSilent = false}) async {
    if (!isSilent || state is! PedidosLoaded) {
      emit(PedidosLoading());
    }
    try {
      final list = await datasource.getPedidos();
      emit(PedidosLoaded(list));
    } catch (e) {
      emit(PedidosError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> addPedido({
    required int deudorId,
    required int tiendaId,
    required int ciudadId,
    String? comentario,
  }) async {
    try {
      await datasource.createPedido(
        deudorId: deudorId,
        tiendaId: tiendaId,
        ciudadId: ciudadId,
        comentario: comentario,
      );
      // Refrescar lista después de crear
      await fetchPedidos();
    } catch (e) {
      emit(PedidosError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    return super.close();
  }
}

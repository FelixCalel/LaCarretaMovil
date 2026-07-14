import 'package:flutter_bloc/flutter_bloc.dart';
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

  PedidosCubit({required this.datasource}) : super(PedidosInitial());

  Future<void> fetchPedidos() async {
    emit(PedidosLoading());
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
}

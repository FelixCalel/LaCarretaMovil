import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/logger_service.dart';
import '../../data/produccion_datasource.dart';
import '../../domain/produccion_model.dart';
import 'produccion_digitador_state.dart';

class ProduccionDigitadorCubit extends Cubit<ProduccionDigitadorState> {
  final ProduccionDatasource datasource;

  ProduccionDigitadorCubit({required this.datasource})
      : super(const ProduccionDigitadorState());

  Future<void> loadData({bool silent = false}) async {
    if (!silent) {
      emit(state.copyWith(status: ProduccionDigitadorStatus.loading, clearError: true));
    }

    try {
      // Intentar cargar etapaId: 3 (digitador), si viene vacía cargar pedidos agrupados generales
      var groups = await datasource.getPedidosAgrupados(etapaId: 3);
      if (groups.isEmpty) {
        groups = await datasource.getPedidosAgrupados();
      }

      emit(state.copyWith(
        status: ProduccionDigitadorStatus.loaded,
        allGroups: groups,
      ));
    } catch (e) {
      Log.e('Error cargando pedidos de digitador', e);
      emit(state.copyWith(
        status: ProduccionDigitadorStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  void setSearchTerm(String term) {
    emit(state.copyWith(searchTerm: term));
  }

  void setCountryFilter(String? val) {
    emit(state.copyWith(countryFilter: val, clearCountry: val == null));
  }

  void setClientFilter(String? val) {
    emit(state.copyWith(clientFilter: val, clearClient: val == null));
  }

  void setDeuFilter(String? val) {
    emit(state.copyWith(deuFilter: val, clearDeu: val == null));
  }

  void setDateMode(String mode) {
    emit(state.copyWith(dateMode: mode));
  }

  void setSelectedDate(String? date) {
    emit(state.copyWith(selectedDate: date));
  }

  void setDateType(String type) {
    emit(state.copyWith(dateType: type));
  }

  void setViewMode(String mode) {
    emit(state.copyWith(viewMode: mode));
  }

  void selectOrder(PedidoAgrupadoModel? order) {
    emit(state.copyWith(
      selectedOrder: order,
      clearSelectedOrder: order == null,
    ));
  }

  void toggleSectionCollapse(String sectionKey) {
    final updated = Set<String>.from(state.collapsedSections);
    if (updated.contains(sectionKey)) {
      updated.remove(sectionKey);
    } else {
      updated.add(sectionKey);
    }
    emit(state.copyWith(collapsedSections: updated));
  }

  void clearMessages() {
    emit(state.copyWith(clearError: true, clearSuccess: true));
  }
}

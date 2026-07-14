import '../domain/pedido_model.dart';
import '../domain/catalog_models.dart';
import '../domain/detalle_model.dart';
import '../domain/producto_model.dart';

class CrearPedidoState {
  final bool isLoading;
  final String? error;
  final String? successMessage;
  
  final List<PedidoModel> draftPedidos;
  final List<CatalogCiudad> ciudades;
  final List<CatalogDeudor> deudores;
  final List<CatalogTienda> tiendas;
  final List<int> userRoutes;
  final int userPaisId;

  final Map<int, List<DetalleModel>> pedidoDetalles;
  final Map<int, List<ProductoModel>> deudorProductos;
  final Map<int, bool> expandedPedidos;
  final Map<int, bool> loadingDetails;
  
  final Map<int, int?> selectedProductForPedido;

  const CrearPedidoState({
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.draftPedidos = const [],
    this.ciudades = const [],
    this.deudores = const [],
    this.tiendas = const [],
    this.userRoutes = const [],
    this.userPaisId = 0,
    this.pedidoDetalles = const {},
    this.deudorProductos = const {},
    this.expandedPedidos = const {},
    this.loadingDetails = const {},
    this.selectedProductForPedido = const {},
  });

  CrearPedidoState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
    List<PedidoModel>? draftPedidos,
    List<CatalogCiudad>? ciudades,
    List<CatalogDeudor>? deudores,
    List<CatalogTienda>? tiendas,
    List<int>? userRoutes,
    int? userPaisId,
    Map<int, List<DetalleModel>>? pedidoDetalles,
    Map<int, List<ProductoModel>>? deudorProductos,
    Map<int, bool>? expandedPedidos,
    Map<int, bool>? loadingDetails,
    Map<int, int?>? selectedProductForPedido,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return CrearPedidoState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      draftPedidos: draftPedidos ?? this.draftPedidos,
      ciudades: ciudades ?? this.ciudades,
      deudores: deudores ?? this.deudores,
      tiendas: tiendas ?? this.tiendas,
      userRoutes: userRoutes ?? this.userRoutes,
      userPaisId: userPaisId ?? this.userPaisId,
      pedidoDetalles: pedidoDetalles ?? this.pedidoDetalles,
      deudorProductos: deudorProductos ?? this.deudorProductos,
      expandedPedidos: expandedPedidos ?? this.expandedPedidos,
      loadingDetails: loadingDetails ?? this.loadingDetails,
      selectedProductForPedido: selectedProductForPedido ?? this.selectedProductForPedido,
    );
  }
}

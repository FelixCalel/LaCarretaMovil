import 'package:go_router/go_router.dart';
import '../services/secure_storage_service.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/pedidos/presentation/pedidos_screen.dart';
import '../../features/pedidos/presentation/crear_pedido_screen.dart';
import '../../features/ventas/presentation/ventas_screen.dart';
import '../../features/produccion/presentation/produccion_screen.dart';
import '../../features/compras/presentation/compras_screen.dart';

class AppRouter {
  static final _storage = SecureStorageService();

  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    redirect: (context, state) async {
      final token = await _storage.getAccessToken();
      final loggingIn = state.matchedLocation == '/login';

      if (token == null && !loggingIn) {
        return '/login';
      }

      if (token != null && loggingIn) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/pedidos',
        builder: (context, state) => const PedidosScreen(),
      ),
      GoRoute(
        path: '/pedidos/crear',
        builder: (context, state) => const CrearPedidoScreen(),
      ),
      GoRoute(
        path: '/ventas',
        builder: (context, state) => const VentasScreen(),
      ),
      GoRoute(
        path: '/produccion',
        builder: (context, state) => const ProduccionScreen(),
      ),
      GoRoute(
        path: '/compras',
        builder: (context, state) => const ComprasScreen(),
      ),
    ],
  );
}

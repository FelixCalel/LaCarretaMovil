import 'package:go_router/go_router.dart';
import '../services/secure_storage_service.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/verify_otp_screen.dart';
import '../../features/auth/presentation/recovery_screen.dart';
import '../../features/auth/presentation/reset_password_screen.dart';
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
      final loc = state.matchedLocation;
      final isPublic = loc == '/login' ||
          loc == '/register' ||
          loc == '/verify-otp' ||
          loc == '/recovery' ||
          loc == '/reset-password';

      if (token == null && !isPublic) {
        return '/login';
      }

      if (token != null && loc == '/login') {
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
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/verify-otp',
        builder: (context, state) {
          final target = state.uri.queryParameters['target'] ?? '';
          final type = state.uri.queryParameters['type'] ?? 'register';
          final userId = state.uri.queryParameters['userId'];
          final username = state.uri.queryParameters['username'];
          final password = state.uri.queryParameters['password'];
          return VerifyOtpScreen(
            target: target,
            type: type,
            userId: userId,
            username: username,
            password: password,
          );
        },
      ),
      GoRoute(
        path: '/recovery',
        builder: (context, state) => const RecoveryScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return ResetPasswordScreen(token: token);
        },
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

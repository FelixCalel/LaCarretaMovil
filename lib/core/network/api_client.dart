import 'package:dio/dio.dart';
import '../config/environment.dart';
import '../services/secure_storage_service.dart';
import '../services/logger_service.dart';
import '../router/app_router.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  final Dio dio;
  final _storage = SecureStorageService();
  bool _isRefreshing = false;
  final List<void Function(String token)> _failedQueue = [];

  ApiClient._internal()
      : dio = Dio(
          BaseOptions(
            baseUrl: Environment.apiBaseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          Log.i('🌐 Solicitud HTTP: [${options.method}] ${options.path}');
          final token = await _storage.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          Log.i('✅ Respuesta HTTP: [${response.statusCode}] ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          final requestOptions = e.requestOptions;
          Log.w('❌ Error HTTP: [${e.response?.statusCode}] ${requestOptions.path}');

          // Si el error es 401 y no es login ni refresh
          if (e.response?.statusCode == 401 &&
              !requestOptions.path.contains('/login/login') &&
              !requestOptions.path.contains('/login/refresh-token')) {
            
            if (_isRefreshing) {
              Log.w('🔄 Refresco de token en progreso, encolando petición: ${requestOptions.path}');
              _failedQueue.add((token) {
                requestOptions.headers['Authorization'] = 'Bearer $token';
                _retry(requestOptions).then(
                  (res) => handler.resolve(res),
                  onError: (err) => handler.reject(err),
                );
              });
              return;
            }

            _isRefreshing = true;
            Log.w('🔑 Token de acceso expirado (401). Intentando refrescar...');

            try {
              final refreshToken = await _storage.getRefreshToken();
              if (refreshToken == null) {
                throw DioException(requestOptions: requestOptions);
              }

              final refreshDio = Dio(BaseOptions(baseUrl: Environment.apiBaseUrl));
              final response = await refreshDio.post(
                '/login/refresh-token',
                data: {'refreshToken': refreshToken},
              );

              final newAccessToken = response.data['accessToken'] as String;
              await _storage.saveAccessToken(newAccessToken);

              if (response.data['refreshToken'] != null) {
                await _storage.saveRefreshToken(response.data['refreshToken'] as String);
              }

              Log.i('🔑 Token refrescado con éxito. Liberando cola de peticiones...');
              _isRefreshing = false;

              // Desencolar y ejecutar las fallidas
              for (final callback in _failedQueue) {
                callback(newAccessToken);
              }
              _failedQueue.clear();

              // Reintentar la petición actual
              requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
              final retryResponse = await _retry(requestOptions);
              return handler.resolve(retryResponse);
            } catch (err) {
              Log.e('🚨 Falló el refresco del token. Deslogueando...', err);
              _isRefreshing = false;
              _failedQueue.clear();
              await _storage.clearAuthData();
              AppRouter.router.go('/login');
              return handler.next(e);
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) {
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
    );
    return dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }
}

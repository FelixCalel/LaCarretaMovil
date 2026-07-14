import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../router/app_router.dart';

class ApiClient {
  final Dio dio;
  final _storage = const FlutterSecureStorage();

  ApiClient({required String baseUrl})
      : dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
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
          final token = await _storage.read(key: 'access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            await _storage.delete(key: 'access_token');
            await _storage.delete(key: 'refresh_token');
            await _storage.delete(key: 'user_id');
            await _storage.delete(key: 'user_name');
            await _storage.delete(key: 'user_role_id');
            await _storage.delete(key: 'user_permissions');
            AppRouter.router.go('/login');
          }
          return handler.next(e);
        },
      ),
    );
  }
}

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/network/api_client.dart';
import '../domain/user_model.dart';

class AuthDatasource {
  final ApiClient apiClient;
  final _storage = const FlutterSecureStorage();

  AuthDatasource({required this.apiClient});

  Future<UserModel> login(String username, String password) async {
    try {
      final response = await apiClient.dio.post(
        '/login/login', // Endpoint del backend
        data: {
          'username': username,
          'password': password,
        },
      );

      final data = response.data;
      final accessToken = data['accessToken'] as String;
      final refreshToken = data['refreshToken'] as String;
      final userJson = data['user'] as Map<String, dynamic>;
      
      final user = UserModel.fromJson(userJson);

      // Guardar tokens y datos de forma segura
      await _storage.write(key: 'access_token', value: accessToken);
      await _storage.write(key: 'refresh_token', value: refreshToken);
      await _storage.write(key: 'user_id', value: user.id.toString());
      await _storage.write(key: 'user_name', value: user.nombre);
      await _storage.write(key: 'user_role_id', value: user.roleId.toString());

      // Guardar rutas del usuario
      final rutas = userJson['rutas'] as List<dynamic>? ?? [];
      final rutaIds = rutas.map((r) => r['id'].toString()).join(',');
      await _storage.write(key: 'user_routes', value: rutaIds);

      // Guardar pais del usuario
      final userPaisId = userJson['paisId'] ?? 0;
      await _storage.write(key: 'user_pais_id', value: userPaisId.toString());

      // Obtener y persistir permisos de módulos y opciones
      try {
        final permissionsResponse = await apiClient.dio.get(
          '/asignarRMOP/modulosPermisos/${user.id}',
          options: Options(
            headers: {
              'Authorization': 'Bearer $accessToken',
            },
          ),
        );
        await _storage.write(
          key: 'user_permissions',
          value: jsonEncode(permissionsResponse.data),
        );
      } catch (e) {
        await _storage.write(key: 'user_permissions', value: '[]');
      }

      return user;
    } on DioException catch (e) {
      final errorMessage = e.response?.data['error'] ?? 'Error de conexión';
      throw Exception(errorMessage);
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'user_id');
    await _storage.delete(key: 'user_name');
    await _storage.delete(key: 'user_role_id');
    await _storage.delete(key: 'user_routes');
    await _storage.delete(key: 'user_pais_id');
    await _storage.delete(key: 'user_permissions');
  }
}

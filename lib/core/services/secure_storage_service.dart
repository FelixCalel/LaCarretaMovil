import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;

  final FlutterSecureStorage _storage;

  SecureStorageService._internal() : _storage = const FlutterSecureStorage();

  // Keys Constants
  static const String _kAccessToken = 'access_token';
  static const String _kRefreshToken = 'refresh_token';
  static const String _kUserId = 'user_id';
  static const String _kUserName = 'user_name';
  static const String _kUserRoleId = 'user_role_id';
  static const String _kUserRoutes = 'user_routes';
  static const String _kUserPaisId = 'user_pais_id';
  static const String _kUserPermissions = 'user_permissions';
  static const String _kBioUser = 'bio_user';
  static const String _kBioPass = 'bio_pass';
  static const String _kUserAvatar = 'user_avatar';

  // Read methods
  Future<String?> getAccessToken() => _storage.read(key: _kAccessToken);
  Future<String?> getRefreshToken() => _storage.read(key: _kRefreshToken);
  Future<String?> getUserId() => _storage.read(key: _kUserId);
  Future<String?> getUserName() => _storage.read(key: _kUserName);
  Future<String?> getUserRoleId() => _storage.read(key: _kUserRoleId);
  Future<String?> getUserRoutes() => _storage.read(key: _kUserRoutes);
  Future<String?> getUserPaisId() => _storage.read(key: _kUserPaisId);
  Future<String?> getUserPermissions() => _storage.read(key: _kUserPermissions);
  Future<String?> getBioUser() => _storage.read(key: _kBioUser);
  Future<String?> getBioPass() => _storage.read(key: _kBioPass);
  Future<String?> getUserAvatar() => _storage.read(key: _kUserAvatar);

  // Write methods
  Future<void> saveAccessToken(String value) => _storage.write(key: _kAccessToken, value: value);
  Future<void> saveRefreshToken(String value) => _storage.write(key: _kRefreshToken, value: value);
  Future<void> saveUserId(String value) => _storage.write(key: _kUserId, value: value);
  Future<void> saveUserName(String value) => _storage.write(key: _kUserName, value: value);
  Future<void> saveUserRoleId(String value) => _storage.write(key: _kUserRoleId, value: value);
  Future<void> saveUserRoutes(String value) => _storage.write(key: _kUserRoutes, value: value);
  Future<void> saveUserPaisId(String value) => _storage.write(key: _kUserPaisId, value: value);
  Future<void> saveUserPermissions(String value) => _storage.write(key: _kUserPermissions, value: value);
  Future<void> saveUserAvatar(String value) => _storage.write(key: _kUserAvatar, value: value);
  
  Future<void> saveBioCredentials(String username, String password) async {
    await _storage.write(key: _kBioUser, value: username);
    await _storage.write(key: _kBioPass, value: password);
  }

  // Delete methods
  Future<void> deleteAccessToken() => _storage.delete(key: _kAccessToken);
  Future<void> deleteRefreshToken() => _storage.delete(key: _kRefreshToken);
  Future<void> deleteUserId() => _storage.delete(key: _kUserId);
  Future<void> deleteUserName() => _storage.delete(key: _kUserName);
  Future<void> deleteUserRoleId() => _storage.delete(key: _kUserRoleId);
  Future<void> deleteUserRoutes() => _storage.delete(key: _kUserRoutes);
  Future<void> deleteUserPaisId() => _storage.delete(key: _kUserPaisId);
  Future<void> deleteUserPermissions() => _storage.delete(key: _kUserPermissions);
  Future<void> deleteUserAvatar() => _storage.delete(key: _kUserAvatar);
  
  Future<void> deleteBioCredentials() async {
    await _storage.delete(key: _kBioUser);
    await _storage.delete(key: _kBioPass);
  }

  Future<void> clearAuthData() async {
    await deleteAccessToken();
    await deleteRefreshToken();
    await deleteUserId();
    await deleteUserName();
    await deleteUserRoleId();
    await deleteUserRoutes();
    await deleteUserPaisId();
    await deleteUserPermissions();
    await deleteUserAvatar();
  }
}

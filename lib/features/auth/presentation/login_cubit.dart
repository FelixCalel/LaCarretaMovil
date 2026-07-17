import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../../core/services/logger_service.dart';
import '../data/auth_datasource.dart';
import '../domain/user_model.dart';

abstract class LoginState {}

class LoginInitial extends LoginState {}

class LoginLoading extends LoginState {}

class LoginSuccess extends LoginState {
  final UserModel user;
  final bool promptBiometrics;
  final String savedUsername;
  final String savedPassword;
  LoginSuccess(this.user, {this.promptBiometrics = false, this.savedUsername = '', this.savedPassword = ''});
}

class LoginFailure extends LoginState {
  final String error;
  LoginFailure(this.error);
}

class BiometricsReady extends LoginState {
  final bool canCheckBiometrics;
  final String? savedUsername;
  BiometricsReady(this.canCheckBiometrics, {this.savedUsername});
}

class LoginCubit extends Cubit<LoginState> {
  final AuthDatasource authDatasource;
  final _storage = SecureStorageService();
  final _localAuth = LocalAuthentication();

  LoginCubit({required this.authDatasource}) : super(LoginInitial());

  Future<void> checkBiometrics() async {
    try {
      final savedUser = await _storage.getBioUser();
      final savedPass = await _storage.getBioPass();
      Log.i('=== DEBUG BIOMETRICS ===');
      Log.i('Saved user: $savedUser');
      Log.i('Saved pass length: ${savedPass?.length ?? 0}');
      
      if (savedUser != null && savedPass != null) {
        final canCheck = await _localAuth.canCheckBiometrics;
        final isSupported = await _localAuth.isDeviceSupported();
        Log.i('canCheckBiometrics: $canCheck');
        Log.i('isDeviceSupported: $isSupported');
        
        if (canCheck || isSupported) {
          Log.i('Emitting BiometricsReady(true)');
          emit(BiometricsReady(true, savedUsername: savedUser));
        } else {
          Log.i('Biometrics not supported or not enrolled');
        }
      } else {
        Log.i('No saved credentials for biometrics');
      }
      Log.i('========================');
    } catch (e) {
      Log.e('Error checking biometrics', e);
    }
  }

  Future<void> loginWithBiometrics() async {
    try {
      final savedUser = await _storage.getBioUser();
      final savedPass = await _storage.getBioPass();

      if (savedUser == null || savedPass == null) {
        emit(LoginFailure('No hay credenciales guardadas para la huella.'));
        return;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Inicia sesión con tu huella dactilar o rostro',
        persistAcrossBackgrounding: true,
        biometricOnly: true,
      );

      if (authenticated) {
        emit(LoginLoading());
        final user = await authDatasource.login(savedUser, savedPass);
        emit(LoginSuccess(user));
      }
    } catch (e) {
      final savedUser = await _storage.getBioUser();
      Log.e('Error al autenticar con huella', e);
      emit(LoginFailure('Error al autenticar con huella. Intente con contraseña.'));
      emit(BiometricsReady(true, savedUsername: savedUser));
    }
  }

  Future<void> login(String username, String password) async {
    emit(LoginLoading());
    try {
      final user = await authDatasource.login(username, password);
      
      final savedUser = await _storage.getBioUser();
      final canCheck = await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
      
      bool promptBio = canCheck && savedUser == null;
      
      emit(LoginSuccess(user, promptBiometrics: promptBio, savedUsername: username, savedPassword: password));
    } catch (e) {
      Log.e('Error en login tradicional', e);
      emit(LoginFailure(e.toString().replaceAll('Exception: ', '')));
      checkBiometrics();
    }
  }

  Future<void> enableBiometrics(String username, String password) async {
    await _storage.saveBioCredentials(username, password);
  }

  Future<void> disableBiometrics() async {
    await _storage.deleteBioCredentials();
  }
}

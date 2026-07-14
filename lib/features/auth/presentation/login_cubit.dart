import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
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

class LoginBiometricsAvailable extends LoginState {
  // This state is just a signal to the UI that biometrics are available 
  // so the UI can show the fingerprint button. 
  // It shouldn't overwrite the form state, so we might want to handle it differently, 
  // but for simplicity, the screen can just rebuild or we can add a boolean to initial state.
}

// A better approach is to make a structured state class, but since we are refactoring slightly,
// we will just add a CheckBiometricsResult.
class BiometricsReady extends LoginState {
  final bool canCheckBiometrics;
  final String? savedUsername;
  BiometricsReady(this.canCheckBiometrics, {this.savedUsername});
}

class LoginCubit extends Cubit<LoginState> {
  final AuthDatasource authDatasource;
  final _storage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();

  LoginCubit({required this.authDatasource}) : super(LoginInitial());

  Future<void> checkBiometrics() async {
    try {
      final savedUser = await _storage.read(key: 'bio_user');
      final savedPass = await _storage.read(key: 'bio_pass');
      print('=== DEBUG BIOMETRICS ===');
      print('Saved user: $savedUser');
      print('Saved pass length: ${savedPass?.length ?? 0}');
      
      if (savedUser != null && savedPass != null) {
        final canCheck = await _localAuth.canCheckBiometrics;
        final isSupported = await _localAuth.isDeviceSupported();
        print('canCheckBiometrics: $canCheck');
        print('isDeviceSupported: $isSupported');
        
        if (canCheck || isSupported) {
          print('Emitting BiometricsReady(true)');
          emit(BiometricsReady(true, savedUsername: savedUser));
        } else {
          print('Biometrics not supported or not enrolled');
        }
      } else {
        print('No saved credentials for biometrics');
      }
      print('========================');
    } catch (e) {
      print('Error checking biometrics: $e');
    }
  }

  Future<void> loginWithBiometrics() async {
    try {
      final savedUser = await _storage.read(key: 'bio_user');
      final savedPass = await _storage.read(key: 'bio_pass');

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
        // Ejecutar login con las credenciales guardadas
        emit(LoginLoading());
        final user = await authDatasource.login(savedUser, savedPass);
        emit(LoginSuccess(user));
      }
    } catch (e) {
      final savedUser = await _storage.read(key: 'bio_user');
      emit(LoginFailure('Error al autenticar con huella. Intente con contraseña.'));
      // Emitir ready nuevamente para que puedan seguir viendo el boton
      emit(BiometricsReady(true, savedUsername: savedUser));
    }
  }

  Future<void> login(String username, String password) async {
    emit(LoginLoading());
    try {
      final user = await authDatasource.login(username, password);
      
      // Comprobar si ya tiene activado el biometría
      final savedUser = await _storage.read(key: 'bio_user');
      final canCheck = await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
      
      // Si el dispositivo soporta y no tiene configurada la huella, sugerimos habilitarlo
      bool promptBio = canCheck && savedUser == null;
      
      emit(LoginSuccess(user, promptBiometrics: promptBio, savedUsername: username, savedPassword: password));
    } catch (e) {
      emit(LoginFailure(e.toString().replaceAll('Exception: ', '')));
      checkBiometrics(); // re-check en caso de fallo para mostrar boton
    }
  }

  Future<void> enableBiometrics(String username, String password) async {
    await _storage.write(key: 'bio_user', value: username);
    await _storage.write(key: 'bio_pass', value: password);
  }

  Future<void> disableBiometrics() async {
    await _storage.delete(key: 'bio_user');
    await _storage.delete(key: 'bio_pass');
  }
}

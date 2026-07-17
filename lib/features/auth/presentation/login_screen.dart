
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/logger_service.dart';
import '../data/auth_datasource.dart';
import '../../../core/network/api_client.dart';
import 'login_cubit.dart';
import '../../../core/presentation/widgets/floating_particles_background.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient();
    final authDatasource = AuthDatasource(apiClient: apiClient);

    return BlocProvider(
      create: (context) => LoginCubit(authDatasource: authDatasource),
      child: const _LoginScreenView(),
    );
  }
}

class _LoginScreenView extends StatefulWidget {
  const _LoginScreenView();

  @override
  State<_LoginScreenView> createState() => _LoginScreenViewState();
}

class _LoginScreenViewState extends State<_LoginScreenView> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _obscurePassword = true;
  bool _showBiometricButton = false;
  bool _autoPromptFired = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<LoginCubit>().checkBiometrics();
      }
    });
  }

  Future<void> _showBiometricPrompt(LoginSuccess state) async {
    final cubit = context.read<LoginCubit>();
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Inicio Rápido'),
        content: const Text('¿Deseas habilitar el inicio de sesión con huella dactilar o reconocimiento facial para la próxima vez?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No, gracias', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: const Text('Habilitar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true) {
      await cubit.enableBiometrics(state.savedUsername, state.savedPassword);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Huella habilitada correctamente'), backgroundColor: Colors.green),
      );
    }
    
    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<LoginCubit, LoginState>(
        listener: (context, state) {
          Log.i('=== LOGIN SCREEN LISTENER: state is ${state.runtimeType} ===');
          if (state is BiometricsReady) {
            Log.i('BiometricsReady received: canCheck=${state.canCheckBiometrics}, username=${state.savedUsername}');
            setState(() {
              _showBiometricButton = state.canCheckBiometrics;
            });
            if (state.savedUsername != null) {
              _formKey.currentState?.fields['username']?.didChange(state.savedUsername);
            }
            // Auto prompt only once when the screen loads
            if (!_autoPromptFired && state.canCheckBiometrics) {
              Log.i('Auto prompting biometrics...');
              _autoPromptFired = true;
              context.read<LoginCubit>().loginWithBiometrics();
            }
          } else if (state is LoginSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('¡Bienvenido, ${state.user.nombre}!'),
                backgroundColor: Colors.green,
              ),
            );
            
            if (state.promptBiometrics) {
              _showBiometricPrompt(state);
            } else {
              context.go('/home');
            }
          } else if (state is LoginFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              // Fondo decorativo con gradiente premium
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryDarkColor, AppTheme.primaryColor, AppTheme.primaryLightColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              const RepaintBoundary(
                child: FloatingParticlesBackground(),
              ),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Card(
                      color: Theme.of(context).cardColor,
                      elevation: 12.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: FormBuilder(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/images/LogoLaCarreta.png',
                                height: 100.0,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.store_mall_directory_outlined,
                                    size: 64.0,
                                    color: Theme.of(context).primaryColor,
                                  );
                                },
                              ).animate().fade(duration: 500.ms).scale(curve: Curves.easeOutBack),
                              const SizedBox(height: 16.0),
                              Text(
                                'La Carreta Móvil',
                                style: TextStyle(
                                  fontSize: 24.0,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ).animate().fade(delay: 200.ms).slideY(begin: 0.2, end: 0),
                              const SizedBox(height: 8.0),
                              const Text(
                                'Inicia sesión para continuar',
                                style: TextStyle(
                                  fontSize: 14.0,
                                  color: Colors.grey,
                                ),
                              ).animate().fade(delay: 300.ms).slideY(begin: 0.2, end: 0),
                              const SizedBox(height: 24.0),
                              
                              // Input de Usuario con FormBuilder
                              FormBuilderTextField(
                                name: 'username',
                                decoration: InputDecoration(
                                  labelText: 'Usuario o Correo',
                                  prefixIcon: const Icon(Icons.person_outline),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  filled: true,
                                  fillColor: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.grey[100],
                                ),
                                validator: FormBuilderValidators.compose([
                                  FormBuilderValidators.required(errorText: 'Por favor ingresa tu usuario'),
                                ]),
                              ).animate().fade(delay: 400.ms).slideX(begin: -0.1, end: 0),
                              const SizedBox(height: 16.0),
                              
                              // Input de Contraseña con FormBuilder
                              FormBuilderTextField(
                                name: 'password',
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: 'Contraseña',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  filled: true,
                                  fillColor: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.grey[100],
                                ),
                                validator: FormBuilderValidators.compose([
                                  FormBuilderValidators.required(errorText: 'Por favor ingresa tu contraseña'),
                                ]),
                              ).animate().fade(delay: 500.ms).slideX(begin: 0.1, end: 0),
                              const SizedBox(height: 24.0),
                              
                              // Botón de Enviar
                              SizedBox(
                                width: double.infinity,
                                height: 50.0,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).primaryColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    elevation: 4.0,
                                  ),
                                  onPressed: state is LoginLoading
                                      ? null
                                      : () {
                                          if (_formKey.currentState?.saveAndValidate() ?? false) {
                                            final vals = _formKey.currentState!.value;
                                            context.read<LoginCubit>().login(
                                                  vals['username'],
                                                  vals['password'],
                                                );
                                          }
                                        },
                                  child: state is LoginLoading
                                      ? const SizedBox(
                                          height: 24.0,
                                          width: 24.0,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'Iniciar Sesión',
                                          style: TextStyle(
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ).animate().fade(delay: 600.ms).scale(),
                              
                              // Botón de Huella
                              if (_showBiometricButton) ...[
                                const SizedBox(height: 16.0),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50.0,
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.fingerprint, size: 28.0),
                                    label: const Text(
                                      'Iniciar con Huella',
                                      style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Theme.of(context).primaryColor,
                                      side: BorderSide(color: Theme.of(context).primaryColor, width: 2.0),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12.0),
                                      ),
                                    ),
                                    onPressed: state is LoginLoading
                                        ? null
                                        : () {
                                            context.read<LoginCubit>().loginWithBiometrics();
                                          },
                                  ),
                                ).animate().fade(delay: 700.ms).scale(),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ).animate().fade(duration: 400.ms).slideY(begin: 0.1, end: 0),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

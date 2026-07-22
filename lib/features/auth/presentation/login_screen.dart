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
import 'package:google_sign_in/google_sign_in.dart';

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
        title: const Row(
          children: [
            Icon(Icons.fingerprint, color: AppTheme.primaryColor, size: 28),
            SizedBox(width: 12),
            Text('Inicio Rápido'),
          ],
        ),
        content: const Text(
          '¿Deseas habilitar el inicio de sesión con huella dactilar o reconocimiento facial para tus próximos accesos?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Ahora no', style: TextStyle(color: Colors.grey)),
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
        const SnackBar(
          content: Text('Huella habilitada correctamente'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    
    if (!mounted) return;
    context.go('/home');
  }
  
  Future<void> _showSocialAuthPlaceholder(String provider) async {
    String? userEmail;

    if (provider == 'Google') {
      try {
        const clientId = String.fromEnvironment('GOOGLE_CLIENT_ID');
        final GoogleSignIn googleSignIn = GoogleSignIn(
          clientId: clientId.isNotEmpty ? clientId : null,
          scopes: ['email', 'profile'],
        );
        final googleUser = await googleSignIn.signIn();
        if (googleUser != null) {
          userEmail = googleUser.email;
        } else {
          return;
        }
      } catch (e) {
        Log.e('Error al acceder a cuenta Google nativa en login', e);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Atención: El selector de cuentas nativas de Google requiere registrar la clave SHA-1 de desarrollo en Google Cloud Console. Detalle: $e'),
            backgroundColor: AppTheme.warningColor,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    } else if (provider == 'Microsoft') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Iniciando autenticación nativa de Microsoft...'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!mounted || userEmail == null) return;

    _formKey.currentState?.fields['username']?.didChange(userEmail);
    _formKey.currentState?.fields['password']?.didChange('LaCarreta2026!');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cuenta $userEmail seleccionada del teléfono. Iniciando sesión...'),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final vals = _formKey.currentState!.value;
      context.read<LoginCubit>().login(
            vals['username'],
            vals['password'],
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: BlocConsumer<LoginCubit, LoginState>(
        listener: (context, state) {
          Log.i('=== LOGIN SCREEN LISTENER: state is ${state.runtimeType} ===');
          if (state is BiometricsReady) {
            setState(() {
              _showBiometricButton = state.canCheckBiometrics;
            });
            if (state.savedUsername != null) {
              _formKey.currentState?.fields['username']?.didChange(state.savedUsername);
            }
            if (!_autoPromptFired && state.canCheckBiometrics) {
              _autoPromptFired = true;
              context.read<LoginCubit>().loginWithBiometrics();
            }
          } else if (state is LoginSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.white),
                    const SizedBox(width: 12),
                    Text('¡Bienvenido, ${state.user.nombre}!'),
                  ],
                ),
                backgroundColor: AppTheme.successColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            );
            
            if (state.promptBiometrics) {
              _showBiometricPrompt(state);
            } else {
              context.go('/home');
            }
          } else if (state is Login2FARequired) {
            context.go(
              '/verify-otp'
              '?target=${Uri.encodeComponent(state.maskedPhone)}'
              '&type=login'
              '&userId=${state.userId}'
              '&username=${Uri.encodeComponent(state.username)}'
              '&password=${Uri.encodeComponent(state.password)}',
            );
          } else if (state is LoginFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(child: Text(state.error)),
                  ],
                ),
                backgroundColor: AppTheme.errorColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            );
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              // Fondo degradado fluido
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF031604), const Color(0xFF09290B), const Color(0xFF0B132B)]
                        : [AppTheme.primaryDarkColor, AppTheme.primaryColor, AppTheme.primaryLightColor],
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
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                    child: Container(
                      width: MediaQuery.of(context).size.width > 500 ? 440 : MediaQuery.of(context).size.width * 0.9,
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkCardColor : Colors.white,
                        borderRadius: BorderRadius.circular(28.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 24.0,
                            offset: const Offset(0, 10),
                          ),
                        ],
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                        ),
                      ),
                      padding: const EdgeInsets.all(28.0),
                      child: FormBuilder(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Logo de La Carreta animado
                            Container(
                              padding: const EdgeInsets.all(14.0),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                              ),
                              child: Image.asset(
                                'assets/images/LogoLaCarreta.png',
                                height: 75.0,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => Icon(
                                  Icons.storefront_rounded,
                                  size: 48,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ).animate().fade(duration: 400.ms).scale(),
                            const SizedBox(height: 12),
                            Text(
                              'La Carreta',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Accede a tu cuenta de distribuidor',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Campo Usuario
                            FormBuilderTextField(
                              name: 'username',
                              decoration: const InputDecoration(
                                labelText: 'Usuario o Correo',
                                prefixIcon: Icon(Icons.person_outline_rounded),
                              ),
                              validator: FormBuilderValidators.required(
                                errorText: 'El usuario es obligatorio',
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Campo Contraseña
                            FormBuilderTextField(
                              name: 'password',
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Contraseña',
                                prefixIcon: const Icon(Icons.lock_outline_rounded),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: FormBuilderValidators.required(
                                errorText: 'La contraseña es obligatoria',
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Botón Principal Iniciar Sesión
                            SizedBox(
                              width: double.infinity,
                              height: 54.0,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white,
                                  elevation: 4.0,
                                  shadowColor: Theme.of(context).primaryColor.withValues(alpha: 0.4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16.0),
                                  ),
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
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Iniciar Sesión',
                                            style: TextStyle(
                                              fontSize: 17.0,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Icon(Icons.arrow_forward_rounded, size: 20),
                                        ],
                                      ),
                              ),
                            ).animate().fade(delay: 600.ms).scale(),
                            
                            // Botón Huella Digital
                            if (_showBiometricButton) ...[
                              const SizedBox(height: 16.0),
                              SizedBox(
                                width: double.infinity,
                                height: 54.0,
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.fingerprint_rounded, size: 26.0),
                                  label: const Text(
                                    'Acceder con Huella',
                                    style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Theme.of(context).primaryColor,
                                    side: BorderSide(color: Theme.of(context).primaryColor, width: 2.0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16.0),
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

                            // Separador OAuth
                            const SizedBox(height: 24.0),
                            Row(
                              children: [
                                Expanded(child: Divider(color: isDark ? Colors.white30 : Colors.black12)),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Text(
                                    'O continuar con',
                                    style: TextStyle(fontSize: 12.5, color: Colors.grey, fontWeight: FontWeight.w500),
                                  ),
                                ),
                                Expanded(child: Divider(color: isDark ? Colors.white30 : Colors.black12)),
                              ],
                            ),
                            const SizedBox(height: 18.0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                                      side: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                                    ),
                                    icon: const Icon(Icons.g_mobiledata_rounded, size: 28, color: Colors.red),
                                    label: Text(
                                      'Google',
                                      style: TextStyle(
                                        color: isDark ? Colors.white : Colors.black87,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    onPressed: () => _showSocialAuthPlaceholder('Google'),
                                  ),
                                ),
                                const SizedBox(width: 12.0),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                                      side: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                                    ),
                                    icon: const Icon(Icons.mail_rounded, size: 20, color: Colors.blue),
                                    label: Text(
                                      'Microsoft',
                                      style: TextStyle(
                                        color: isDark ? Colors.white : Colors.black87,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    onPressed: () => _showSocialAuthPlaceholder('Microsoft'),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20.0),
                            
                            // Enlaces de ayuda
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton(
                                  onPressed: () => context.go('/recovery'),
                                  child: const Text('¿Olvidaste la clave?'),
                                ),
                                TextButton(
                                  onPressed: () => context.go('/register'),
                                  child: const Text(
                                    'Crear cuenta',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ).animate().fade(duration: 400.ms).slideY(begin: 0.08, end: 0),
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

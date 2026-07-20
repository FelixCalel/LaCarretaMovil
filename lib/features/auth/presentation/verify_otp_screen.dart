import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/logger_service.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/presentation/widgets/floating_particles_background.dart';
import '../data/auth_datasource.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String target;
  final String type;
  final String? userId;
  final String? username;
  final String? password;

  const VerifyOtpScreen({
    super.key,
    required this.target,
    required this.type,
    this.userId,
    this.username,
    this.password,
  });

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> with WidgetsBindingObserver {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkClipboard();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkClipboard();
    }
  }

  Future<void> _checkClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final text = clipboardData?.text?.trim();
      if (text != null && RegExp(r'^\d{6}$').hasMatch(text)) {
        if (_pinController.text != text) {
          setState(() {
            _pinController.text = text;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Código OTP detectado y copiado automáticamente'),
                backgroundColor: AppTheme.successColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            );
          }
          _verifyCode(text);
        }
      }
    } catch (e) {
      Log.e('Error al leer portapapeles', e);
    }
  }

  Future<void> _verifyCode(String code) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.type == 'login') {
        Log.i('Validando OTP de Login 2FA: ${widget.userId}');
        final authDatasource = AuthDatasource(apiClient: ApiClient());
        final user = await authDatasource.verifyLogin2FA(int.parse(widget.userId!), code);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Bienvenido, ${user.nombre}!'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );

        final localAuth = LocalAuthentication();
        final canCheck = await localAuth.canCheckBiometrics || await localAuth.isDeviceSupported();
        final storage = SecureStorageService();
        final savedUser = await storage.getBioUser();

        if (canCheck && savedUser == null && widget.username != null && widget.password != null) {
          if (!mounted) return;
          final enableBio = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
              title: const Text('Inicio Rápido'),
              content: const Text('¿Deseas habilitar el inicio de sesión con huella dactilar o reconocimiento facial?'),
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

          if (enableBio == true) {
            await storage.saveBioCredentials(widget.username!, widget.password!);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Huella habilitada correctamente'),
                  backgroundColor: AppTheme.successColor,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        }

        if (mounted) {
          context.go('/home');
        }
      } else if (widget.type == 'register') {
        Log.i('Validando OTP teléfono ${widget.target}: $code');
        await ApiClient().dio.post('/usuarios/verify-phone', data: {
          'telefono': widget.target,
          'code': code,
        });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Cuenta verificada con éxito. Ya puedes iniciar sesión.'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
        context.go('/login');
      } else {
        Log.i('Validando OTP recuperación para teléfono ${widget.target}: $code');
        final response = await ApiClient().dio.post('/usuarios/verificar-clave-sms', data: {
          'telefono': widget.target,
          'code': code,
        });

        final token = response.data['token'] as String?;
        if (token == null || token.isEmpty) {
          throw Exception('No se recibió el token de restablecimiento.');
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Código verificado con éxito.'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
        context.go('/reset-password?token=${Uri.encodeComponent(token)}');
      }
    } catch (e) {
      Log.e('Error en verificación OTP', e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Código incorrecto o expirado. Intente de nuevo.'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
      _pinController.clear();
      _pinFocusNode.requestFocus();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    final defaultPinTheme = PinTheme(
      width: 50,
      height: 54,
      textStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131C38) : const Color(0xFFF1F5F9),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
        borderRadius: BorderRadius.circular(14),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: primaryColor, width: 2),
      borderRadius: BorderRadius.circular(14),
    );

    return Scaffold(
      body: Stack(
        children: [
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
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  width: size.width > 500 ? 460 : size.width * 0.9,
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
                  ),
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primaryColor.withValues(alpha: 0.1),
                        ),
                        child: Icon(
                          Icons.mark_email_read_rounded,
                          size: 52,
                          color: primaryColor,
                        ),
                      ).animate().fade(duration: 400.ms).scale(),
                      const SizedBox(height: 16),
                      const Text(
                        'Verificación OTP',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Hemos enviado un código de 6 dígitos al destino:',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.target,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Pinput(
                        length: 6,
                        controller: _pinController,
                        focusNode: _pinFocusNode,
                        autofillHints: const [AutofillHints.oneTimeCode],
                        defaultPinTheme: defaultPinTheme,
                        focusedPinTheme: focusedPinTheme,
                        hapticFeedbackType: HapticFeedbackType.lightImpact,
                        onCompleted: (pin) => _verifyCode(pin),
                      ),
                      const SizedBox(height: 32),
                      if (_isLoading)
                        const CircularProgressIndicator()
                      else ...[
                        OutlinedButton.icon(
                          icon: const Icon(Icons.paste_rounded, size: 20),
                          label: const Text('Pegar del Portapapeles'),
                          onPressed: () {
                            _checkClipboard();
                          },
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => context.go('/login'),
                          child: const Text('Regresar al Login'),
                        ),
                      ]
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

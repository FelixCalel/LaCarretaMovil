import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/logger_service.dart';
import '../../../core/services/secure_storage_service.dart';
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
    // Verificar portapapeles al iniciar la pantalla
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
              const SnackBar(
                content: Text('Código OTP detectado y copiado automáticamente'),
                backgroundColor: Colors.green,
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
        Log.i('📤 Verificando OTP de Login 2FA para usuario: ${widget.userId}');
        final authDatasource = AuthDatasource(apiClient: ApiClient());
        final user = await authDatasource.verifyLogin2FA(int.parse(widget.userId!), code);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Bienvenido, ${user.nombre}!'),
            backgroundColor: Colors.green,
          ),
        );

        final localAuth = LocalAuthentication();
        final canCheck = await localAuth.canCheckBiometrics || await localAuth.isDeviceSupported();
        final storage = SecureStorageService();
        final savedUser = await storage.getBioUser();

        if (canCheck && savedUser == null && widget.username != null && widget.password != null) {
          if (!mounted) return;
          final primaryColor = Theme.of(context).primaryColor;
          final enableBio = await showDialog<bool>(
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
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                  child: const Text('Habilitar', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );

          if (enableBio == true) {
            await storage.saveBioCredentials(widget.username!, widget.password!);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Huella habilitada correctamente'), backgroundColor: Colors.green),
              );
            }
          }
        }

        if (mounted) {
          context.go('/home');
        }
      } else if (widget.type == 'register') {
        Log.i('📤 Verificando OTP registro para teléfono ${widget.target}: $code');
        await ApiClient().dio.post('/usuarios/verify-phone', data: {
          'telefono': widget.target,
          'code': code,
        });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cuenta verificada con éxito. Ya puedes iniciar sesión.'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/login');
      } else {
        // Recovery
        Log.i('📤 Verificando OTP recuperación para teléfono ${widget.target}: $code');
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
          const SnackBar(
            content: Text('Código verificado con éxito.'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/reset-password?token=${Uri.encodeComponent(token)}');
      }
    } catch (e) {
      Log.e('❌ Error en verificación OTP', e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Código incorrecto o expirado. Intente de nuevo.'),
          backgroundColor: Colors.red,
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
    final primaryColor = Theme.of(context).primaryColor;

    final defaultPinTheme = PinTheme(
      width: 48,
      height: 48,
      textStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: primaryColor,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: primaryColor, width: 2),
      borderRadius: BorderRadius.circular(8),
    );

    return Scaffold(
      body: Stack(
        children: [
          const FloatingParticlesBackground(),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Card(
                elevation: 12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Container(
                  width: size.width > 500 ? 450 : size.width * 0.9,
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.sms_outlined,
                        size: 60,
                        color: primaryColor,
                      ).animate().fade(duration: 400.ms).scale(),
                      const SizedBox(height: 16),
                      const Text(
                        'Verificación OTP',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Hemos enviado un código de 6 dígitos al número:',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.target,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
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
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return 'Ingrese los 6 dígitos.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      if (_isLoading)
                        const CircularProgressIndicator()
                      else ...[
                        TextButton(
                          onPressed: () {
                            Clipboard.setData(const ClipboardData(text: ''));
                            _checkClipboard();
                          },
                          child: const Text('Re-verificar Portapapeles'),
                        ),
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

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/logger_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/presentation/widgets/floating_particles_background.dart';

class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({super.key});

  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isLoading = false;
  String _selectedMethod = 'sms';

  Future<void> _submitRecovery() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      final values = _formKey.currentState!.value;
      final input = values['input']?.toString().trim() ?? '';

      try {
        if (_selectedMethod == 'sms') {
          Log.i('Solicitando recuperación por SMS para teléfono: $input');
          await ApiClient().dio.post('/usuarios/recuperar-clave-sms', data: {
            'telefono': input,
          });

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Código de recuperación enviado.'),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          );
          context.go('/verify-otp?target=${Uri.encodeComponent(input)}&type=recovery');
        } else {
          Log.i('Solicitando recuperación por Correo para: $input');
          await ApiClient().dio.post('/usuarios/recuperar_clave_email', data: {
            'correo': input,
          });

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Correo de recuperación enviado con éxito.'),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          );
          context.go('/login');
        }
      } catch (e) {
        Log.e('Error en recuperación de clave', e);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error al enviar solicitud. Verifique los datos.'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

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
                  child: FormBuilder(
                    key: _formKey,
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
                            Icons.lock_reset_rounded,
                            size: 52,
                            color: primaryColor,
                          ),
                        ).animate().fade(duration: 400.ms).scale(),
                        const SizedBox(height: 16),
                        const Text(
                          'Recuperar Contraseña',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Selecciona el método de recuperación para recibir tu código o enlace.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        FormBuilderDropdown<String>(
                          name: 'method',
                          initialValue: 'sms',
                          decoration: const InputDecoration(
                            labelText: 'Método de Recuperación',
                            prefixIcon: Icon(Icons.settings_suggest_rounded),
                          ),
                          onChanged: (val) {
                            setState(() {
                              _selectedMethod = val ?? 'sms';
                              _formKey.currentState?.fields['input']?.reset();
                            });
                          },
                          items: const [
                            DropdownMenuItem(value: 'sms', child: Text('Código SMS')),
                            DropdownMenuItem(value: 'email', child: Text('Enlace por Email')),
                          ],
                        ),
                        const SizedBox(height: 16),
                        FormBuilderTextField(
                          key: ValueKey(_selectedMethod),
                          name: 'input',
                          decoration: InputDecoration(
                            labelText: _selectedMethod == 'sms' ? 'Número de Teléfono' : 'Correo electrónico',
                            prefixIcon: Icon(
                              _selectedMethod == 'sms' ? Icons.phone_outlined : Icons.email_outlined,
                            ),
                          ),
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.required(
                              errorText: 'Este campo es obligatorio.',
                            ),
                            if (_selectedMethod == 'email')
                              FormBuilderValidators.email(
                                errorText: 'Ingrese un correo válido.',
                              ),
                            if (_selectedMethod == 'sms')
                              FormBuilderValidators.numeric(
                                errorText: 'Ingrese un número válido.',
                              ),
                          ]),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitRecovery,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                    'Enviar Solicitud',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => context.go('/login'),
                          child: const Text('Volver al Iniciar Sesión'),
                        ),
                      ],
                    ),
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

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/logger_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/presentation/widgets/floating_particles_background.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String _selectedVerificationMethod = 'sms';

  Future<void> _submitRegister() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      final values = _formKey.currentState!.value;
      final nombre = values['nombre']?.toString() ?? '';
      final apellido = values['apellido']?.toString() ?? '';
      final correo = values['correo']?.toString().trim();
      final telefono = values['telefono']?.toString().trim();
      final contrasena = values['contrasena']?.toString() ?? '';

      if ((correo == null || correo.isEmpty) && (telefono == null || telefono.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Debe proporcionar correo o teléfono.'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      try {
        final data = {
          'nombre': nombre,
          'apellido': apellido,
          'correo': (correo != null && correo.isNotEmpty) ? correo : null,
          'telefono': (telefono != null && telefono.isNotEmpty) ? telefono : null,
          'contrasena': contrasena,
          'paisId': 1,
          'verificationMethod': _selectedVerificationMethod,
          'roleId': 0,
        };

        Log.i('📤 Enviando registro: $data');
        await ApiClient().dio.post('/usuarios/registro', data: data);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Usuario registrado exitosamente.'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );

        if (_selectedVerificationMethod == 'sms' && telefono != null && telefono.isNotEmpty) {
          context.go('/verify-otp?target=${Uri.encodeComponent(telefono)}&type=register');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Por favor, revise su correo para validar su cuenta.'),
              backgroundColor: AppTheme.accentColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          );
          context.go('/login');
        }
      } catch (e) {
        Log.e('❌ Error en registro', e);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error al registrar. Verifique los datos o si ya existe.'),
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
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
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
                        Container(
                          padding: const EdgeInsets.all(14.0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          ),
                          child: Image.asset(
                            'assets/images/LogoLaCarreta.png',
                            height: 70.0,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.person_add_alt_1_rounded,
                              size: 48,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ).animate().fade(duration: 400.ms).scale(),
                        const SizedBox(height: 12),
                        Text(
                          'Crear Cuenta',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Completa tus datos para empezar',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Campos de texto
                        Row(
                          children: [
                            Expanded(
                              child: FormBuilderTextField(
                                name: 'nombre',
                                decoration: const InputDecoration(
                                  labelText: 'Nombre',
                                  prefixIcon: Icon(Icons.person_outline_rounded),
                                ),
                                validator: FormBuilderValidators.required(
                                  errorText: 'Obligatorio',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FormBuilderTextField(
                                name: 'apellido',
                                decoration: const InputDecoration(
                                  labelText: 'Apellido',
                                  prefixIcon: Icon(Icons.person_outline_rounded),
                                ),
                                validator: FormBuilderValidators.required(
                                  errorText: 'Obligatorio',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        FormBuilderTextField(
                          name: 'correo',
                          decoration: const InputDecoration(
                            labelText: 'Correo electrónico',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.email(
                              errorText: 'Ingrese un correo válido',
                            ),
                          ]),
                        ),
                        const SizedBox(height: 16),
                        FormBuilderTextField(
                          name: 'telefono',
                          decoration: const InputDecoration(
                            labelText: 'Teléfono',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.numeric(
                              errorText: 'Ingrese un número válido',
                            ),
                          ]),
                        ),
                        const SizedBox(height: 16),
                        FormBuilderTextField(
                          name: 'contrasena',
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
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.required(
                              errorText: 'La contraseña es obligatoria',
                            ),
                            FormBuilderValidators.minLength(
                              6,
                              errorText: 'Mínimo 6 caracteres',
                            ),
                          ]),
                        ),
                        const SizedBox(height: 16),
                        FormBuilderDropdown<String>(
                          name: 'verificationMethod',
                          initialValue: 'sms',
                          decoration: const InputDecoration(
                            labelText: 'Método de Verificación',
                            prefixIcon: Icon(Icons.verified_user_outlined),
                          ),
                          onChanged: (val) {
                            setState(() {
                              _selectedVerificationMethod = val ?? 'sms';
                            });
                          },
                          items: const [
                            DropdownMenuItem(value: 'sms', child: Text('SMS (Código al celular)')),
                            DropdownMenuItem(value: 'email', child: Text('Email (Enlace de activación)')),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                    'Registrarse',
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
                          child: const Text('¿Ya tienes cuenta? Inicia Sesión'),
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

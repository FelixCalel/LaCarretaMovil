import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/logger_service.dart';
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
          const SnackBar(
            content: Text('Debe proporcionar correo o teléfono.'),
            backgroundColor: Colors.red,
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
          const SnackBar(
            content: Text('Usuario registrado exitosamente.'),
            backgroundColor: Colors.green,
          ),
        );

        if (_selectedVerificationMethod == 'sms' && telefono != null && telefono.isNotEmpty) {
          context.go('/verify-otp?target=${Uri.encodeComponent(telefono)}&type=register');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Por favor, revise su correo para validar su cuenta.'),
              backgroundColor: Colors.blue,
            ),
          );
          context.go('/login');
        }
      } catch (e) {
        Log.e('❌ Error en registro', e);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar. Verifique los datos o si ya existe.'),
            backgroundColor: Colors.red,
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
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      body: Stack(
        children: [
          const FloatingParticlesBackground(),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
              child: Card(
                elevation: 12,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Container(
                  width: size.width > 500 ? 450 : size.width * 0.9,
                  padding: const EdgeInsets.all(32.0),
                  child: FormBuilder(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/logo.png',
                          height: 80,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.local_shipping,
                            size: 60,
                            color: primaryColor,
                          ),
                        ).animate().fade(duration: 400.ms).scale(),
                        const SizedBox(height: 16),
                        Text(
                          'Crear Cuenta',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 24),
                        FormBuilderTextField(
                          name: 'nombre',
                          decoration: InputDecoration(
                            labelText: 'Nombre',
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: FormBuilderValidators.required(
                            errorText: 'El nombre es obligatorio.',
                          ),
                        ),
                        const SizedBox(height: 16),
                        FormBuilderTextField(
                          name: 'apellido',
                          decoration: InputDecoration(
                            labelText: 'Apellido',
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: FormBuilderValidators.required(
                            errorText: 'El apellido es obligatorio.',
                          ),
                        ),
                        const SizedBox(height: 16),
                        FormBuilderTextField(
                          name: 'correo',
                          decoration: InputDecoration(
                            labelText: 'Correo electrónico',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.email(
                              errorText: 'Ingrese un correo válido.',
                            ),
                          ]),
                        ),
                        const SizedBox(height: 16),
                        FormBuilderTextField(
                          name: 'telefono',
                          decoration: InputDecoration(
                            labelText: 'Teléfono',
                            prefixIcon: const Icon(Icons.phone_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.numeric(
                              errorText: 'Ingrese un número válido.',
                            ),
                          ]),
                        ),
                        const SizedBox(height: 16),
                        FormBuilderTextField(
                          name: 'contrasena',
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.required(
                              errorText: 'La contraseña es obligatoria.',
                            ),
                            FormBuilderValidators.minLength(
                              6,
                              errorText: 'Mínimo 6 caracteres.',
                            ),
                          ]),
                        ),
                        const SizedBox(height: 16),
                        FormBuilderDropdown<String>(
                          name: 'verificationMethod',
                          initialValue: 'sms',
                          decoration: InputDecoration(
                            labelText: 'Método de Verificación',
                            prefixIcon: const Icon(Icons.verified_user_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (val) {
                            setState(() {
                              _selectedVerificationMethod = val ?? 'sms';
                            });
                          },
                          items: const [
                            DropdownMenuItem(value: 'sms', child: Text('SMS')),
                            DropdownMenuItem(value: 'email', child: Text('Email')),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
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

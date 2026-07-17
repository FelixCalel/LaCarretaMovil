import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/logger_service.dart';
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
          Log.i('📤 Solicitando recuperación por SMS para teléfono: $input');
          await ApiClient().dio.post('/usuarios/recuperar-clave-sms', data: {
            'telefono': input,
          });

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Código de recuperación enviado.'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/verify-otp?target=${Uri.encodeComponent(input)}&type=recovery');
        } else {
          // Email
          Log.i('📤 Solicitando recuperación por Correo para: $input');
          await ApiClient().dio.post('/usuarios/recuperar_clave_email', data: {
            'correo': input,
          });

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Correo de recuperación enviado con éxito.'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/login');
        }
      } catch (e) {
        Log.e('❌ Error en recuperación de clave', e);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al enviar solicitud de recuperación. Verifique el dato.'),
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
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Card(
                elevation: 12,
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
                        Icon(
                          Icons.lock_open_outlined,
                          size: 60,
                          color: primaryColor,
                        ).animate().fade(duration: 400.ms).scale(),
                        const SizedBox(height: 16),
                        const Text(
                          'Recuperar Contraseña',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Selecciona el método de recuperación para recibir tu código o enlace.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 24),
                        FormBuilderDropdown<String>(
                          name: 'method',
                          initialValue: 'sms',
                          decoration: InputDecoration(
                            labelText: 'Método de Recuperación',
                            prefixIcon: const Icon(Icons.settings_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (val) {
                            setState(() {
                              _selectedMethod = val ?? 'sms';
                              _formKey.currentState?.fields['input']?.reset();
                            });
                          },
                          items: const [
                            DropdownMenuItem(value: 'sms', child: Text('SMS')),
                            DropdownMenuItem(value: 'email', child: Text('Email')),
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
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
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
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitRecovery,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
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
                          child: const Text('Volver al Login'),
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

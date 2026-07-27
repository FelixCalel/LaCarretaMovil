import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/logger_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/presentation/widgets/floating_particles_background.dart';
import '../data/auth_datasource.dart';
import '../domain/user_model.dart';
import 'package:google_sign_in/google_sign_in.dart';

class RegisterScreen extends StatefulWidget {
  final String? initialEmail;
  final String? initialDisplayName;

  const RegisterScreen({super.key, this.initialEmail, this.initialDisplayName});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String _selectedVerificationMethod = 'sms';

  // Lista de países cargada dinámicamente o por fallback estático
  List<Map<String, dynamic>> _countries = [
    {'id': 1, 'nombre': 'Guatemala', 'dialCode': '+502'},
    {'id': 2, 'nombre': 'El Salvador', 'dialCode': '+503'},
    {'id': 3, 'nombre': 'Honduras', 'dialCode': '+504'},
    {'id': 4, 'nombre': 'Nicaragua', 'dialCode': '+505'},
    {'id': 5, 'nombre': 'Costa Rica', 'dialCode': '+506'},
    {'id': 6, 'nombre': 'Belice', 'dialCode': '+501'},
  ];
  int _selectedCountryId = 1;

  @override
  void initState() {
    super.initState();
    _loadCountries();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialEmail != null) {
        _fillFromGoogleData(widget.initialEmail!, widget.initialDisplayName);
      }
    });
  }

  void _fillFromGoogleData(String userEmail, String? displayName) {
    String nom = '';
    String ape = '';
    if (displayName != null && displayName.isNotEmpty) {
      final parts = displayName.split(' ');
      nom = parts[0];
      ape = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    } else {
      final parts = userEmail.split('@')[0].split('.');
      nom = parts[0];
      ape = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    }

    if (nom.isNotEmpty) nom = nom[0].toUpperCase() + nom.substring(1);
    if (ape.isNotEmpty) ape = ape[0].toUpperCase() + ape.substring(1);

    _formKey.currentState?.fields['nombre']?.didChange(nom);
    _formKey.currentState?.fields['apellido']?.didChange(ape);
    _formKey.currentState?.fields['correo']?.didChange(userEmail);

    // Generar contraseña sugerida/aleatoria para flujo rápido
    final randomPass =
        'Gg#${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}!';
    _formKey.currentState?.fields['contrasena']?.didChange(randomPass);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Cuenta $userEmail vinculada con Google. Ingresa tu número de teléfono para finalizar.',
        ),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _loadCountries() async {
    try {
      final response = await ApiClient().dio.get('/pais/listar');
      if (response.data is List) {
        final List<dynamic> list = response.data;
        setState(() {
          _countries = list
              .map(
                (item) => {
                  'id': int.tryParse(item['id'].toString()) ?? 0,
                  'nombre': item['nombre']?.toString() ?? '',
                  'dialCode': item['dialCode']?.toString() ?? '',
                },
              )
              .where((c) => c['id'] != 0)
              .toList();
        });
      }
    } catch (e) {
      Log.w(
        'No se pudo cargar la lista de países desde el servidor, usando estáticos: $e',
      );
    }
  }

  Future<void> _submitRegister() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      final values = _formKey.currentState!.value;
      final nombre = values['nombre']?.toString() ?? '';
      final apellido = values['apellido']?.toString() ?? '';
      final correo = values['correo']?.toString().trim();
      final rawTelefono = values['telefono']?.toString().trim() ?? '';
      final contrasena = values['contrasena']?.toString() ?? '';

      if ((correo == null || correo.isEmpty) && rawTelefono.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Debe proporcionar correo o teléfono.'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Concatenar código del país al teléfono (normalización)
      String? telefono;
      if (rawTelefono.isNotEmpty) {
        final selectedCountry = _countries.firstWhere(
          (c) => c['id'] == _selectedCountryId,
          orElse: () => _countries.first,
        );
        String dialCode = (selectedCountry['dialCode'] ?? '')
            .toString()
            .replaceAll(' ', '');
        if (dialCode.isNotEmpty && !dialCode.startsWith('+')) {
          dialCode = '+$dialCode';
        }

        // Limpiar el input quitando cualquier caracter no numérico
        final digits = rawTelefono.replaceAll(RegExp(r'\D+'), '');
        telefono = '$dialCode$digits';
      }

      try {
        final data = {
          'nombre': nombre,
          'apellido': apellido,
          'correo': (correo != null && correo.isNotEmpty) ? correo : null,
          'telefono': telefono,
          'contrasena': contrasena,
          'paisId': _selectedCountryId,
          'verificationMethod': 'none',
          'roleId': 0,
        };

        Log.i('📤 Enviando registro con país y teléfono concatenado: $data');
        await ApiClient().dio.post('/usuarios/registro', data: data);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Usuario registrado exitosamente.'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );

        if (_selectedVerificationMethod == 'sms' &&
            telefono != null &&
            telefono.isNotEmpty) {
          context.go(
            '/verify-otp?target=${Uri.encodeComponent(telefono)}&type=register',
          );
        } else {
          // Intentar Login Automático con el identificador correcto (correo o teléfono)
          final loginIdentifier = (correo != null && correo.isNotEmpty)
              ? correo
              : (telefono != null && telefono.isNotEmpty ? telefono : nombre);

          try {
            final authDatasource = AuthDatasource(apiClient: ApiClient());
            final loginResult = await authDatasource.login(
              loginIdentifier,
              contrasena,
            );
            if (!mounted) return;

            if (loginResult is UserModel) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '¡Cuenta creada e inicio de sesión automático exitoso! Bienvenido, ${loginResult.nombre}',
                  ),
                  backgroundColor: AppTheme.successColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              );
              context.go('/home');
              return;
            }
          } catch (loginErr) {
            Log.e('Error al intentar auto-login tras registro', loginErr);
          }

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Registro completado. Por favor inicie sesión o verifique su cuenta.',
              ),
              backgroundColor: AppTheme.accentColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
          context.go('/login');
        }
      } catch (e) {
        Log.e('❌ Error en registro', e);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al registrar: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
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

  Future<void> _showSocialAuthPlaceholder(String provider) async {
    String? userEmail;
    String? displayName;

    if (provider == 'Google') {
      try {
        final GoogleSignIn googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
        );
        await googleSignIn.signOut();
        final googleUser = await googleSignIn.signIn();
        if (googleUser != null) {
          userEmail = googleUser.email;
          displayName = googleUser.displayName;
        } else {
          // El usuario canceló la selección de cuenta
          return;
        }
      } catch (e) {
        Log.e('Error al acceder al selector de cuentas de Google', e);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Atención: El selector de cuentas nativas de Google requiere registrar la clave SHA-1 de desarrollo en Google Cloud Console. Detalle: $e',
            ),
            backgroundColor: AppTheme.warningColor,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    } else if (provider == 'Microsoft') {
      // Para Microsoft en producción se usa MSAL. Por ahora informamos la integración nativa.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Iniciando autenticación nativa de Microsoft...'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!mounted || userEmail == null) return;

    // Extraer datos de la cuenta nativa seleccionada
    String nom = '';
    String ape = '';
    if (displayName != null && displayName.isNotEmpty) {
      final parts = displayName.split(' ');
      nom = parts[0];
      ape = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    } else {
      final parts = userEmail.split('@')[0].split('.');
      nom = parts[0];
      ape = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    }

    if (nom.isNotEmpty) nom = nom[0].toUpperCase() + nom.substring(1);
    if (ape.isNotEmpty) ape = ape[0].toUpperCase() + ape.substring(1);

    // Asignar los datos extraídos de la cuenta del dispositivo directamente
    _formKey.currentState?.fields['nombre']?.didChange(nom);
    _formKey.currentState?.fields['apellido']?.didChange(ape);
    _formKey.currentState?.fields['correo']?.didChange(userEmail);
    _formKey.currentState?.fields['contrasena']?.didChange('LaCarreta2026!');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Cuenta $userEmail seleccionada del teléfono. Creando cuenta...',
        ),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );

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
                    ? [
                        const Color(0xFF031604),
                        const Color(0xFF09290B),
                        const Color(0xFF0B132B),
                      ]
                    : [
                        AppTheme.primaryDarkColor,
                        AppTheme.primaryColor,
                        AppTheme.primaryLightColor,
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          const RepaintBoundary(child: FloatingParticlesBackground()),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 24.0,
                ),
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
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.05),
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
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary,
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
                                  prefixIcon: Icon(
                                    Icons.person_outline_rounded,
                                  ),
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
                                  prefixIcon: Icon(
                                    Icons.person_outline_rounded,
                                  ),
                                ),
                                validator: FormBuilderValidators.required(
                                  errorText: 'Obligatorio',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Selector de País de Origen
                        FormBuilderDropdown<int>(
                          name: 'paisId',
                          initialValue: _selectedCountryId,
                          decoration: const InputDecoration(
                            labelText: 'País de origen',
                            prefixIcon: Icon(Icons.public_rounded),
                          ),
                          items: _countries.map((country) {
                            return DropdownMenuItem<int>(
                              value: country['id'] as int,
                              child: Text(
                                '${country['nombre']} (${country['dialCode']})',
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedCountryId = val;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        FormBuilderTextField(
                          name: 'correo',
                          decoration: const InputDecoration(
                            labelText: 'Correo electrónico',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) return null;
                            final emailRx = RegExp(r'^\S+@\S+\.\S+$');
                            if (!emailRx.hasMatch(val)) {
                              return 'Ingrese un correo válido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        FormBuilderTextField(
                          name: 'telefono',
                          decoration: const InputDecoration(
                            labelText: 'Teléfono',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) return null;
                            if (double.tryParse(val) == null) {
                              return 'Ingrese un número válido';
                            }
                            return null;
                          },
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
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
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
                            DropdownMenuItem(value: 'sms', child: Text('SMS')),
                            DropdownMenuItem(
                              value: 'email',
                              child: Text('Correo Electrónico'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // Botón de registro
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.0),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    'Crear Cuenta',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),

                        // Separador OAuth
                        const SizedBox(height: 24.0),
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: isDark ? Colors.white30 : Colors.black12,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                'O continuar con',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: isDark ? Colors.white30 : Colors.black12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12.0,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  side: BorderSide(
                                    color: isDark
                                        ? Colors.white24
                                        : Colors.black12,
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.g_mobiledata_rounded,
                                  size: 28,
                                  color: Colors.red,
                                ),
                                label: Text(
                                  'Google',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                onPressed: () =>
                                    _showSocialAuthPlaceholder('Google'),
                              ),
                            ),
                            const SizedBox(width: 12.0),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12.0,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  side: BorderSide(
                                    color: isDark
                                        ? Colors.white24
                                        : Colors.black12,
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.mail_rounded,
                                  size: 20,
                                  color: Colors.blue,
                                ),
                                label: Text(
                                  'Microsoft',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                onPressed: () =>
                                    _showSocialAuthPlaceholder('Microsoft'),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20.0),

                        // Enlace para volver a iniciar sesión
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '¿Ya tienes una cuenta? ',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.lightTextSecondary,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.go('/login'),
                              child: Text(
                                'Inicia Sesión',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
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

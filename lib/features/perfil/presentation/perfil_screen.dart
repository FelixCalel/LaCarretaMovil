import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../../core/services/logger_service.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _storage = SecureStorageService();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSaving = false;
  int? _userId;
  String? _avatarBase64;

  final _nombresController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _correoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _nombresController.dispose();
    _apellidosController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    super.dispose();
  }

  String _getInitials(String nombres, String apellidos) {
    String initials = '';
    if (nombres.isNotEmpty) initials += nombres[0];
    if (apellidos.isNotEmpty) initials += apellidos[0];
    if (initials.isEmpty) return 'U';
    return initials.toUpperCase();
  }

  Uint8List? _decodeBase64(String? base64Str) {
    if (base64Str == null || base64Str.isEmpty) return null;
    try {
      String cleanStr = base64Str;
      if (cleanStr.contains(',')) {
        cleanStr = cleanStr.split(',')[1];
      }
      return base64Decode(cleanStr.trim());
    } catch (e) {
      return null;
    }
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiClient().dio.get('/login/me');
      final userData = response.data['user'];
      Log.i('=== PERFIL DIAGNOSTIC ===');
      Log.i('userData JSON: $userData');
      if (userData != null) {
        _userId = int.tryParse(userData['id'].toString());
        Log.i('Parsed User ID: $_userId');
        _nombresController.text = (userData['nombre'] ?? '').toString();
        _apellidosController.text = (userData['apellido'] ?? '').toString();
        _telefonoController.text = (userData['telefono'] ?? '').toString();
        _correoController.text = (userData['correo'] ?? '').toString();
      }

      // Intentar cargar avatar guardado en local
      final savedAvatar = await _storage.getUserAvatar();
      if (savedAvatar != null && savedAvatar.isNotEmpty) {
        Log.i('Saved avatar found in SecureStorage (length: ${savedAvatar.length})');
        setState(() {
          _avatarBase64 = savedAvatar;
        });
      }

      if (_userId != null) {
        try {
          Log.i('Fetching avatar for user ID: $_userId');
          final avatarResponse = await ApiClient().dio.get('/usuarios/$_userId/avatar');
          final av = avatarResponse.data['avatar'] as String?;
          Log.i('Fetch avatar response status: ${avatarResponse.statusCode}');
          Log.i('Avatar data length: ${av?.length ?? 0}');
          if (av != null && av.isNotEmpty) {
            setState(() {
              _avatarBase64 = av;
            });
            await _storage.saveUserAvatar(av);
          }
        } catch (e) {
          Log.w('Error fetching avatar from backend: $e');
        }
      } else {
        Log.w('_userId is NULL, cannot fetch avatar');
      }
    } catch (e) {
      Log.e('Error loading profile data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cargar datos del perfil'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_userId == null) return;

      setState(() {
        _isSaving = true;
      });

      try {
        await ApiClient().dio.put(
          '/usuarios/$_userId',
          data: {
            'nombre': _nombresController.text.trim(),
            'apellido': _apellidosController.text.trim(),
          },
        );

        // Guardar nombre actualizado en SecureStorage para el Drawer/Home
        final nuevoNombreCompleto = '${_nombresController.text.trim()} ${_apellidosController.text.trim()}'.trim();
        await _storage.saveUserName(nuevoNombreCompleto);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Perfil actualizado exitosamente.'),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al guardar los cambios.'),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  Future<void> _pickAndUploadImage(
    ImageSource source, {
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) async {
    if (_userId == null) return;

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        preferredCameraDevice: preferredCameraDevice,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _isSaving = true;
      });

      final bytes = await image.readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      // Enviar al backend
      await ApiClient().dio.put(
        '/usuarios/$_userId',
        data: {
          'avatar': base64Image,
        },
      );

      // Guardar localmente
      await _storage.saveUserAvatar(base64Image);

      setState(() {
        _avatarBase64 = base64Image;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto de perfil actualizada correctamente.'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cambiar la foto de perfil.'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'Cambiar Foto de Perfil',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Elegir de la Galería'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Tomar Foto'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(ImageSource.camera, preferredCameraDevice: CameraDevice.rear);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final decodedBytes = _decodeBase64(_avatarBase64);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Encabezado del Perfil (Banner Premium M3 + Avatar)
                      Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          const SizedBox(height: 180, width: double.infinity),
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 120,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24.0),
                                border: Border.all(
                                  color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                                ),
                                gradient: LinearGradient(
                                  colors: isDark
                                      ? [const Color(0xFF0F172A), const Color(0xFF1E293B)] // Slate Premium Oscuro
                                      : [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)], // Slate Premium Claro
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Align(
                                alignment: Alignment.topLeft,
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Opacity(
                                    opacity: 0.06,
                                    child: Image.asset(
                                      'assets/images/LogoLaCarreta.png',
                                      height: 50,
                                      fit: BoxFit.contain,
                                      errorBuilder: (ctx, err, st) => const Icon(Icons.storefront, size: 50),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 60,
                            child: Container(
                              padding: const EdgeInsets.all(4.0),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).scaffoldBackgroundColor,
                              ),
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 55,
                                    backgroundColor: primaryColor,
                                    backgroundImage: decodedBytes != null
                                        ? MemoryImage(decodedBytes)
                                        : null,
                                    child: decodedBytes == null
                                        ? Text(
                                            _getInitials(_nombresController.text, _apellidosController.text),
                                            style: const TextStyle(
                                              fontSize: 38.0,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          )
                                        : null,
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: _showImageSourceOptions,
                                      child: Container(
                                        padding: const EdgeInsets.all(8.0),
                                        decoration: BoxDecoration(
                                          color: primaryColor,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Theme.of(context).scaffoldBackgroundColor,
                                            width: 2.0,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt_rounded,
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ).animate().fade(duration: 400.ms).scale(),
                      
                      const SizedBox(height: 70),

                      Text(
                        '${_nombresController.text} ${_apellidosController.text}'.trim(),
                        style: const TextStyle(
                          fontSize: 22.0,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _correoController.text,
                        style: TextStyle(
                          fontSize: 14.0,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Campos Editables
                      TextFormField(
                        controller: _nombresController,
                        decoration: const InputDecoration(
                          labelText: 'Nombres',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'El nombre es requerido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _apellidosController,
                        decoration: const InputDecoration(
                          labelText: 'Apellidos',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'El apellido es requerido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Campos Deshabilitados
                      TextFormField(
                        controller: _telefonoController,
                        enabled: false,
                        decoration: InputDecoration(
                          labelText: 'Teléfono',
                          prefixIcon: const Icon(Icons.phone_outlined),
                          helperText: 'El teléfono no se puede modificar.',
                          helperStyle: TextStyle(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _correoController,
                        enabled: false,
                        decoration: InputDecoration(
                          labelText: 'Correo Electrónico',
                          prefixIcon: const Icon(Icons.email_outlined),
                          helperText: 'El correo electrónico no se puede modificar.',
                          helperStyle: TextStyle(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                        ),
                      ),

                      const SizedBox(height: 36),

                      // Botón Guardar Cambios
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.successColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                          ),
                          child: _isSaving
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'Guardar Cambios',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

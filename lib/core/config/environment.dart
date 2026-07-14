import 'dart:io';
import 'package:flutter/foundation.dart';

class Environment {
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: '',
  );

  static String get apiBaseUrl {
    if (apiUrl.isNotEmpty) return apiUrl;

    // Si estamos en modo release (APK compilado o Shorebird), usar el servidor real
    if (kReleaseMode) {
      return 'http://localhost:3000/api';
    }

    // Valores de desarrollo por defecto (modo debug)
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api';
    } else {
      return 'http://localhost:3000/api';
    }
  }
}

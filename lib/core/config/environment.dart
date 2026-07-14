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
      return 'https://stg-caback.popoyan.com.gt/api';
    }

    // Valores de desarrollo por defecto (modo debug)
    if (kIsWeb) {
      return 'https://stg-caback.popoyan.com.gt/api';
    } else if (Platform.isAndroid) {
      return 'https://stg-caback.popoyan.com.gt/api';
    } else {
      return 'https://stg-caback.popoyan.com.gt/api';
    }
  }
}

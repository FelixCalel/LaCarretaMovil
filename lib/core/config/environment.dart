
class Environment {
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: '',
  );

  static String get apiBaseUrl {
    if (apiUrl.isEmpty) {
      throw Exception(
        '⚠️ ERROR CRÍTICO: No se encontró la URL del servidor. '
        'Asegúrate de ejecutar o compilar la app pasando el archivo de variables: '
        '--dart-define-from-file=env.json',
      );
    }
    
    return apiUrl;
  }
}

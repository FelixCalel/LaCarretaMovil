import 'package:flutter/material.dart';

class AppTheme {
  // --- COLORES BRAND LA CARRETA ---
  static const Color primaryColor = Color(0xFF025205); // Verde principal oscuro
  static const Color primaryLightColor = Color(0xFF05A60A); // Verde secundario / brillante
  static const Color primaryDarkColor = Color(0xFF013603); // Verde muy oscuro
  
  // Colores para Modo Claro
  static const Color lightBackgroundColor = Color(0xFFF4F6F8);
  static const Color lightCardColor = Colors.white;
  static const Color lightTextPrimary = Color(0xFF1E293B);
  static const Color lightTextSecondary = Color(0xFF64748B);

  // Colores para Modo Oscuro
  static const Color darkBackgroundColor = Color(0xFF0F172A); // Slate muy oscuro
  static const Color darkCardColor = Color(0xFF1E293B); // Slate oscuro
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // Colores de Estados (Comunes)
  static const Color accentColor = Color(0xFF3B82F6); 
  static const Color successColor = Color(0xFF10B981); 
  static const Color warningColor = Color(0xFFF59E0B); 
  static const Color errorColor = Color(0xFFEF4444); 

  // --- TAMAÑO DE LETRAS ---
  static const double fontSizeTitleLarge = 24.0;
  static const double fontSizeTitleMedium = 18.0;
  static const double fontSizeBodyLarge = 16.0;
  static const double fontSizeBodyMedium = 14.0;
  static const double fontSizeBodySmall = 12.0;

  // --- TAMAÑO DE ICONOS ---
  static const double iconSizeLarge = 32.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeSmall = 18.0;

  // --- ALTURAS, ANCHOS Y MÁRGENES (DIMENSIONES) ---
  static const double borderRadiusCard = 16.0;
  static const double borderRadiusButton = 12.0;
  static const double defaultPadding = 16.0;
  static const double defaultMargin = 12.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;

  // --- TEMA CLARO ---
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: lightBackgroundColor,
      cardColor: lightCardColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: primaryLightColor,
        surface: lightBackgroundColor,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontSize: fontSizeTitleMedium,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontSize: fontSizeTitleLarge,
          fontWeight: FontWeight.bold,
          color: lightTextPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: fontSizeTitleMedium,
          fontWeight: FontWeight.bold,
          color: lightTextPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: fontSizeBodyLarge,
          color: lightTextPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: fontSizeBodyMedium,
          color: lightTextSecondary,
        ),
        bodySmall: TextStyle(
          fontSize: fontSizeBodySmall,
          color: lightTextSecondary,
        ),
      ),
      cardTheme: CardThemeData(
        color: lightCardColor,
        elevation: 3.0,
        margin: const EdgeInsets.only(bottom: defaultMargin),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusCard),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 24.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusButton),
          ),
          textStyle: const TextStyle(
            fontSize: fontSizeBodyLarge,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // --- TEMA OSCURO ---
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryLightColor,
      scaffoldBackgroundColor: darkBackgroundColor,
      cardColor: darkCardColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryLightColor,
        primary: primaryLightColor,
        secondary: primaryColor,
        surface: darkBackgroundColor,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkCardColor,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontSize: fontSizeTitleMedium,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontSize: fontSizeTitleLarge,
          fontWeight: FontWeight.bold,
          color: darkTextPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: fontSizeTitleMedium,
          fontWeight: FontWeight.bold,
          color: darkTextPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: fontSizeBodyLarge,
          color: darkTextPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: fontSizeBodyMedium,
          color: darkTextSecondary,
        ),
        bodySmall: TextStyle(
          fontSize: fontSizeBodySmall,
          color: darkTextSecondary,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkCardColor,
        elevation: 3.0,
        margin: const EdgeInsets.only(bottom: defaultMargin),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusCard),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryLightColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 24.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusButton),
          ),
          textStyle: const TextStyle(
            fontSize: fontSizeBodyLarge,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

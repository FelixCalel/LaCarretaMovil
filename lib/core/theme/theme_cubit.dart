import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('theme_mode');
    if (themeIndex != null) {
      emit(ThemeMode.values[themeIndex]);
    }
  }

  Future<void> toggleTheme(BuildContext context) async {
    final currentMode = state;
    ThemeMode newMode;

    if (currentMode == ThemeMode.system) {
      final brightness = MediaQuery.of(context).platformBrightness;
      newMode = brightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
    } else {
      newMode = currentMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    }

    emit(newMode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', newMode.index);
  }
}

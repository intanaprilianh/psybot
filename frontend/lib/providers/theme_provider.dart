import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeKey = 'psybot_theme';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

Future<ThemeMode> loadThemePreference() async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString(_kThemeKey);
  return saved == 'dark' ? ThemeMode.dark : ThemeMode.light;
}

Future<void> saveThemePreference(ThemeMode mode) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kThemeKey, mode == ThemeMode.dark ? 'dark' : 'light');
}

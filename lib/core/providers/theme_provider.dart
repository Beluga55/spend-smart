import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  final box = Hive.box('settings');
  return ThemeNotifier(box);
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  final Box _box;

  ThemeNotifier(this._box) : super(ThemeMode.light) {
    _loadTheme();
  }

  void _loadTheme() {
    final isDark = _box.get('isDarkMode', defaultValue: false);
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggleTheme() async {
    final newMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await _box.put('isDarkMode', newMode == ThemeMode.dark);
    state = newMode;
  }

  bool get isDarkMode => state == ThemeMode.dark;
}
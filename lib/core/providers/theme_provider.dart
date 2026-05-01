import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

enum ThemeStyle { defaultTheme, catTheme }

class ThemeState {
  final ThemeMode mode;
  final ThemeStyle style;
  const ThemeState(this.mode, this.style);
}

final themeStateProvider =
    StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier(Hive.box('settings'));
});

/// Convenience: just the ThemeMode, for MaterialApp.themeMode
final themeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(themeStateProvider).mode;
});

/// Convenience: just the ThemeStyle
final themeStyleProvider = Provider<ThemeStyle>((ref) {
  return ref.watch(themeStateProvider).style;
});

class ThemeNotifier extends StateNotifier<ThemeState> {
  final Box _box;

  ThemeNotifier(this._box)
      : super(const ThemeState(ThemeMode.light, ThemeStyle.defaultTheme)) {
    _load();
  }

  void _load() {
    final isDark = _box.get('isDarkMode', defaultValue: false) as bool;
    final styleStr = _box.get('themeStyle', defaultValue: 'default') as String;
    final style =
        styleStr == 'cat' ? ThemeStyle.catTheme : ThemeStyle.defaultTheme;
    state = ThemeState(isDark ? ThemeMode.dark : ThemeMode.light, style);
  }

  Future<void> setTheme(ThemeStyle style, bool isDark) async {
    await _box.put('isDarkMode', isDark);
    await _box.put('themeStyle', style == ThemeStyle.catTheme ? 'cat' : 'default');
    state = ThemeState(isDark ? ThemeMode.dark : ThemeMode.light, style);
  }

  Future<void> toggleTheme() async {
    await setTheme(state.style, state.mode != ThemeMode.dark);
  }

  bool get isDarkMode => state.mode == ThemeMode.dark;
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final box = Hive.box('settings');
  return LocaleNotifier(box);
});

class LocaleNotifier extends StateNotifier<Locale> {
  final Box _box;
  
  LocaleNotifier(this._box) : super(const Locale('en')) {
    _loadLocale();
  }

  void _loadLocale() {
    final languageCode = _box.get('languageCode', defaultValue: 'en');
    state = Locale(languageCode);
  }

  Future<void> setLocale(String languageCode) async {
    await _box.put('languageCode', languageCode);
    state = Locale(languageCode);
  }
}

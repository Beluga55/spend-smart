import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

enum FontFamily { sora, fredoka, comfortaa }

class FontNotifier extends StateNotifier<FontFamily> {
  final Box _box;

  FontNotifier(this._box) : super(FontFamily.sora) {
    _load();
  }

  void _load() {
    final fontStr = _box.get('fontFamily', defaultValue: 'sora') as String;
    state = fontStr == 'fredoka'
        ? FontFamily.fredoka
        : fontStr == 'comfortaa'
        ? FontFamily.comfortaa
        : FontFamily.sora;
  }

  Future<void> setFont(FontFamily font) async {
    await _box.put(
      'fontFamily',
      font == FontFamily.fredoka
          ? 'fredoka'
          : font == FontFamily.comfortaa
          ? 'comfortaa'
          : 'sora',
    );
    state = font;
  }
}

final fontFamilyProvider = StateNotifierProvider<FontNotifier, FontFamily>((
  ref,
) {
  return FontNotifier(Hive.box('settings'));
});

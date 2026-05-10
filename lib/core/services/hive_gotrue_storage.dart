import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Hive-backed [supabase.GotrueAsyncStorage] for PKCE code verifier storage.
class HiveGotrueStorage extends supabase.GotrueAsyncStorage {
  static const String _boxName = 'supabase_auth';
  static const String _pkcePrefix = 'pkce_';

  Box<String>? _box;

  Future<Box<String>> _ensureBox() async {
    final box = _box;
    if (box != null && box.isOpen) return box;
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<String>(_boxName);
    } else {
      _box = Hive.box<String>(_boxName);
    }
    return _box!;
  }

  @override
  Future<String?> getItem({required String key}) async {
    final box = await _ensureBox();
    return box.get('$_pkcePrefix$key');
  }

  @override
  Future<void> removeItem({required String key}) async {
    final box = await _ensureBox();
    await box.delete('$_pkcePrefix$key');
  }

  @override
  Future<void> setItem({required String key, required String value}) async {
    final box = await _ensureBox();
    await box.put('$_pkcePrefix$key', value);
  }
}

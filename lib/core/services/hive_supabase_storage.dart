import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Hive-backed [supabase.LocalStorage] for persisting Supabase auth sessions.
///
/// Replaces the default [supabase.SharedPreferencesLocalStorage] to avoid
/// Android Auto Backup corruption of SharedPreferences on sideloaded updates.
class HiveSupabaseStorage extends supabase.LocalStorage {
  static const String _boxName = 'supabase_auth';
  static const String _sessionKey = 'persisted_session';

  Box<String>? _box;

  @override
  Future<void> initialize() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<String>(_boxName);
    } else {
      _box = Hive.box<String>(_boxName);
    }
  }

  @override
  Future<bool> hasAccessToken() async {
    final box = _box;
    if (box == null) return false;
    return box.containsKey(_sessionKey);
  }

  @override
  Future<String?> accessToken() async {
    final box = _box;
    if (box == null) return null;
    return box.get(_sessionKey);
  }

  @override
  Future<void> removePersistedSession() async {
    final box = _box;
    if (box == null) return;
    await box.delete(_sessionKey);
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    final box = _box;
    if (box == null) return;
    await box.put(_sessionKey, persistSessionString);
  }
}

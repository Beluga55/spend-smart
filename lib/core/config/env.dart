import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralised environment configuration loaded from `.env`.
///
/// Secrets are read at runtime from the bundled `.env` asset so they
/// never appear in source code.  Keep `.env` out of version control
/// (it is listed in `.gitignore`).  Copy `.env.example` to `.env` and
/// fill in your real keys before building.
///
/// **Security note:**  The `.env` file is still bundled into the APK as
/// a Flutter asset.  It keeps secrets out of *git*, but anyone with the
/// APK can still extract them.  For production-grade security use
/// `--dart-define` or a remote config service instead.
class Env {
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    try {
      await dotenv.load(fileName: '.env');
      _loaded = true;
    } catch (e) {
      debugPrint('[Env] dotenv.load failed ($e), trying rootBundle fallback...');
      // flutter_dotenv's file loader can fail in release APKs on Android.
      // Fall back to rootBundle which is more reliable.
      try {
        final content = await rootBundle.loadString('.env');
        final map = <String, String>{};
        for (final line in content.split('\n')) {
          final trimmed = line.trim();
          if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
          final idx = trimmed.indexOf('=');
          if (idx == -1) continue;
          final key = trimmed.substring(0, idx).trim();
          final value = trimmed.substring(idx + 1).trim();
          map[key] = value;
        }
        dotenv.testLoad(mergeWith: map);
        _loaded = true;
        debugPrint('[Env] Loaded ${map.length} keys via rootBundle.');
      } catch (fallbackErr) {
        debugPrint('[Env] rootBundle fallback also failed: $fallbackErr');
        // Allow the app to continue with empty values so that CI/build
        // pipelines that don't have a .env file don't crash.
      }
    }
  }

  static String _get(String key, {String fallback = ''}) {
    return dotenv.env[key] ?? fallback;
  }

  static String get supabaseUrl => _get('SUPABASE_URL');
  static String get supabaseAnonKey => _get('SUPABASE_ANON_KEY');
  static String get googleWebClientId => _get('GOOGLE_WEB_CLIENT_ID');
  static String get geminiApiKey => _get('GEMINI_API_KEY');
  static String get nvidiaApiKey => _get('NVIDIA_API_KEY');
}

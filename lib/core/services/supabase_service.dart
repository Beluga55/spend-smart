import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:mobile_expense_tracker/core/constants/app_constants.dart';
import 'hive_supabase_storage.dart';
import 'hive_gotrue_storage.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthState {
  final AuthStatus status;
  final supabase.User? user;
  final String? error;

  const AuthState({this.status = AuthStatus.initial, this.user, this.error});

  bool get isAnonymous => user?.isAnonymous ?? false;
  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null && !isAnonymous;
}

class SupabaseService {
  static supabase.SupabaseClient get client =>
      supabase.Supabase.instance.client;

  static Future<void> initialize() async {
    await _migrateFromSharedPreferences();
    await supabase.Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
      authOptions: supabase.FlutterAuthClientOptions(
        localStorage: HiveSupabaseStorage(),
        pkceAsyncStorage: HiveGotrueStorage(),
      ),
    );
  }

  static Future<supabase.User> signInAnonymously() async {
    final response = await client.auth.signInAnonymously();
    return response.user!;
  }

  static Future<void> linkEmail(String email) async {
    await client.auth.signInWithOtp(email: email, shouldCreateUser: false);
  }

  static Future<supabase.User?> verifyOtp(String email, String token) async {
    final response = await client.auth.verifyOTP(
      email: email,
      token: token,
      type: supabase.OtpType.email,
    );
    return response.user;
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// Sign in with Google using native Android/iOS flow,
  /// then authenticate with Supabase via ID token.
  static Future<supabase.AuthResponse> signInWithGoogle() async {
    try {
      // google_sign_in 7.x: authenticate() returns the account directly
      final googleUser = await GoogleSignIn.instance.authenticate();

      final idToken = googleUser.authentication.idToken;
      if (idToken == null) {
        throw Exception('No ID token received from Google');
      }

      // In 7.x, accessToken requires a separate authorization call
      final authorization = await googleUser.authorizationClient
          .authorizationForScopes(['email']);
      final accessToken = authorization?.accessToken;

      final response = await client.auth.signInWithIdToken(
        provider: supabase.OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      return response;
    } catch (e) {
      debugPrint('[Google Sign-In] Error: $e');
      rethrow;
    }
  }

  /// Disconnect the Google account by signing out and
  /// reverting to a fresh anonymous session.
  static Future<void> unlinkGoogle() async {
    // signOut() alone leaves cached credentials in Google Play Services,
    // which can cause "reauth failed" on the next authenticate() call.
    // disconnect() revokes access and fully clears the cache.
    try {
      await GoogleSignIn.instance.disconnect();
    } catch (_) {}
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}

    // Sign out locally - clears in-memory session AND local storage
    try {
      await client.auth.signOut(scope: supabase.SignOutScope.local);
    } catch (_) {}
    // Also nuke Hive auth box as backup
    await _clearAuthHiveBox();
  }

  static supabase.User? get currentUser => client.auth.currentUser;

  static Future<void> refreshSession() async {
    try {
      await client.auth.refreshSession();
      final response = await client.auth.getUser();
      if (response.user != null) {
        final email = response.user!.email;
        final isAnon = response.user!.isAnonymous;
        print('Session refreshed - email: $email, isAnonymous: $isAnon');
      }
    } catch (e) {
      print('Session refresh failed, signing in anonymously: $e');
      try {
        await client.auth.signInAnonymously();
      } catch (_) {}
    }
  }

  static Future<void> forceRefreshAuth() async {
    // Clear Hive auth box to remove any persisted session
    await _clearAuthHiveBox();
    // Also tell the GoTrue client to sign out locally (no network call)
    // This clears the in-memory session so it won't be re-persisted
    try {
      await client.auth.signOut(scope: supabase.SignOutScope.local);
    } catch (_) {}
  }

  /// One-time migration: move the existing Supabase session from
  /// SharedPreferences to the new Hive-backed storage, then clean up
  /// SharedPreferences so stale keys don't interfere.
  static Future<void> _migrateFromSharedPreferences() async {
    final settingsBox = Hive.box('settings');
    const migrationFlag = 'supabase_auth_migrated_to_hive';
    if (settingsBox.get(migrationFlag, defaultValue: false) == true) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final url = AppConstants.supabaseUrl;
      final hostFirstSegment = Uri.parse(url).host.split('.').first;
      final sessionKey = 'sb-$hostFirstSegment-auth-token';

      // 1. Migrate existing session into Hive so Supabase can recover it
      final oldSession = prefs.getString(sessionKey);
      if (oldSession != null && oldSession.isNotEmpty) {
        const boxName = 'supabase_auth';
        final authBox = Hive.isBoxOpen(boxName)
            ? Hive.box<String>(boxName)
            : await Hive.openBox<String>(boxName);
        await authBox.put('persisted_session', oldSession);
      }

      // 2. Delete old SharedPreferences keys so they never conflict again
      await prefs.remove(sessionKey);
      await prefs.remove('supabase.auth.token-code-verifier');
      await prefs.remove('SUPABASE_PERSIST_SESSION_KEY');
    } catch (_) {
      // ignore
    }

    await settingsBox.put(migrationFlag, true);
  }

  static Future<void> _clearAuthHiveBox() async {
    try {
      const boxName = 'supabase_auth';
      if (Hive.isBoxOpen(boxName)) {
        await Hive.box<String>(boxName).clear();
      } else {
        final box = await Hive.openBox<String>(boxName);
        await box.clear();
      }
    } catch (_) {}
  }

  static Stream<AuthState> get authStateChanges {
    return client.auth.onAuthStateChange.map((event) {
      final user = event.session?.user;
      if (user == null) {
        return const AuthState(status: AuthStatus.unauthenticated);
      }
      return AuthState(status: AuthStatus.authenticated, user: user);
    });
  }
}

final authStateProvider = StreamProvider<AuthState>((ref) {
  return SupabaseService.authStateChanges;
});

final supabaseClientProvider = Provider<supabase.SupabaseClient>((ref) {
  return SupabaseService.client;
});

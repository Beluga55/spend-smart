import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:mobile_expense_tracker/core/constants/app_constants.dart';

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
    await supabase.Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
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
  }

  /// Disconnect the Google account by signing out and
  /// reverting to a fresh anonymous session.
  static Future<void> unlinkGoogle() async {
    await GoogleSignIn.instance.signOut();
    // Sign out locally - clears in-memory session AND local storage
    try {
      await client.auth.signOut(scope: supabase.SignOutScope.local);
    } catch (_) {}
    // Also nuke SharedPreferences as backup
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
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
    // Use Supabase's own internal storage to remove the session
    // This is the same mechanism Supabase uses to persist/recover sessions
    final prefs = await SharedPreferences.getInstance();
    // Remove all keys - covers any possible key format
    await prefs.clear();
    // Also tell the GoTrue client to sign out locally (no network call)
    // This clears the in-memory session so it won't be re-persisted
    try {
      await client.auth.signOut(scope: supabase.SignOutScope.local);
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

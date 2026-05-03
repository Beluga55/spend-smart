import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();
  static const String _settingsKey = 'biometricEnabled';

  static bool isEnabled() {
    final box = Hive.box('settings');
    return box.get(_settingsKey, defaultValue: false) as bool;
  }

  static Future<void> setEnabled(bool value) async {
    final box = Hive.box('settings');
    await box.put(_settingsKey, value);
  }

  static Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  static Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> authenticate({
    required String localizedReason,
    bool stickyAuth = true,
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          stickyAuth: stickyAuth,
          biometricOnly: false,
          useErrorDialogs: true,
        ),
      );
    } catch (e) {
      debugPrint('Biometric auth error: $e');
      return false;
    }
  }
}

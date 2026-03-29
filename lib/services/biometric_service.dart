import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  // Android: encryptedSharedPreferences adds hardware-backed encryption
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _accessKey  = 'bio_access_token';
  static const _refreshKey = 'bio_refresh_token';
  static const _enabledKey = 'bio_enabled';

  // ─────────────────────────────────────────────
  // AVAILABILITY CHECKS
  // ─────────────────────────────────────────────

  /// True if the device hardware supports biometrics AND has enrolled biometrics.
  static Future<bool> isAvailable() async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      if (!isSupported) return false;

      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) return false;

      final enrolled = await _auth.getAvailableBiometrics();
      return enrolled.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// True if the user has previously opted in to biometric login.
  static Future<bool> isEnabled() async {
    try {
      return (await _storage.read(key: _enabledKey)) == 'true';
    } catch (_) {
      return false;
    }
  }

  /// True if biometrics is available AND the user has enabled it.
  static Future<bool> isReadyToUse() async {
    return await isAvailable() && await isEnabled();
  }

  // ─────────────────────────────────────────────
  // AUTHENTICATE
  // ─────────────────────────────────────────────

  /// Triggers the system biometric prompt.
  /// Returns true only on successful biometric match.
  static Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Use your fingerprint or face to login',
        options: const AuthenticationOptions(
          biometricOnly: true,    // no PIN/pattern fallback
          stickyAuth: true,       // survive app backgrounding
          useErrorDialogs: true,  // show system error dialogs
        ),
      );
    } catch (_) {
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // TOKEN STORAGE — called only after user opts in
  // ─────────────────────────────────────────────

  /// Saves tokens and marks biometric login as enabled.
  static Future<void> enableAndSaveTokens({
    required String access,
    required String refresh,
  }) async {
    await _storage.write(key: _accessKey,  value: access);
    await _storage.write(key: _refreshKey, value: refresh);
    await _storage.write(key: _enabledKey, value: 'true');
  }

  static Future<String?> getAccessToken() async {
    try { return await _storage.read(key: _accessKey);  } catch (_) { return null; }
  }

  static Future<String?> getRefreshToken() async {
    try { return await _storage.read(key: _refreshKey); } catch (_) { return null; }
  }

  // ─────────────────────────────────────────────
  // CLEAR — call on logout or session expiry
  // ─────────────────────────────────────────────

  static Future<void> clear() async {
    try { await _storage.deleteAll(); } catch (_) {}
  }
}
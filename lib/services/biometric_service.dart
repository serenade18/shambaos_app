import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../l10n/tr.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // Keys are scoped per user — no cross-user token bleed
  static String _accessKey(String userId)  => 'bio_access_$userId';
  static String _refreshKey(String userId) => 'bio_refresh_$userId';
  static String _enabledKey(String userId) => 'bio_enabled_$userId';

  // Tracks which user is currently tied to biometric login on this device
  static const _currentUserKey = 'bio_current_user';

  // ─────────────────────────────────────────────
  // AVAILABILITY
  // ─────────────────────────────────────────────

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

  /// Is biometric login enabled for this specific user?
  static Future<bool> isEnabledForUser(String userId) async {
    try {
      return (await _storage.read(key: _enabledKey(userId))) == 'true';
    } catch (_) {
      return false;
    }
  }

  /// Is biometric hardware ready AND enabled for this specific user?
  static Future<bool> isReadyForUser(String userId) async {
    return await isAvailable() && await isEnabledForUser(userId);
  }

  /// Returns the userId that last enabled biometric login on this device.
  /// Used on the login screen before the user types their email.
  static Future<String?> getCurrentBiometricUser() async {
    try {
      return await _storage.read(key: _currentUserKey);
    } catch (_) {
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // AUTHENTICATE
  // ─────────────────────────────────────────────

  static Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Use your fingerprint or face to login'.tr,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // TOKEN STORAGE — scoped to userId
  // ─────────────────────────────────────────────

  /// Call this only after the user explicitly opts in.
  static Future<void> enableForUser({
    required String userId,
    required String access,
    required String refresh,
  }) async {
    await _storage.write(key: _accessKey(userId),  value: access);
    await _storage.write(key: _refreshKey(userId), value: refresh);
    await _storage.write(key: _enabledKey(userId), value: 'true');
    // Record who owns the biometric session on this device
    await _storage.write(key: _currentUserKey,     value: userId);
  }

  /// Call this on every successful password login to keep tokens fresh.
  static Future<void> refreshTokensForUser({
    required String userId,
    required String access,
    required String refresh,
  }) async {
    final enabled = await isEnabledForUser(userId);
    if (!enabled) return; // only update if they opted in
    await _storage.write(key: _accessKey(userId),  value: access);
    await _storage.write(key: _refreshKey(userId), value: refresh);
  }

  static Future<String?> getAccessToken(String userId) async {
    try { return await _storage.read(key: _accessKey(userId));  } catch (_) { return null; }
  }

  static Future<String?> getRefreshToken(String userId) async {
    try { return await _storage.read(key: _refreshKey(userId)); } catch (_) { return null; }
  }

  // ─────────────────────────────────────────────
  // DISABLE — only clears this user's biometric data
  // ─────────────────────────────────────────────

  static Future<void> disableForUser(String userId) async {
    try {
      await _storage.delete(key: _accessKey(userId));
      await _storage.delete(key: _refreshKey(userId));
      await _storage.delete(key: _enabledKey(userId));
      // Clear current user pointer only if it was this user
      final current = await _storage.read(key: _currentUserKey);
      if (current == userId) {
        await _storage.delete(key: _currentUserKey);
      }
    } catch (_) {}
  }

  /// Nuclear option — wipes everything (use on full logout/uninstall).
  static Future<void> clearAll() async {
    try { await _storage.deleteAll(); } catch (_) {}
  }
}
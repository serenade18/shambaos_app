import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();
  static final FlutterSecureStorage _storage = FlutterSecureStorage();

  /// Check if biometrics are supported and enrolled
  static Future<bool> isAvailable() async {
    final canCheck = await _auth.canCheckBiometrics;
    final isSupported = await _auth.isDeviceSupported();
    return canCheck && isSupported;
  }

  /// Perform biometric authentication
  /// Returns true if auth succeeds
  static Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Authenticate to login',
        biometricOnly: true,
      );
    } catch (e) {
      return false;
    }
  }

  /// Save JWT securely after first login
  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
    await _storage.write(key: 'biometric_enabled', value: 'true');
  }

  /// Retrieve JWT token
  static Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  /// Check if biometric login is enabled
  static Future<bool> isBiometricEnabled() async {
    final enabled = await _storage.read(key: 'biometric_enabled');
    return enabled == 'true';
  }

  /// Clear saved JWT (optional, e.g., on logout)
  static Future<void> clear() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'biometric_enabled');
  }
}
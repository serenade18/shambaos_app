import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
import '../../services/biometric_service.dart';
import '../../l10n/tr.dart';

class AuthService {
  static const String _appVersion = '1.0.0';

  // ─────────────────────────────────────────────
  // DEVICE — sent with every sign-in. The API binds tokens to it, so the
  // install id must stay the same for the life of the install.
  // ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> _device() async {
    final prefs = await SharedPreferences.getInstance();
    var installId = prefs.getString('install_id');
    if (installId == null) {
      final rnd = Random.secure();
      installId = List.generate(16, (_) => rnd.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
      await prefs.setString('install_id', installId);
    }

    final platform = kIsWeb
        ? 'web'
        : defaultTargetPlatform == TargetPlatform.iOS
            ? 'ios'
            : 'android';

    return {'install_id': installId, 'platform': platform, 'app_version': _appVersion};
  }

  // Stores the tokens, user and organisation from a sign-in response.
  static Future<void> _saveSignIn(dynamic data) async {
    if (data is! Map) return;

    final access = data['access'];
    final refresh = data['refresh'];
    if (data['user'] is Map) {
      await ApiService.setUser(Map<String, dynamic>.from(data['user']));
    }
    if (access != null) await ApiService.setToken(access.toString());
    if (refresh != null) await ApiService.setRefreshToken(refresh.toString());

    // A farmer signing up gets an organisation of their own; an invited worker
    // joins the inviter's. Requests act on the first one.
    final memberships = data['memberships'];
    if (memberships is List && memberships.isNotEmpty) {
      await ApiService.setOrgId(memberships.first['organisation_id'].toString());
      final currency = memberships.first['currency'];
      if (currency != null) await ApiService.setOrgCurrency(currency.toString());
    }
  }

  // ─────────────────────────────────────────────
  // REGISTER (email and password, as on the web portal)
  // ─────────────────────────────────────────────
  static Future<ApiResponse> register({
    required String name,
    required String phone,
    required String email,
    required String password,
    String? username,
  }) {
    return ApiService.post(
      '/auth/register',
      {
        'name': name,
        'phone': phone,
        'email': email,
        'username': username ?? email.split('@').first,
        'password': password,
        'locale': ApiService.locale,
      },
      requiresAuth: false,
    );
  }

  // ─────────────────────────────────────────────
  // REFRESH TOKEN
  // ─────────────────────────────────────────────
  static Future<ApiResponse> refreshAuthToken({
    required String refresh,
  }) async {
    final response = await ApiService.post(
      '/auth/token/refresh',
      {'refresh': refresh},
      requiresAuth: false,
    );

    // !response.error = request succeeded
    if (!response.error && response.data != null) {
      final token = response.data['access'];
      final newRefresh = response.data['refresh'];

      if (token != null) {
        await ApiService.setToken(token.toString());
        if (newRefresh != null) {
          await ApiService.setRefreshToken(newRefresh.toString());
        }

        final userRes = await getUserInfo();
        if (!userRes.error && userRes.data != null) {
          await ApiService.setUser(userRes.data);
        }
      }
    }

    return response;
  }

  // ─────────────────────────────────────────────
  // VALIDATE TOKEN
  // ─────────────────────────────────────────────
  static Future<bool> validateToken({
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      await ApiService.setToken(accessToken);

      final response = await ApiService.get('/me', requiresAuth: true);

      // !response.error = token is valid
      if (!response.error) return true;
    } catch (_) {}

    try {
      final refreshRes = await refreshAuthToken(refresh: refreshToken);

      // !refreshRes.error = refresh succeeded
      if (!refreshRes.error) return true;
    } catch (_) {}

    return false;
  }

  // ─────────────────────────────────────────────
  // LOGIN (email or username, and password)
  // ─────────────────────────────────────────────
  static Future<ApiResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await ApiService.post(
      '/auth/login',
      {'identifier': email, 'password': password, 'device': await _device()},
      requiresAuth: false,
    );

    // !response.error = login succeeded
    if (!response.error) await _saveSignIn(response.data);

    return response;
  }

  // ─────────────────────────────────────────────
  // USER INFO
  // ─────────────────────────────────────────────
  static Future<ApiResponse> getUserInfo() {
    return ApiService.get('/me');
  }

  // ─────────────────────────────────────────────
  // LOGOUT — revokes this device's refresh token, then forgets it locally.
  // With biometric login on, it only locks the app: the session stays on the
  // server and its token stays in secure storage, behind the fingerprint.
  // ─────────────────────────────────────────────
  static Future<void> logout() async {
    final user = await ApiService.getUser();
    final userId = user?['id']?.toString();
    final keepForBiometrics = userId != null && await BiometricService.isEnabledForUser(userId);

    final refresh = ApiService.refreshToken;
    if (refresh != null && !keepForBiometrics) {
      await ApiService.post('/auth/logout', {'refresh': refresh});
    }
    await ApiService.clearAll();
  }

  // ─────────────────────────────────────────────
  // BIOMETRIC LOGIN
  // ─────────────────────────────────────────────

  /// Whether this device can sign in with biometrics right now.
  static Future<bool> canUseBiometricLogin() async {
    final userId = await BiometricService.getCurrentBiometricUser();
    return userId != null && await BiometricService.isReadyForUser(userId);
  }

  /// Is biometric login on for the signed-in user?
  static Future<bool> isBiometricEnabled() async {
    final user = await ApiService.getUser();
    final userId = user?['id']?.toString();
    return userId != null && await BiometricService.isEnabledForUser(userId);
  }

  /// Turns biometric login on for the signed-in user after a fingerprint or face check.
  /// Returns null on success, or why it could not be turned on.
  static Future<String?> enableBiometricLogin() async {
    if (!await BiometricService.isAvailable()) {
      return 'Set up a fingerprint or face unlock on this phone first.'.tr;
    }
    final user = await ApiService.getUser();
    final refresh = ApiService.refreshToken;
    if (user?['id'] == null || refresh == null) return 'Sign in again, then turn this on.'.tr;
    if (!await BiometricService.authenticate()) return 'Biometric check was cancelled.'.tr;

    await BiometricService.enableForUser(
      userId: user!['id'].toString(),
      access: '',
      refresh: refresh,
    );
    return null;
  }

  static Future<void> disableBiometricLogin() async {
    final user = await ApiService.getUser();
    if (user?['id'] != null) await BiometricService.disableForUser(user!['id'].toString());
  }

  /// Signs in with the session kept behind biometrics: checks the fingerprint or
  /// face, then exchanges the stored refresh token for a fresh session.
  static Future<ApiResponse> biometricLogin() async {
    final userId = await BiometricService.getCurrentBiometricUser();
    final refresh = userId == null ? null : await BiometricService.getRefreshToken(userId);
    if (userId == null || refresh == null) {
      return ApiResponse(error: true, message: 'Biometric login is not set up.'.tr, statusCode: 400);
    }
    if (!await BiometricService.authenticate()) {
      return ApiResponse(error: true, message: 'Biometric check was cancelled.'.tr, statusCode: 401);
    }

    final response = await ApiService.post('/auth/token/refresh', {'refresh': refresh}, requiresAuth: false);
    if (response.error || response.data is! Map) {
      // Signed out elsewhere, expired, or the device was revoked: fall back to the phone number.
      if (response.statusCode == 401) await BiometricService.disableForUser(userId);
      return ApiResponse(
        error: true,
        message: response.statusCode == 401
            ? 'Your session has ended. Sign in with your phone number.'.tr
            : response.message ?? 'Could not sign in. Check your connection.'.tr,
        statusCode: response.statusCode,
      );
    }

    final data = response.data as Map;
    await ApiService.setToken(data['access'].toString());
    final me = await ApiService.get('/me');
    if (!me.error && me.data is Map) await ApiService.setUser(Map<String, dynamic>.from(me.data));
    // After the user is known, so the rotated token is kept for the next biometric sign-in.
    if (data['refresh'] != null) await ApiService.setRefreshToken(data['refresh'].toString());

    final orgs = await ApiService.get('/me/organisations');
    final memberships = orgs.data is Map ? orgs.data['memberships'] : null;
    if (memberships is List && memberships.isNotEmpty) {
      await ApiService.setOrgId(memberships.first['organisation_id'].toString());
      final currency = memberships.first['currency'];
      if (currency != null) await ApiService.setOrgCurrency(currency.toString());
    }
    return ApiResponse(error: false, data: me.data, statusCode: 200);
  }

  // ─────────────────────────────────────────────
  // PASSWORD RESET — the API emails a link; the reset itself takes the
  // uid and token from that link.
  // ─────────────────────────────────────────────
  static Future<ApiResponse> forgotPassword({
    required String email,
  }) {
    return ApiService.post(
      '/auth/password/forgot',
      {'email': email, 'locale': ApiService.locale},
      requiresAuth: false,
    );
  }

  static Future<ApiResponse> resetPassword({
    required String uid,
    required String token,
    required String newPassword,
  }) {
    return ApiService.post(
      '/auth/password/reset',
      {'uid': uid, 'token': token, 'password': newPassword},
      requiresAuth: false,
    );
  }

  // ─────────────────────────────────────────────
  // PHONE OTP — REQUEST
  // ─────────────────────────────────────────────
  static Future<ApiResponse> requestOtp({
    required String phone,
  }) async {
    final response = await ApiService.post(
      '/auth/otp/request',
      {'phone': phone, 'locale': ApiService.locale},
      requiresAuth: false,
    );

    // The API answers 202 {phone, expires_in}; the login screen looks for `sent`.
    if (!response.error && response.data is Map) {
      return ApiResponse(
        error: false,
        data: {...response.data as Map, 'sent': true},
        message: response.message,
        statusCode: response.statusCode,
      );
    }
    return response;
  }

  // ─────────────────────────────────────────────
  // PHONE OTP — VERIFY. Signs in, creating the account (and its farm
  // account) the first time a number is used.
  // ─────────────────────────────────────────────
  static Future<ApiResponse> verifyOtp({
    required String phone,
    required String otp,
    String? googleTicket,
  }) async {
    final response = await ApiService.post(
      '/auth/otp/verify',
      {
        'phone': phone,
        'code': otp,
        'locale': ApiService.locale,
        'device': await _device(),
        // Someone new who continued with Google: links that Google account.
        'google_ticket': ?googleTicket,
      },
      requiresAuth: false,
    );

    // !response.error = OTP verified successfully
    if (!response.error) await _saveSignIn(response.data);

    return response;
  }

  // ─────────────────────────────────────────────
  // GOOGLE SIGN-IN. The client IDs come from the server (GET /config/public),
  // where super admins set them in the staff portal; until they do, the
  // button stays hidden. The plugin can only be set up once per run, so a
  // changed ID takes effect the next time the app starts.
  // ─────────────────────────────────────────────
  static const String googleCancelled = 'Google sign-in was cancelled.';
  static ({String web, String ios})? _googleIds;
  static bool _googleInitialized = false;

  static bool get _isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static Future<({String web, String ios})?> _googleClientIds() async {
    if (_googleIds != null) return _googleIds;
    final res = await ApiService.get('/config/public', requiresAuth: false);
    if (res.error || res.data is! Map) return null;
    final web = (res.data['google_web_client_id'] ?? '').toString();
    final ios = (res.data['google_ios_client_id'] ?? '').toString();
    // iPhones need their own client ID as well as the server's.
    if (web.isEmpty || (_isIOS && ios.isEmpty)) return null;
    return _googleIds = (web: web, ios: ios);
  }

  static Future<bool> isGoogleAvailable() async {
    if (kIsWeb) return false;
    return await _googleClientIds() != null;
  }

  /// Signs in with Google. On success the data is either a full sign-in, or
  /// {needs_phone: true, google_ticket, email, name} for someone new, who then
  /// adds their phone number with an SMS code (verifyOtp with the ticket).
  static Future<ApiResponse> googleSignIn() async {
    final ids = await _googleClientIds();
    if (ids == null) {
      return ApiResponse(error: true, message: "Google sign-in isn't available right now.".tr, statusCode: 503);
    }

    String? idToken;
    try {
      if (!_googleInitialized) {
        // serverClientId makes Google issue the ID token for our server, which checks it.
        await GoogleSignIn.instance.initialize(clientId: _isIOS ? ids.ios : null, serverClientId: ids.web);
        _googleInitialized = true;
      }
      final account = await GoogleSignIn.instance.authenticate();
      idToken = account.authentication.idToken;
    } on GoogleSignInException catch (e) {
      final cancelled = e.code == GoogleSignInExceptionCode.canceled;
      return ApiResponse(
        error: true,
        message: cancelled ? googleCancelled : "Google sign-in didn't work. Try again.".tr,
        statusCode: cancelled ? 499 : 400,
      );
    } catch (_) {
      return ApiResponse(error: true, message: "Google sign-in didn't work. Try again.".tr, statusCode: 400);
    }
    if (idToken == null) {
      return ApiResponse(error: true, message: "Google sign-in didn't work. Try again.".tr, statusCode: 400);
    }

    final response = await ApiService.post(
      '/auth/google',
      {'id_token': idToken, 'device': await _device()},
      requiresAuth: false,
    );
    // Our own session keeps them signed in, so let go of Google straight away:
    // the account picker shows again next time, for a shared phone.
    unawaited(GoogleSignIn.instance.signOut());

    if (!response.error && response.data is Map && response.data['needs_phone'] != true) {
      await _saveSignIn(response.data);
    }
    return response;
  }
}

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';

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
    if (access != null) await ApiService.setToken(access.toString());
    if (refresh != null) await ApiService.setRefreshToken(refresh.toString());
    if (data['user'] is Map) {
      await ApiService.setUser(Map<String, dynamic>.from(data['user']));
    }

    // A farmer signing up gets an organisation of their own; an invited worker
    // joins the inviter's. Requests act on the first one.
    final memberships = data['memberships'];
    if (memberships is List && memberships.isNotEmpty) {
      await ApiService.setOrgId(memberships.first['organisation_id'].toString());
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
        'locale': 'en',
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
  // ─────────────────────────────────────────────
  static Future<void> logout() async {
    final refresh = ApiService.refreshToken;
    if (refresh != null) {
      await ApiService.post('/auth/logout', {'refresh': refresh});
    }
    await ApiService.clearAll();
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
      {'email': email, 'locale': 'en'},
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
      {'phone': phone, 'locale': 'en'},
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
  }) async {
    final response = await ApiService.post(
      '/auth/otp/verify',
      {'phone': phone, 'code': otp, 'locale': 'en', 'device': await _device()},
      requiresAuth: false,
    );

    // !response.error = OTP verified successfully
    if (!response.error) await _saveSignIn(response.data);

    return response;
  }
}

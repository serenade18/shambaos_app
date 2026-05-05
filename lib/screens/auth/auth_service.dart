import '../../services/api_service.dart';

class AuthService {

  // ─────────────────────────────────────────────
  // REGISTER
  // ─────────────────────────────────────────────
  static Future<ApiResponse> register({
    required String name,
    required String phone,
    required String email,
    required String password,
    String role = 'farm_admin',
  }) {
    return ApiService.post(
      '/users/',
      {
        'name': name,
        'phone': phone,
        'email': email,
        'role': role,
        'password': password,
      },
      requiresAuth: false,
    );
  }

  // ─────────────────────────────────────────────
  // REFRESH TOKEN (RENAMED)
  // ─────────────────────────────────────────────
  static Future<ApiResponse> refreshAuthToken({
    required String refresh,
  }) async {
    final response = await ApiService.post(
      '/refresh_token/',
      {'refresh': refresh},
      requiresAuth: false,
    );

    if (response.success && response.data != null) {
      final token = response.data['token'] ??
          response.data['access'] ??
          response.data['auth_token'];

      if (token != null) {
        await ApiService.setToken(token.toString());

        // ✅ Reload user after refresh
        final userRes = await getUserInfo();
        if (userRes.success && userRes.data != null) {
          await ApiService.setUser(userRes.data);
        }
      }
    }

    return response;
  }

  // ─────────────────────────────────────────────
  // VALIDATE TOKEN (FIXED)
  // ─────────────────────────────────────────────
  static Future<bool> validateToken({
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      // 1️⃣ Try access token
      await ApiService.setToken(accessToken);

      final response = await ApiService.get(
        '/validate-token/',
        requiresAuth: true,
      );

      if (response.success) return true;
    } catch (e) {
      // Optional: log error
      // print('Access token failed: $e');
    }

    // 2️⃣ Try refresh token
    try {
      final refreshRes = await refreshAuthToken(
        refresh: refreshToken, // ✅ FIXED
      );

      if (refreshRes.success) return true;
    } catch (e) {
      // print('Refresh token failed: $e');
    }

    // 3️⃣ Fully invalid session
    return false;
  }

  // ─────────────────────────────────────────────
  // LOGIN
  // ─────────────────────────────────────────────
  static Future<ApiResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await ApiService.post(
      '/gettoken/',
      {'username': email, 'password': password},
      requiresAuth: false,
    );

    if (response.success && response.data != null) {
      final access = response.data['access'] ??
          response.data['token'] ??
          response.data['auth_token'];

      final refresh = response.data['refresh'];

      if (access != null) {
        await ApiService.setToken(access.toString());
      }

      if (access != null && refresh != null) {
        response.data['access'] = access;
        response.data['refresh'] = refresh;
      }

      final userRes = await getUserInfo();
      if (userRes.success && userRes.data != null) {
        await ApiService.setUser(userRes.data);
      }
    }

    return response;
  }

  // ─────────────────────────────────────────────
  // USER INFO
  // ─────────────────────────────────────────────
  static Future<ApiResponse> getUserInfo() {
    return ApiService.get('/userinfo/');
  }

  // ─────────────────────────────────────────────
  // LOGOUT
  // ─────────────────────────────────────────────
  static void logout() {
    ApiService.clearToken();
  }

  // ─────────────────────────────────────────────
  // PASSWORD RESET
  // ─────────────────────────────────────────────
  static Future<ApiResponse> forgotPassword({
    required String email,
  }) {
    return ApiService.post(
      '/forgot-password/',
      {'email': email},
      requiresAuth: false,
    );
  }

  static Future<ApiResponse> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) {
    return ApiService.post(
      '/reset-password/',
      {
        'email': email,
        'code': code,
        'new_password': newPassword,
      },
      requiresAuth: false,
    );
  }

  // ─────────────────────────────────────────────
  // Add these two methods inside AuthService
  // (in lib/services/auth_service.dart)
  // ─────────────────────────────────────────────

  // PHONE OTP — REQUEST
  static Future<ApiResponse> requestOtp({
    required String phone,
  }) {
    return ApiService.post(
      '/mobile/auth/request-otp/',
      {'phone': phone},
      requiresAuth: false,
    );
  }

  // PHONE OTP — VERIFY (signs in or creates account)
  static Future<ApiResponse> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    final response = await ApiService.post(
      '/mobile/auth/verify-otp/',
      {'phone': phone, 'otp': otp},
      requiresAuth: false,
    );

    if (response.success && response.data != null) {
      final access = response.data['access'];
      final refresh = response.data['refresh'];

      if (access != null) {
        await ApiService.setToken(access.toString());
      }
      if (response.data['user'] != null) {
        await ApiService.setUser(response.data['user']);
      }

      // Persist refresh token if your ApiService supports it
      // await ApiService.setRefreshToken(refresh.toString());
    }

    return response;
  }
}
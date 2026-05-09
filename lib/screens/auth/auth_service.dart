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
  // REFRESH TOKEN
  // ─────────────────────────────────────────────
  static Future<ApiResponse> refreshAuthToken({
    required String refresh,
  }) async {
    final response = await ApiService.post(
      '/refresh_token/',
      {'refresh': refresh},
      requiresAuth: false,
    );

    // !response.error = request succeeded
    if (!response.error && response.data != null) {
      final token = response.data['token'] ??
          response.data['access'] ??
          response.data['auth_token'];

      if (token != null) {
        await ApiService.setToken(token.toString());

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

      final response = await ApiService.get(
        '/validate-token/',
        requiresAuth: true,
      );

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

    // !response.error = login succeeded
    if (!response.error && response.data != null) {
      final access = response.data['access'] ??
          response.data['token'] ??
          response.data['auth_token'];

      final refresh = response.data['refresh'];

      if (access != null) {
        await ApiService.setToken(access.toString());
      }

      if (refresh != null) {
        await ApiService.setRefreshToken(refresh.toString());
      }

      final userRes = await getUserInfo();
      if (!userRes.error && userRes.data != null) {
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
    ApiService.clearAll();
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
  // PHONE OTP — REQUEST
  // ─────────────────────────────────────────────
  static Future<ApiResponse> requestOtp({
    required String phone,
  }) {
    return ApiService.post(
      '/mobile/auth/request-otp/',
      {'phone': phone},
      requiresAuth: false,
    );
  }

  // ─────────────────────────────────────────────
  // PHONE OTP — VERIFY
  // ─────────────────────────────────────────────
  static Future<ApiResponse> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    final response = await ApiService.post(
      '/mobile/auth/verify-otp/',
      {'phone': phone, 'otp': otp},
      requiresAuth: false,
    );

    // !response.error = OTP verified successfully
    if (!response.error && response.data != null) {
      final access = response.data['access'];
      final refresh = response.data['refresh'];

      if (access != null) {
        await ApiService.setToken(access.toString());
      }
      if (refresh != null) {
        await ApiService.setRefreshToken(refresh.toString());
      }
      if (response.data['user'] != null) {
        await ApiService.setUser(response.data['user']);
      }
    }

    return response;
  }
}
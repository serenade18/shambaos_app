import '../../services/api_service.dart';

// ════════════════════════════════════════════════════════════════
//  auth_service.dart  —  Auth endpoints only
//  Uses ApiService base client. All other feature services
//  follow this exact same pattern.
// ════════════════════════════════════════════════════════════════

class AuthService {
  
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

  static Future<ApiResponse> refreshToken({
    required String refresh,
  }) async {
    final response = await ApiService.post(
      '/refresh_token/',
      {'refresh': refresh,},
      requiresAuth: false,
    );

    if (response.success && response.data != null) {
      final token = response.data['token'] ??
          response.data['access'] ??
          response.data['auth_token'];

      if (token != null) {
        await ApiService.setToken(token.toString());

        // ✅ Fetch user immediately after login
        final userRes = await getUserInfo();
        if (userRes.success && userRes.data != null) {
          await ApiService.setUser(userRes.data);
        }
      }
    }

    return response;
  }
  

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
      final token = response.data['token'] ??
          response.data['access'] ??
          response.data['auth_token'];

      if (token != null) {
        await ApiService.setToken(token.toString());

        // ✅ Fetch user immediately after login
        final userRes = await getUserInfo();
        if (userRes.success && userRes.data != null) {
          await ApiService.setUser(userRes.data);
        }
      }
    }

    return response;
  }
  
  static Future<ApiResponse> getUserInfo() {
    return ApiService.get('/userinfo/');
  }

  static void logout() {
    ApiService.clearToken();
  }

  static Future<ApiResponse> forgotPassword({
    required String email,
  }) {
    return ApiService.post(
      '/forgot-password/',
      {
        'email': email,
      },
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

}
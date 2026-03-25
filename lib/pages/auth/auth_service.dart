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

  static Future<ApiResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await ApiService.post(
      '/gettoken/',
      {'username': email, 'password': password},
      requiresAuth: false,
    );

    // Auto-store token on successful login
    if (response.success && response.data != null) {
      final token = response.data['token'] ??
          response.data['access'] ??      // JWT access token
          response.data['auth_token'];    // DRF TokenAuth
      if (token != null) {
        ApiService.setToken(token.toString());
      }
    }

    return response;
  }

  static void logout() {
    ApiService.clearToken();
  }
}
import '../../services/api_service.dart';

class ProfileService {
  static Future<ApiResponse> getProfile() async {
    return ApiService.get('/me', requiresAuth: true);
  }

  // The username is fixed once the account exists, so it isn't sent.
  static Future<ApiResponse> updateProfile({
    required String name,
    required String email,
    required String phone,
    required String username,
  }) async {
    final response = await ApiService.patch('/me', {
      'name': name,
      'email': email,
      'phone': phone,
    }, requiresAuth: true);

    if (!response.error && response.data is Map) {
      await ApiService.setUser(Map<String, dynamic>.from(response.data));
    }
    return response;
  }

  // Someone who has only signed in with SMS codes has no password yet:
  // they leave oldPassword empty to set their first one.
  static Future<ApiResponse> updatePassword(
      String oldPassword, String newPassword) async {
    return ApiService.post('/me/password', {
      'current_password': oldPassword,
      'new_password': newPassword,
    });
  }
}

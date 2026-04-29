import '../../services/api_service.dart';

class ProfileService {
  static Future<ApiResponse> getProfile() async {
    return ApiService.get('/userinfo/', requiresAuth: true);
  }

  static Future<ApiResponse> updateProfile({
    required String name,
    required String email,
    required String phone,
    required String username,
  }) async {
    return ApiService.put('/userinfo/', {
      'name': name,
      'email': email,
      'phone': phone,
      'username': username,
    }, requiresAuth: true);
  }

  static Future<ApiResponse> updatePassword(
      String oldPassword, String newPassword) async {
    return ApiService.post('/user/change-password/', {
      'old_password': oldPassword,
      'new_password': newPassword,
    });
  }

  static Future<ApiResponse> setNotification() async {
    return ApiService.get('/notification-prefs/', requiresAuth: true);
  }

  /// Sends only the single changed key as a PATCH.
  /// e.g. patchNotification('leave_requests', true)
  /// Payload → { "leave_requests": true }
  static Future<ApiResponse> patchNotification(String key, bool value) async {
    return ApiService.patch(
      '/notification-prefs/update/',
      {key: value},
      requiresAuth: true,
    );
  }
}
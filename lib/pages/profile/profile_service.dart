import '../../services/api_service.dart';

class ProfileService {
  // Fetch the current user profile
  static Future<ApiResponse> getProfile() async {
    return ApiService.get('/userinfo/', requiresAuth: true,); // adjust endpoint to your backend
  }

  // Update profile info
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
    }, 
      requiresAuth: true,
    );
  }

  // Update password
  static Future<ApiResponse> updatePassword(String oldPassword, String newPassword) async {
    return ApiService.post('/user/change-password/', {
      'old_password': oldPassword,
      'new_password': newPassword,
    });
  }
}
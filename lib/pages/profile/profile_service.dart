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

  // Get Notifications
  static Future<ApiResponse> setNotification() async {
    return ApiService.get('/notification-prefs/', requiresAuth: true,);
  }

  // Update notification preferences
  static Future<ApiResponse> updateNotification({
    required bool lowStockAlerts,
    required bool leaveRequests,
    required bool paymentReminders,
    required bool healthReminders,
    required bool systemUpdates,
  }) async {
    return ApiService.put('/notification-prefs/', {
      'low_stock_alerts': lowStockAlerts,
      'leave_requests': leaveRequests,
      'payment_reminders': paymentReminders,
      'health_reminders': healthReminders,
      'system_updates': systemUpdates,
    }, requiresAuth: true);
  }
}

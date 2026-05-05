import '../../services/api_service.dart';

class CustomerService {
  // FETCH ALL CUSTOMERS
  static Future<ApiResponse> getCustomers() async {
    final response = await ApiService.get(
      '/customers/',
      requiresAuth: true,
    );

    return response;
  }

  //CREATE CUSTOMER
  static Future<ApiResponse> createCustomer({
    required String name,
    String? email,
    required String phone,
    String? town,
  }) async {
    final payload = {
      'name': name,
      'phone': phone,
      if (email != null && email.isNotEmpty) 'email': email,
      if (town != null && town.isNotEmpty) 'town': town,
    };

    return ApiService.post(
      '/customers/',
      payload,
      requiresAuth: true,
    );
  }

  // UPDATE CUSTOMER (PATCH — not PUT)
  static Future<ApiResponse> updateCustomer({
    required int id,
    required Map<String, dynamic> updates,
  }) async {
    return ApiService.patch(
      '/customers/$id/',   // 👈 IMPORTANT
      updates,
      requiresAuth: true,
    );
  }

  //DELETE CUSTOMER
  static Future<ApiResponse> deleteCustomer(int id) async {
    return ApiService.delete(
      '/customers/$id/',
      requiresAuth: true,
    );
  }
}
import '../../services/api_service.dart';

class CustomerService {
  // FETCH ALL CUSTOMERS — the API pages them as {next, previous, results}.
  static Future<ApiResponse> getCustomers() async {
    final response = await ApiService.get(
      '/customers',
      requiresAuth: true,
    );

    if (!response.error && response.data is Map) {
      return ApiResponse(
        error: false,
        data: response.data['results'] ?? [],
        message: response.message,
        statusCode: response.statusCode,
      );
    }
    return response;
  }

  // CREATE CUSTOMER — the API keeps a name and a phone number.
  static Future<ApiResponse> createCustomer({
    required String name,
    required String phone,
  }) async {
    return ApiService.post(
      '/customers',
      {'name': name, 'phone': phone},
      requiresAuth: true,
    );
  }

  // UPDATE CUSTOMER (PATCH — name and/or phone). Ids are UUIDs.
  static Future<ApiResponse> updateCustomer({
    required String id,
    required Map<String, dynamic> updates,
  }) async {
    return ApiService.patch(
      '/customers/$id',
      updates,
      requiresAuth: true,
    );
  }
}

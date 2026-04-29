import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiResponse {
  final bool success;
  final dynamic data;
  final String? message;
  final int statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    required this.statusCode,
  });
}

class ApiService {
  // ⚠️ CHANGE THIS depending on your environment
  // static const String baseUrl = 'https://shambaos.linkworldcargo.com/api';
  static const String baseUrl = 'http://192.168.0.100:8000/api';

  static String? _accessToken;
  static String? _refreshToken;

  // ================= INIT =================
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');
  }

  // ================= TOKEN STORAGE =================
  static Future<void> setToken(String token) async {
    _accessToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  static Future<void> setRefreshToken(String token) async {
    _refreshToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('refresh_token', token);
  }

  static Future<void> setUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user));
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('user');
    return data != null ? jsonDecode(data) : null;
  }

  static Future<void> clearToken() async {
    _accessToken = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }

  static Future<void> clearRefreshToken() async {
    _refreshToken = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('refresh_token');
  }

  static Future<void> clearAll() async {
    _accessToken = null;
    _refreshToken = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user');
  }

  // ================= HEADERS =================
  static Map<String, String> _headers({bool requiresAuth = true}) {
    return {
      'Content-Type': 'application/json',
      if (requiresAuth && _accessToken != null)
        'Authorization': 'Bearer $_accessToken',
    };
  }

  // ================= CORE REQUEST HANDLER =================
  static Future<ApiResponse> _request(
    Future<http.Response> Function() requestFn, {
    bool requiresAuth = true,
    bool retry = true,
  }) async {
    try {
      final response = await requestFn();
      final statusCode = response.statusCode;

      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = response.body;
      }

      // ✅ SUCCESS
      if (statusCode >= 200 && statusCode < 300) {
        return ApiResponse(
          success: true,
          data: data,
          message: data is Map ? data['message'] : null,
          statusCode: statusCode,
        );
      }

      // 🔄 HANDLE TOKEN EXPIRY (401)
      if (statusCode == 401 && requiresAuth && retry) {
        final refreshed = await _refreshAccessToken();

        if (refreshed) {
          // 🔁 Retry original request once
          return _request(requestFn, requiresAuth: requiresAuth, retry: false);
        }
      }

      // ❌ FAILURE
      return ApiResponse(
        success: false,
        data: data,
        message: data is Map ? data['detail'] ?? data['message'] : null,
        statusCode: statusCode,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: e.toString(),
        statusCode: 500,
      );
    }
  }

  // ================= TOKEN REFRESH =================
  static Future<bool> _refreshAccessToken() async {
    if (_refreshToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': _refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccess = data['access'];

        if (newAccess != null) {
          await setToken(newAccess);
          return true;
        }
      }
    } catch (_) {}

    // ❌ Refresh failed → logout user
    await clearAll();
    return false;
  }

  // ================= HTTP METHODS =================

  static Future<ApiResponse> get(
    String endpoint, {
    bool requiresAuth = true,
  }) {
    return _request(
      () => http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers(requiresAuth: requiresAuth),
      ),
      requiresAuth: requiresAuth,
    );
  }

  static Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) {
    return _request(
      () => http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers(requiresAuth: requiresAuth),
        body: jsonEncode(body),
      ),
      requiresAuth: requiresAuth,
    );
  }

  static Future<ApiResponse> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) {
    return _request(
      () => http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers(requiresAuth: requiresAuth),
        body: jsonEncode(body),
      ),
      requiresAuth: requiresAuth,
    );
  }

  static Future<ApiResponse> patch(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) {
    return _request(
      () => http.patch(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers(requiresAuth: requiresAuth),
        body: jsonEncode(body),
      ),
      requiresAuth: requiresAuth,
    );
  }

  static Future<ApiResponse> delete(
    String endpoint, {
    bool requiresAuth = true,
  }) {
    return _request(
      () => http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers(requiresAuth: requiresAuth),
      ),
      requiresAuth: requiresAuth,
    );
  }
}
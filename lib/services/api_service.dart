import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/tr.dart';
import 'biometric_service.dart';

class ApiResponse {
  // final bool success;
  final bool error;
  final dynamic data;
  final String? message;
  final int statusCode;

  ApiResponse({
    // required this.success,
    required this.error,
    this.data,
    this.message,
    required this.statusCode,
  });
}

class ApiService {
  // Shamba OS Django API. Override per build:
  //   flutter run --dart-define=API_BASE_URL=http://192.168.0.102:8000/api/v1
  // The default reaches runserver on the host from the Android emulator.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.0.101:8000/api/v1',
  );

  static String? _accessToken;
  static String? _refreshToken;
  // The organisation (farm account) requests act on, sent as X-Org-Id.
  static String? _orgId;

  // The language the person chose: en, sw or fr. Sent as Accept-Language, so the
  // server answers in it, and saved on their account, which SMS and emails follow.
  static const Map<String, String> languages = {'en': 'English', 'sw': 'Kiswahili', 'fr': 'Français'};
  static String _locale = 'en';
  static String get locale => _locale;
  // Tells the app to redraw in a newly chosen language.
  static final ValueNotifier<String> language = ValueNotifier('en');

  // ================= INIT =================
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');
    _orgId = prefs.getString('org_id');
    _locale = prefs.getString('locale') ?? 'en';
    language.value = _locale;
  }

  // Kept on sign-out: it belongs to the phone as much as the person.
  static Future<void> setLocale(String code) async {
    if (!languages.containsKey(code)) return;
    _locale = code;
    language.value = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', code);
  }

  static String? get refreshToken => _refreshToken;
  static String? get orgId => _orgId;

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

    // Refresh tokens rotate and the old one is blacklisted, so the copy kept for
    // biometric sign-in must follow every rotation (it is only written if enabled).
    final user = await getUser();
    if (user?['id'] != null) {
      await BiometricService.refreshTokensForUser(
        userId: user!['id'].toString(),
        access: _accessToken ?? '',
        refresh: token,
      );
    }
  }

  static Future<void> setOrgId(String orgId) async {
    _orgId = orgId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('org_id', orgId);
  }

  // The organisation's currency (from its membership), for showing money.
  static Future<void> setOrgCurrency(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('org_currency', currency);
  }

  static Future<String> getOrgCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('org_currency') ?? 'KES';
  }

  static Future<void> setUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user));
    // The account's language wins, e.g. after signing in on a new phone.
    final locale = user['preferred_locale'];
    if (locale is String) await setLocale(locale);
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
    _orgId = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('org_id');
    await prefs.remove('org_currency');
    await prefs.remove('user');
  }

  // ================= HEADERS =================
  static Map<String, String> _headers({bool requiresAuth = true}) {
    return {
      'Content-Type': 'application/json',
      'Accept-Language': _locale,
      if (requiresAuth && _accessToken != null)
        'Authorization': 'Bearer $_accessToken',
      if (requiresAuth && _orgId != null) 'X-Org-Id': _orgId!,
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
          error: false,
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
          return await _request(requestFn, requiresAuth: requiresAuth, retry: false);
        }
      }

      // ❌ FAILURE
      return ApiResponse(
        error: true,
        data: data,
        message: _errorMessage(data),
        statusCode: statusCode,
      );
    } catch (e) {
      return ApiResponse(
        error: true,
        message: e.toString(),
        statusCode: 500,
      );
    }
  }

  // Errors are {code, message, params, fields}; field errors are {field: [messages]}.
  static String? _errorMessage(dynamic data) {
    if (data is! Map) return null;
    final message = data['message'] ?? data['detail'];
    if (message != null) return message.toString();
    final fields = data['fields'] is Map ? data['fields'] as Map : data;
    for (final value in fields.values) {
      if (value is List && value.isNotEmpty) return value.first.toString();
      if (value is String) return value;
    }
    return null;
  }

  // ================= TOKEN REFRESH =================
  static Future<bool> _refreshAccessToken() async {
    if (_refreshToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/token/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': _refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccess = data['access'];
        // Refresh tokens rotate: the old one stops working once used.
        final newRefresh = data['refresh'];

        if (newAccess != null) {
          await setToken(newAccess);
          if (newRefresh != null) await setRefreshToken(newRefresh);
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

  /// Uploads a file as multipart form data (photos for the AI check). The request
  /// is rebuilt on retry, since a multipart body can only be sent once.
  static Future<ApiResponse> postFile(
    String endpoint, {
    required String field,
    required List<int> bytes,
    required String filename,
    Map<String, String> fields = const {},
    Duration timeout = const Duration(seconds: 120),
  }) {
    return _request(() async {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$endpoint'))
        ..headers.addAll(_headers()..remove('Content-Type'))
        ..fields.addAll(fields)
        ..files.add(http.MultipartFile.fromBytes(field, bytes, filename: filename));
      final streamed = await request.send().timeout(timeout);
      return http.Response.fromStream(streamed);
    });
  }

  /// Posts JSON and returns the reply as a stream of text, as the server writes it
  /// (Tulip's answers). An expired session is refreshed once before the stream
  /// starts. Errors come back as an [ApiResponse] with no stream.
  static Future<(Stream<String>?, ApiResponse?)> postStream(String endpoint, Map<String, dynamic> body) async {
    Future<http.StreamedResponse> send() {
      final request = http.Request('POST', Uri.parse('$baseUrl$endpoint'))
        ..headers.addAll(_headers())
        ..body = jsonEncode(body);
      return http.Client().send(request);
    }

    try {
      var response = await send().timeout(const Duration(seconds: 60));
      if (response.statusCode == 401 && await _refreshAccessToken()) {
        response = await send().timeout(const Duration(seconds: 60));
      }
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return (response.stream.transform(utf8.decoder), null);
      }
      final text = await response.stream.bytesToString();
      dynamic data;
      try {
        data = jsonDecode(text);
      } catch (_) {
        data = text;
      }
      return (null, ApiResponse(error: true, data: data, message: _errorMessage(data), statusCode: response.statusCode));
    } catch (e) {
      return (null, ApiResponse(error: true, message: 'No connection. Check your internet and try again.'.tr, statusCode: 0));
    }
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
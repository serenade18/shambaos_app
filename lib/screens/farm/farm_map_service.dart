import '../../services/api_service.dart';
import 'boundary_geo.dart';

/// The calls the farm map makes.
class FarmMapService {
  FarmMapService._();

  static String? _ionToken;

  /// The Cesium ion token for 3D terrain, asked for once ('' when none is set).
  /// GET /config/public needs no sign-in; the portal reads the same value.
  static Future<String> ionToken() async {
    if (_ionToken != null) return _ionToken!;
    final res = await ApiService.get('/config/public', requiresAuth: false);
    if (res.error || res.data is! Map) return '';
    return _ionToken = '${res.data['cesium_ion_token'] ?? ''}';
  }

  /// Saves the farm's boundary (FRM-01). The server checks it again, works out
  /// the area and registers it for weather and satellite data.
  static Future<ApiResponse> saveBoundary(String farmId, List<LngLat> ring) =>
      ApiService.patch('/farms/$farmId', {'boundary': toPolygon(ring)});
}

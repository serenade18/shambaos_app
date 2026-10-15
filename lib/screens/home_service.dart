import '../models/weather_model.dart';
import '../models/agro_polygon_model.dart';
import '../services/api_service.dart';

class HomeService {
  // ================= FARMS =================
  /// The organisation's farms, main farm first. The API pages them as {results}.
  static Future<List<Map<String, dynamic>>> listFarms() async {
    final response = await ApiService.get('/farms', requiresAuth: true);

    if (response.error || response.data is! Map) return [];

    final List data = response.data['results'] ?? [];
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // ================= FORECAST =================
  /// The farm's forecast, today first. Weather is looked up by farm: the
  /// server uses the farm's boundary or location.
  static Future<List<WeatherModel>> getForecast({
    required String farmId,
  }) async {
    final response = await ApiService.get(
      '/weather?farm_id=$farmId',
      requiresAuth: true,
    );

    if (response.error || response.data is! Map) {
      return [];
    }

    final List data = response.data['forecast'] ?? [];

    return data.map((e) => WeatherModel.fromJson(e)).toList();
  }

  // ================= CURRENT WEATHER =================
  static Future<WeatherModel?> getCurrentWeather({
    required String farmId,
  }) async {
    final forecast = await getForecast(farmId: farmId);

    if (forecast.isEmpty) return null;

    return forecast.first;
  }

  // ================= POLYGONS =================
  static Future<List<AgroPolygon>> listPolygons() async {
    final farms = await listFarms();
    return farms.map((e) => AgroPolygon.fromJson(e)).toList();
  }

  // ================= FULL FLOW (IMPORTANT) =================
  static Future<WeatherModel?> getWeatherFromFirstPolygon() async {
    final polygons = await listPolygons();

    if (polygons.isEmpty) return null;

    return getCurrentWeather(farmId: polygons.first.id);
  }

  static Future<List<WeatherModel>> getForecastFromFirstPolygon() async {
    final polygons = await listPolygons();

    if (polygons.isEmpty) return [];

    return getForecast(farmId: polygons.first.id);
  }
}

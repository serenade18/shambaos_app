import '../models/weather_model.dart';
import '../models/agro_polygon_model.dart';
import '../services/api_service.dart';

class HomeService {
  // ✅ Extract lat/lon from GeoJSON center [lng, lat]
  static Map<String, double> _extractLatLon(List<double> center) {
    return {
      "lat": center[1], // GeoJSON → [lng, lat]
      "lon": center[0],
    };
  }

  // ================= FORECAST =================
  static Future<List<WeatherModel>> getForecast({
    required double lat,
    required double lon,
  }) async {
    final response = await ApiService.get(
      '/weather/forecast/?lat=$lat&lon=$lon',
      requiresAuth: true,
    );

    if (!response.error || response.data == null) {
      return [];
    }

    final List data = response.data;

    return data.map((e) => WeatherModel.fromJson(e)).toList();
  }

  // ================= CURRENT WEATHER =================
  static Future<WeatherModel?> getCurrentWeather({
    required double lat,
    required double lon,
  }) async {
    final forecast = await getForecast(lat: lat, lon: lon);

    if (forecast.isEmpty) return null;

    return forecast.first;
  }

  // ================= POLYGONS =================
  static Future<List<AgroPolygon>> listPolygons() async {
    final response = await ApiService.get(
      '/weather/polygons/',
      requiresAuth: true,
    );

    if (!response.error || response.data == null) {
      return [];
    }

    final List data = response.data;

    return data.map((e) => AgroPolygon.fromJson(e)).toList();
  }

  // ================= FULL FLOW (IMPORTANT) =================
  static Future<WeatherModel?> getWeatherFromFirstPolygon() async {
    final polygons = await listPolygons();

    if (polygons.isEmpty) return null;

    final first = polygons.first;

    final coords = _extractLatLon(first.center);

    return getCurrentWeather(
      lat: coords["lat"]!,
      lon: coords["lon"]!,
    );
  }

  static Future<List<WeatherModel>> getForecastFromFirstPolygon() async {
    final polygons = await listPolygons();

    if (polygons.isEmpty) return [];

    final first = polygons.first;

    final coords = _extractLatLon(first.center);

    return getForecast(
      lat: coords["lat"]!,
      lon: coords["lon"]!,
    );
  }
}
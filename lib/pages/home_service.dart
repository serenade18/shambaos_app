import '../models/weather_model.dart';
import '../services/api_service.dart';

class HomeService {
  // ✅ Inline coordinate normalization (instead of utils folder)
  static Map<String, double> _normalize(double lat, double lon) {
    return {
      "lat": double.parse(lat.toStringAsFixed(6)),
      "lon": double.parse(lon.toStringAsFixed(6)),
    };
  }

  static Future<List<WeatherModel>> getForecast({
    required double lat,
    required double lon,
  }) async {
    final coords = _normalize(lat, lon);

    final response = await ApiService.get(
      '/weather/forecast/?lat=${coords["lat"]}&lon=${coords["lon"]}',
      requiresAuth: true,
    );

    if (!response.success || response.data == null) {
      return [];
    }

    final List data = response.data;

    return data.map((e) => WeatherModel.fromJson(e)).toList();
  }

  static Future<WeatherModel?> getCurrentWeather({
    required double lat,
    required double lon,
  }) async {
    final forecast = await getForecast(lat: lat, lon: lon);

    if (forecast.isEmpty) return null;

    return forecast.first;
  }
}
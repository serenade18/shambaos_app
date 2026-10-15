/// One day of a farm's weather, from GET /weather?farm_id=.
class WeatherModel {
  final double temp; // the day's high, °C
  final double tempMin;
  final String condition; // sunny | cloudy | light_rain | rain | heavy_rain
  final String description;
  final String icon; // OpenWeather icon code, for the icon image
  final int rainProbability; // %
  final double precipitation; // mm
  final DateTime dateTime;

  WeatherModel({
    required this.temp,
    required this.tempMin,
    required this.condition,
    required this.description,
    required this.icon,
    required this.rainProbability,
    required this.precipitation,
    required this.dateTime,
  });

  static const _icons = {
    'sunny': '01d',
    'cloudy': '03d',
    'light_rain': '10d',
    'rain': '09d',
    'heavy_rain': '11d',
  };

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    final condition = (json['condition'] ?? 'cloudy') as String;

    return WeatherModel(
      temp: (json['t_max'] as num).toDouble(),
      tempMin: (json['t_min'] as num).toDouble(),
      condition: condition,
      description: condition.replaceAll('_', ' '),
      icon: _icons[condition] ?? '03d',
      rainProbability: (json['rain_probability'] as num?)?.toInt() ?? 0,
      precipitation: (json['rain_mm'] as num?)?.toDouble() ?? 0.0,
      dateTime: DateTime.parse(json['date']),
    );
  }
}

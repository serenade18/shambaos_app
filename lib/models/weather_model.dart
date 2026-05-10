class WeatherModel {
  final double temp;
  final String condition;
  final String description;
  final String icon; 
  final int humidity;
  final double windSpeed;
  final double precipitation;
  final DateTime dateTime;

  WeatherModel({
    required this.temp,
    required this.condition,
    required this.description,
    required this.icon, 
    required this.humidity,
    required this.windSpeed,
    required this.precipitation,
    required this.dateTime,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    final main = json['main'];
    final weather = json['weather'][0];
    final wind = json['wind'];

    return WeatherModel(
      temp: (main['temp'] - 273.15),
      condition: weather['main'],
      description: weather['description'],
      icon: weather['icon'], // ✅ ADD
      humidity: main['humidity'],
      windSpeed: (wind['speed'] as num).toDouble(),
      precipitation: json['rain']?['3h']?.toDouble() ?? 0.0,
      dateTime:
          DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000),
    );
  }
}
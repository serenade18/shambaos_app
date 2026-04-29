import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../screens/home_service.dart';

class WeatherWidget extends StatefulWidget {
  const WeatherWidget({super.key});

  @override
  State<WeatherWidget> createState() => WeatherWidgetState();
}

class WeatherWidgetState extends State<WeatherWidget> {
  WeatherModel? weather;
  String fieldName = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    setState(() => isLoading = true);

    final polygons = await HomeService.listPolygons();

    if (polygons.isEmpty) {
      setState(() {
        weather = null;
        isLoading = false;
      });
      return;
    }

    final first = polygons.first;
    final lat = first.center[1];
    final lon = first.center[0];

    final result = await HomeService.getCurrentWeather(
      lat: lat,
      lon: lon,
    );

    setState(() {
      weather = result;
      fieldName = first.name;
      isLoading = false;
    });
  }

  /// Called externally via GlobalKey to refresh weather data
  Future<void> refresh() => _loadWeather();

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (weather == null) {
      return const Text(
        'Failed to load weather',
        style: TextStyle(color: Colors.white70),
      );
    }

    return _buildUI();
  }

  Widget _buildUI() {
    final w = weather!;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  color: Colors.white70, size: 16),
              const SizedBox(width: 6),

              Expanded(
                child: Text(
                  fieldName.isEmpty ? 'Your Field' : fieldName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                  ),
                ),
              ),

              const SizedBox(width: 6),

              Image.network(
                'https://openweathermap.org/img/wn/${w.icon}@2x.png',
                width: 40, // 👈 fixed safe size (don’t over-engineer this)
                height: 40,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.cloud,
                  color: Colors.white70,
                  size: 30,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${w.temp.toStringAsFixed(1)}°C',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      w.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${w.dateTime}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.12)),
          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _stat('Humidity', '${w.humidity}%'),
              _stat('Rain', '${w.precipitation} mm'),
              _stat('Wind', '${w.windSpeed} m/s'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(0.55), fontSize: 11)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import '../services/app_colors.dart';
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

    final result = await HomeService.getCurrentWeather(farmId: first.id);

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
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: context.appColors.brandText,
            ),
          ),
        ),
      );
    }

    if (weather == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(Icons.cloud_off_outlined, color: context.appColors.textHint, size: 18),
            SizedBox(width: 8),
            Text(
              'Weather unavailable',
              style: TextStyle(color: context.appColors.textHint, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return _buildUI();
  }

  Widget _buildUI() {
    final w = weather!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Row 1: date + location ──────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // "Today, Nairobi, Embakasi, E..."
                  Text(
                    _buildLocationLabel(w),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.appColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  // "Cloudy, No Rain"
                  Text(
                    _capitalise(w.description),
                    style: TextStyle(
                      color: context.appColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Temperature + weather icon side by side
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '${w.temp.round()}°',
                  style: TextStyle(
                    color: context.appColors.textPrimary,
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 6),
                Image.network(
                  'https://openweathermap.org/img/wn/${w.icon}@2x.png',
                  width: 46,
                  height: 46,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.cloud_outlined,
                    color: context.appColors.textHint,
                    size: 36,
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 14),
        Divider(height: 1, thickness: 1, color: context.appColors.divider),
        const SizedBox(height: 12),

        // ── Row 2: Rain chance · Rain · Low stats ───────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _stat(Icons.water_drop_outlined, 'Chance', '${w.rainProbability}%'),
            _statDivider(),
            _stat(Icons.umbrella_outlined, 'Rain', '${w.precipitation} mm'),
            _statDivider(),
            _stat(Icons.thermostat_outlined, 'Low', '${w.tempMin.round()}°'),
          ],
        ),
      ],
    );
  }

  // "Today, Nairobi, Embakasi, E..." — mirrors the screenshot label
  String _buildLocationLabel(WeatherModel w) {
    final location = fieldName.isEmpty ? 'Your Field' : fieldName;
    return 'Today, $location';
  }

  String _capitalise(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  Widget _stat(IconData icon, String label, String value) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: context.appColors.brandText),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: context.appColors.textHint,
                  fontSize: 11,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: context.appColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statDivider() {
    return Container(
      width: 1,
      height: 28,
      color: context.appColors.divider,
    );
  }
}
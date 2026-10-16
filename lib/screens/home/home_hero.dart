import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/weather_model.dart';
import '../../services/app_colors.dart';
import '../../services/app_type.dart';
import '../../widgets/phosphor_icons.dart';
import '../../l10n/tr.dart';

/// The top of Home: a farm photograph with the greeting, today's weather for
/// the farm, and two weather tiles laid over it on frosted cards.
class HomeHero extends StatelessWidget {
  final String userName;
  final String initials;
  final String? place; // the farm's county or name
  final WeatherModel? today;
  final bool weatherLoading;
  final VoidCallback onAvatarTap;
  final VoidCallback? onBellTap;
  final VoidCallback? onPlaceTap; // opens the farm map

  const HomeHero({
    super.key,
    required this.userName,
    required this.initials,
    required this.place,
    required this.today,
    required this.weatherLoading,
    required this.onAvatarTap,
    this.onBellTap,
    this.onPlaceTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final top = MediaQuery.paddingOf(context).top;

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'images/auth/field.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            cacheWidth: (MediaQuery.sizeOf(context).width * MediaQuery.devicePixelRatioOf(context)).round(),
          ),
        ),
        // The page colour washes over the sky so the greeting reads in both themes.
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0, 0.35, 1],
                colors: [
                  c.scaffoldBackground.withValues(alpha: 0.85),
                  c.scaffoldBackground.withValues(alpha: 0.25),
                  c.scaffoldBackground.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, top + 12, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _greeting(c),
              const SizedBox(height: 18),
              _weatherCard(c),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _tile(c, PhosphorIconsRegular.cloudRain, c.rainInk, 'Rain today'.tr,
                        today == null ? '—' : '${_num(today!.precipitation)} mm'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _tile(c, PhosphorIconsRegular.thermometer, c.warnInk, 'Low tonight'.tr,
                        today == null ? '—' : '${today!.tempMin.round()}°C'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _greeting(AppColors c) {
    final hour = DateTime.now().hour;
    final hello = hour < 12 ? 'Good morning'.tr : hour < 17 ? 'Good afternoon'.tr : 'Good evening'.tr;
    return Row(
      children: [
        Semantics(
          button: true,
          label: 'Profile'.tr,
          child: GestureDetector(
            onTap: onAvatarTap,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(shape: BoxShape.circle, color: c.shamba),
              alignment: Alignment.center,
              child: Text(initials, style: AppType.label.copyWith(color: c.onShamba)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(hello, style: AppType.caption.copyWith(color: c.textSecondary)),
              Text(userName.isEmpty ? 'Karibu'.tr : userName,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.titleM.copyWith(color: c.textPrimary)),
            ],
          ),
        ),
        _roundButton(c, PhosphorIconsRegular.bell, 'Notifications'.tr, onBellTap),
      ],
    );
  }

  Widget _roundButton(AppColors c, IconData icon, String label, VoidCallback? onTap) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: _frost(
        c,
        radius: 999,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: 48, height: 48, child: Icon(icon, size: 22, color: c.textPrimary)),
        ),
      ),
    );
  }

  Widget _weatherCard(AppColors c) {
    final w = today;
    final now = DateTime.now();
    final (IconData icon, Color tone) = switch (w?.condition) {
      'sunny' => (PhosphorIconsFill.sun, c.maize),
      'light_rain' || 'rain' => (PhosphorIconsFill.cloudRain, c.rainInk),
      'heavy_rain' => (PhosphorIconsFill.cloudLightning, c.rainInk),
      _ => (PhosphorIconsFill.cloudSun, c.maize),
    };

    return _frost(
      c,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (onPlaceTap == null)
                    _pill(c, PhosphorIconsRegular.mapPin, place ?? 'Your farm'.tr)
                  else
                    Semantics(
                      button: true,
                      hint: 'Map your farm'.tr,
                      child: GestureDetector(onTap: onPlaceTap, child: _pill(c, PhosphorIconsRegular.mapPin, place ?? 'Your farm'.tr)),
                    ),
                  const SizedBox(height: 10),
                  if (w == null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        weatherLoading ? 'Loading the forecast…'.tr : 'The forecast shows here once your farm has a location.'.tr,
                        style: AppType.body.copyWith(color: c.textSecondary),
                      ),
                    )
                  else ...[
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.end,
                      spacing: 10,
                      children: [
                        Text('${w.temp.round()}°C', style: AppType.figureXl.copyWith(fontSize: 48, height: 1, color: c.textPrimary)),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(DateFormat('EEE d MMM · HH:mm').format(now),
                              style: AppType.caption.copyWith(color: c.textSecondary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _pill(c, PhosphorIconsRegular.drop, '{rainProbability}% rain'.trArgs({'rainProbability': w.rainProbability})),
                        _pill(c, PhosphorIconsRegular.thermometer, 'Low {p0}°'.trArgs({'p0': w.tempMin.round()})),
                        _pill(c, PhosphorIconsRegular.cloud, _cap(w.description)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, size: 64, color: tone),
          ],
        ),
      ),
    );
  }

  Widget _tile(AppColors c, IconData icon, Color tone, String label, String value) {
    return _frost(
      c,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(color: c.surfaceMuted, shape: BoxShape.circle),
                  child: Icon(icon, size: 15, color: tone),
                ),
                const SizedBox(width: 8),
                Text(label, style: AppType.caption.copyWith(color: c.textSecondary)),
              ],
            ),
            const SizedBox(height: 14),
            Text(value, style: AppType.figureL.copyWith(fontSize: 30, color: c.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _pill(AppColors c, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: c.surfaceMuted.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c.textSecondary),
          const SizedBox(width: 5),
          Text(text, style: AppType.caption.copyWith(fontSize: 12, color: c.textPrimary)),
        ],
      ),
    );
  }

  /// A frosted card over the photograph.
  Widget _frost(AppColors c, {required Widget child, double radius = 18}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: c.cardBackground.withValues(alpha: 0.82),
          child: child,
        ),
      ),
    );
  }

  static String _num(double v) => v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);
  static String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

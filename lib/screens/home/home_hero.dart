import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/weather_model.dart';
import '../../services/app_colors.dart';
import '../../services/app_type.dart';
import '../../widgets/ledger_parts.dart';
import '../auth/auth_ui.dart';
import '../profile/my_photo.dart';
import '../../l10n/tr.dart';

/// The top of Home, as the design draws it (sl-hero): the farm photograph
/// with rounded bottom corners, the greeting, today's weather on a frosted
/// card, and rain today and over the next seven days on two frosted tiles.
class HomeHero extends StatelessWidget {
  final String userName;
  final String initials;
  final String? place; // the farm's name and county
  final WeatherModel? today;
  final double? weekRain; // mm over the next 7 days, null when unknown
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
    this.weekRain,
    required this.weatherLoading,
    required this.onAvatarTap,
    this.onBellTap,
    this.onPlaceTap,
  });

  static const _leaf = '<path d="M14 9.536V7a4 4 0 0 1 4-4h1.5a.5.5 0 0 1 .5.5V5a4 4 0 0 1-4 4 4 4 0 0 0-4 4c0 2 1 3 1 5a5 5 0 0 1-1 3"/><path d="M4 9a5 5 0 0 1 8 4 5 5 0 0 1-8-4"/><path d="M5 21h14"/>';
  static const _bell = '<path d="M10.268 21a2 2 0 0 0 3.464 0"/><path d="M3.262 15.326A1 1 0 0 0 4 17h16a1 1 0 0 0 .74-1.673C19.41 13.956 18 12.499 18 8A6 6 0 0 0 6 8c0 4.499-1.411 5.956-2.738 7.326"/>';
  static const _rain = '<path d="M4 14.899A7 7 0 1 1 15.71 8h1.79a4.5 4.5 0 0 1 2.5 8.242"/><path d="M16 14v6"/><path d="M8 14v6"/><path d="M12 16v6"/>';
  static const _sun = '<circle cx="12" cy="12" r="4"/><path d="M12 2v2"/><path d="M12 20v2"/><path d="m4.93 4.93 1.41 1.41"/><path d="m17.66 17.66 1.41 1.41"/><path d="M2 12h2"/><path d="M20 12h2"/><path d="m6.34 17.66-1.41 1.41"/><path d="m19.07 4.93-1.41 1.41"/>';
  static const _cloudSun = '<path d="M12 2v2"/><path d="m4.93 4.93 1.41 1.41"/><path d="M20 12h2"/><path d="m19.07 4.93-1.41 1.41"/><path d="M15.947 12.65a4 4 0 0 0-5.925-4.128"/><path d="M13 22H7a5 5 0 1 1 4.9-6H13a3 3 0 0 1 0 6Z"/>';
  static const _storm = '<path d="M6 16.326A7 7 0 1 1 15.71 8h1.79a4.5 4.5 0 0 1 .5 8.973"/><path d="m13 12-3 5h4l-3 5"/>';

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final top = MediaQuery.paddingOf(context).top;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
      child: Stack(
        children: [
          Positioned.fill(child: ColoredBox(color: c.shamba)),
          Positioned.fill(
            child: Image.asset(
              'images/auth/farming.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              cacheWidth: (MediaQuery.sizeOf(context).width * MediaQuery.devicePixelRatioOf(context)).round(),
            ),
          ),
          // A shade over the top 45%, so the greeting reads on the photo.
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: FractionallySizedBox(
              widthFactor: 1,
              child: Container(
                height: 220 + top,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x7317211A), Color(0x0017211A)],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, top + 20, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _greeting(c),
                const SizedBox(height: 16),
                _weatherCard(context, c),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _tile(c, 'Rain today'.tr, today == null ? null : _num(today!.precipitation))),
                  const SizedBox(width: 10),
                  Expanded(child: _tile(c, 'Next 7 days'.tr, weekRain == null ? null : _num(weekRain!))),
                ]),
              ],
            ),
          ),
        ],
      ),
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
            child: MyAvatar(initials: initials),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(hello, style: const TextStyle(fontFamily: AppType.text, fontSize: 13, height: 18 / 13, color: Colors.white)),
              Text(userName.isEmpty ? 'Karibu'.tr : userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: AppType.text, fontSize: 16, height: 22 / 16, fontWeight: FontWeight.w700, color: Colors.white)),
            ],
          ),
        ),
        _iconButton(c, _bell, 'Notifications'.tr, onBellTap),
      ],
    );
  }

  Widget _iconButton(AppColors c, String icon, String label, VoidCallback? onTap) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: _glass(
        c,
        radius: 999,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: 44, height: 44, child: Center(child: LineIcon(icon, size: 22, color: c.textPrimary))),
        ),
      ),
    );
  }

  Widget _weatherCard(BuildContext context, AppColors c) {
    final w = today;
    final (String icon, Color tone) = switch (w?.condition) {
      'sunny' => (_sun, c.maize),
      'light_rain' || 'rain' => (_rain, c.rainInk),
      'heavy_rain' => (_storm, c.rainInk),
      _ => (_cloudSun, c.maize),
    };
    final farmTag = SlTag(place ?? 'Your farm'.tr, icon: _leaf);

    return _glass(
      c,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 64),
                  child: onPlaceTap == null
                      ? farmTag
                      : Semantics(button: true, hint: 'Map your farm'.tr, child: GestureDetector(onTap: onPlaceTap, child: farmTag)),
                ),
                if (w == null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 14, 64, 4),
                    child: Text(
                      weatherLoading ? 'Loading the forecast…'.tr : 'The forecast shows here once your farm has a location.'.tr,
                      style: AppType.body.copyWith(color: c.textSecondary),
                    ),
                  )
                else ...[
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('${w.temp.round()}°C',
                          style: TextStyle(
                              fontFamily: AppType.text,
                              fontSize: 44,
                              height: 48 / 44,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.88,
                              color: c.textPrimary,
                              fontFeatures: const [FontFeature.tabularFigures()])),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(DateFormat('EEE d MMM · HH:mm', Localizations.localeOf(context).toString()).format(DateTime.now()),
                            style: AppType.caption.copyWith(color: c.textSecondary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    SlTag('{rainProbability}% chance of rain'.trArgs({'rainProbability': w.rainProbability}), tone: SlTone.info),
                    SlTag('Low {p0}°'.trArgs({'p0': w.tempMin.round()})),
                  ]),
                ],
              ],
            ),
            Positioned(right: 0, top: 0, child: LineIcon(icon, size: 52, strokeWidth: 1.6, color: tone)),
          ],
        ),
      ),
    );
  }

  Widget _tile(AppColors c, String label, String? mm) {
    return _glass(
      c,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppType.caption.copyWith(color: c.textSecondary)),
            const SizedBox(height: 10),
            Text.rich(
              TextSpan(children: [
                TextSpan(
                    text: mm ?? '—',
                    style: TextStyle(
                        fontFamily: AppType.text,
                        fontSize: 28,
                        height: 32 / 28,
                        fontWeight: FontWeight.w500,
                        color: c.textPrimary,
                        fontFeatures: const [FontFeature.tabularFigures()])),
                if (mm != null) TextSpan(text: ' mm', style: AppType.caption.copyWith(color: c.textSecondary)),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  /// A frosted card over the photograph (sl-glass).
  Widget _glass(AppColors c, {required Widget child, double radius = 24}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [BoxShadow(color: Color(0x1217211A), blurRadius: 24, offset: Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Material(color: c.cardBackground.withValues(alpha: 0.86), child: child),
        ),
      ),
    );
  }

  static String _num(double v) => v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);
}

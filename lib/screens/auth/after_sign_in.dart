import 'package:flutter/material.dart';
import '../home_screen.dart';
import '../home_service.dart';
import '../farm/farm_map_screen.dart';

/// Where a farmer goes once signed in (by code, Google or biometrics): Home,
/// with "Map your farm" on top when their farm has no boundary yet and they
/// haven't put it off. Closing or finishing the map lands on Home.
Future<void> goHomeAfterSignIn(BuildContext context) async {
  final navigator = Navigator.of(context);
  final farm = await _farmToMap();
  navigator.pushAndRemoveUntil(
    PageRouteBuilder(
      pageBuilder: (_, _, _) => const HomeScreen(),
      transitionsBuilder: (_, anim, _, child) => FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 400),
    ),
    (_) => false,
  );
  if (farm != null) {
    navigator.push(MaterialPageRoute(builder: (_) => FarmMapScreen(farm: farm)));
  }
}

/// The main farm, if it still needs mapping. Any failure just means Home.
Future<Map<String, dynamic>?> _farmToMap() async {
  try {
    final farms = await HomeService.listFarms();
    if (farms.isEmpty) return null;
    final farm = farms.first;
    if (farm['boundary'] != null) return null;
    if (await FarmMapScreen.putOff('${farm['id']}')) return null;
    return farm;
  } catch (_) {
    return null;
  }
}

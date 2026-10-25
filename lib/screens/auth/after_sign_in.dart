import 'package:flutter/material.dart';
import '../home_screen.dart';
import '../../services/api_service.dart';
import '../farm/farm_map_screen.dart';
import '../farm/setup_farm_screen.dart';
import '../profile/complete_profile_sheet.dart';

/// Where a farmer goes once signed in (by code, Google or biometrics): Home,
/// with "Complete your profile" on top until it is, then "Set up your farm" for
/// someone with no farm yet, or "Map your farm" when their farm has no boundary
/// yet and they haven't put it off.
/// Closing or finishing either lands on Home.
Future<void> goHomeAfterSignIn(BuildContext context) async {
  final navigator = Navigator.of(context);
  final farms = await _farms();
  final farm = farms == null || farms.isEmpty ? null : await _toMap(farms.first);
  navigator.pushAndRemoveUntil(
    PageRouteBuilder(
      pageBuilder: (_, _, _) => const HomeScreen(),
      transitionsBuilder: (_, anim, _, child) => FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 400),
    ),
    (_) => false,
  );
  // Signed out instead of completing it: nothing more to open.
  if (!await ensureProfileComplete(navigator)) return;
  if (farms != null && farms.isEmpty) {
    setUpFarmWith(navigator);
  } else if (farm != null) {
    navigator.push(MaterialPageRoute(builder: (_) => FarmMapScreen(farm: farm)));
  }
}

/// The account's farms; null when they couldn't be loaded (no signal), which just
/// means Home: only a farm list that really is empty starts the setup.
Future<List<Map<String, dynamic>>?> _farms() async {
  try {
    final res = await ApiService.get('/farms');
    if (res.error || res.data is! Map) return null;
    return [for (final f in (res.data['results'] as List? ?? const [])) Map<String, dynamic>.from(f as Map)];
  } catch (_) {
    return null;
  }
}

/// The main farm, if it still needs mapping.
Future<Map<String, dynamic>?> _toMap(Map<String, dynamic> farm) async {
  if (farm['boundary'] != null) return null;
  if (await FarmMapScreen.putOff('${farm['id']}')) return null;
  return farm;
}

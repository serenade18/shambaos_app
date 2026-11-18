import 'package:flutter/material.dart';
import '../home_screen.dart';
import '../../services/api_service.dart';
import '../farm/setup_farm_screen.dart';

/// Where a farmer goes once signed in (by code, Google or biometrics): Home,
/// with "Set up your farm" on top for someone with no farm yet. Mapping the farm
/// is offered on Home, not opened. Closing or finishing setup lands on Home.
Future<void> goHomeAfterSignIn(BuildContext context) async {
  final navigator = Navigator.of(context);
  final farms = await _farms();
  navigator.pushAndRemoveUntil(
    PageRouteBuilder(
      pageBuilder: (_, _, _) => const HomeScreen(),
      transitionsBuilder: (_, anim, _, child) => FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 400),
    ),
    (_) => false,
  );
  if (farms != null && farms.isEmpty) setUpFarmWith(navigator);
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

import 'package:flutter/material.dart';
import 'phosphor_icons.dart';

import '../services/app_colors.dart';
import '../services/app_type.dart';

/// Home, Fields, Tulip (the AI farm assistant, raised in the centre), Activity
/// and Profile. The current place is marked with a maize bar on the top edge.
class AppBottomNav extends StatelessWidget {
  final int currentIndex; // 0 Home, 1 Fields, 2 Tulip, 3 Activity, 4 Profile
  final Function(int)? onTap;

  const AppBottomNav({super.key, this.currentIndex = 0, this.onTap});

  static const _routes = ['/home', '/fields', '/chat', '/activity', '/profile'];

  void _go(BuildContext context, int index) {
    if (index == currentIndex) return;
    onTap?.call(index);
    if (index == 0) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    } else if (currentIndex == 0) {
      Navigator.pushNamed(context, _routes[index]); // Home stays underneath
    } else {
      Navigator.pushReplacementNamed(context, _routes[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: c.cardBackground,
        border: Border(top: BorderSide(color: c.divider)),
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: SizedBox(
        height: 68,
        child: Row(
          children: [
            Expanded(child: _item(context, 0, PhosphorIconsRegular.house, PhosphorIconsFill.house, 'Home')),
            Expanded(child: _item(context, 1, PhosphorIconsRegular.mapTrifold, PhosphorIconsFill.mapTrifold, 'Fields')),
            Expanded(child: _assistant(context)),
            Expanded(child: _item(context, 3, PhosphorIconsRegular.chartLine, PhosphorIconsFill.chartLine, 'Activity')),
            Expanded(child: _item(context, 4, PhosphorIconsRegular.user, PhosphorIconsFill.user, 'Profile')),
          ],
        ),
      ),
    );
  }

  /// Tulip, the farm assistant: a raised dark button in the centre.
  Widget _assistant(BuildContext context) {
    final c = context.appColors;
    return Semantics(
      button: true,
      selected: currentIndex == 2,
      label: 'Tulip, farm assistant',
      excludeSemantics: true,
      child: Center(
        child: Transform.translate(
          offset: const Offset(0, -14),
          child: Material(
            color: c.textPrimary,
            shape: const CircleBorder(),
            elevation: 6,
            shadowColor: Colors.black.withValues(alpha: 0.35),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => _go(context, 2),
              child: SizedBox(
                width: 60,
                height: 60,
                child: Icon(PhosphorIconsFill.sparkle, size: 26, color: c.scaffoldBackground),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(BuildContext context, int index, IconData icon, IconData selectedIcon, String label) {
    final c = context.appColors;
    final selected = currentIndex == index;
    final color = selected ? c.textPrimary : c.textHint;

    return Semantics(
      selected: selected,
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: () => _go(context, index),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (selected)
              Positioned(
                top: 0,
                child: Container(
                  width: 32,
                  height: 3,
                  decoration: BoxDecoration(
                    color: c.maize,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(3)),
                  ),
                ),
              ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(selected ? selectedIcon : icon, size: 24, color: color),
                const SizedBox(height: 3),
                Text(label, style: AppType.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

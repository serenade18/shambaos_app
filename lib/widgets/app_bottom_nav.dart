import 'package:flutter/material.dart';
import '../screens/auth/auth_ui.dart';

import '../services/app_colors.dart';
import '../services/app_type.dart';
import '../l10n/tr.dart';

/// Home, Fields, AI (field analysis, raised in the centre), Activity and
/// Profile, as the Shamba Ledger nav: a white bar with rounded top corners, the
/// current place marked with a maize bar on its top edge.
class AppBottomNav extends StatelessWidget {
  final int currentIndex; // 0 Home, 1 Fields, 2 AI, 3 Activity, 4 Profile
  final Function(int)? onTap;

  const AppBottomNav({super.key, this.currentIndex = 0, this.onTap});

  static const _routes = ['/home', '/fields', '/ai', '/activity', '/profile'];

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

  // The design's line icons (Lucide, ISC licence).
  static const _house = '<path d="M15 21v-8a1 1 0 0 0-1-1h-4a1 1 0 0 0-1 1v8"/><path d="M3 10a2 2 0 0 1 .709-1.528l7-6a2 2 0 0 1 2.582 0l7 6A2 2 0 0 1 21 10v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/>';
  static const _map = '<path d="M14.106 5.553a2 2 0 0 0 1.788 0l3.659-1.83A1 1 0 0 1 21 4.619v12.764a1 1 0 0 1-.553.894l-4.553 2.277a2 2 0 0 1-1.788 0l-4.212-2.106a2 2 0 0 0-1.788 0l-3.659 1.83A1 1 0 0 1 3 19.381V6.618a1 1 0 0 1 .553-.894l4.553-2.277a2 2 0 0 1 1.788 0z"/><path d="M15 5.764v15"/><path d="M9 3.236v15"/>';
  static const _scan = '<path d="M3 7V5a2 2 0 0 1 2-2h2"/><path d="M17 3h2a2 2 0 0 1 2 2v2"/><path d="M21 17v2a2 2 0 0 1-2 2h-2"/><path d="M7 21H5a2 2 0 0 1-2-2v-2"/><path d="M7 12h10"/>';
  static const _chart = '<path d="M3 3v16a2 2 0 0 0 2 2h16"/><path d="m19 9-5 5-4-4-3 3"/>';
  static const _user = '<path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/>';

  /// The bar is 72 high; the scan button rises 28 above it. That strip is
  /// see-through and lets taps through, so screens using the bar set
  /// Scaffold.extendBody and scroll under it.
  static const barHeight = 72.0;
  static const _rise = 28.0;

  /// Space to leave under a scroll view that runs beneath the bar, so its last
  /// item can scroll clear of the bar and the raised scan button. Read from a
  /// context outside the Scaffold, where the padding is the phone's own.
  static double scrollPadding(BuildContext context) => barHeight + _rise + MediaQuery.paddingOf(context).bottom + 16;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return SizedBox(
      height: _rise + barHeight + bottomPadding,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: barHeight + bottomPadding,
            child: Container(
              padding: EdgeInsets.only(bottom: bottomPadding),
              decoration: BoxDecoration(
                color: c.cardBackground,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: const [BoxShadow(color: Color(0x1217211A), blurRadius: 24, offset: Offset(0, 8))],
              ),
              child: Row(
                children: [
                  Expanded(child: _item(context, 0, _house, 'Home'.tr)),
                  Expanded(child: _item(context, 1, _map, 'Fields'.tr)),
                  const SizedBox(width: 64),
                  Expanded(child: _item(context, 3, _chart, 'Activity'.tr)),
                  Expanded(child: _item(context, 4, _user, 'Profile'.tr)),
                ],
              ),
            ),
          ),
          Positioned(top: 0, left: 0, right: 0, child: Center(child: _scanButton(context))),
        ],
      ),
    );
  }

  /// Field analysis with AI: a raised dark button in the centre.
  Widget _scanButton(BuildContext context) {
    final c = context.appColors;
    return Semantics(
      button: true,
      selected: currentIndex == 2,
      label: 'Analyse a field with AI'.tr,
      excludeSemantics: true,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: c.textPrimary,
          shape: BoxShape.circle,
          boxShadow: const [BoxShadow(color: Color(0x4717211A), blurRadius: 24, offset: Offset(0, 10))],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => _go(context, 2),
            child: Center(child: LineIcon(_scan, size: 28, strokeWidth: 2.4, color: c.scaffoldBackground)),
          ),
        ),
      ),
    );
  }

  Widget _item(BuildContext context, int index, String icon, String label) {
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
            // The current place: a maize bar across the middle of the top edge.
            if (selected)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: FractionallySizedBox(
                  widthFactor: 0.4,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: c.maize,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(3)),
                    ),
                  ),
                ),
              ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LineIcon(icon, size: 24, color: color),
                const SizedBox(height: 3),
                Text(label, style: AppType.caption.copyWith(fontSize: 12, height: 14 / 12, fontWeight: FontWeight.w700, color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'phosphor_icons.dart';

import '../services/app_colors.dart';
import '../services/app_type.dart';

/// The app's places, each a labelled line icon. The current one is marked
/// with a maize bar on the top edge: maize means "you are here".
class AppBottomNav extends StatefulWidget {
  final int currentIndex;
  final Function(int)? onTap;

  const AppBottomNav({super.key, this.currentIndex = 0, this.onTap});

  @override
  State<AppBottomNav> createState() => _AppBottomNavState();
}

class _AppBottomNavState extends State<AppBottomNav> {
  late int _currentIndex;

  static const _items = [
    (PhosphorIconsRegular.house, PhosphorIconsFill.house, 'Home'),
    (PhosphorIconsRegular.chatCircleText, PhosphorIconsFill.chatCircleText, 'Tulip'),
    (PhosphorIconsRegular.user, PhosphorIconsFill.user, 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
  }

  void _handleTap(BuildContext context, int index) {
    if (_currentIndex == index) return;

    setState(() => _currentIndex = index);
    widget.onTap?.call(index);

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home'); // home replaces
        break;
      case 1:
        Navigator.pushNamed(context, '/chat'); // push, can go back
        break;
      case 2:
        Navigator.pushNamed(context, '/profile'); // push, can go back
        break;
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
        height: 64,
        child: Row(
          children: [
            for (var i = 0; i < _items.length; i++) Expanded(child: _navItem(context, i)),
          ],
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, int index) {
    final c = context.appColors;
    final selected = _currentIndex == index;
    final (icon, selectedIcon, label) = _items[index];
    final color = selected ? c.brandText : c.textHint;

    return Semantics(
      selected: selected,
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: () => _handleTap(context, index),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (selected)
              Positioned(
                top: 0,
                child: Container(
                  width: 36,
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

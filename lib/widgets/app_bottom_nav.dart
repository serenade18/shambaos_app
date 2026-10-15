import 'package:flutter/material.dart';
import '../services/app_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppBottomNav extends StatefulWidget {
  final int currentIndex;
  final Function(int)? onTap;

  const AppBottomNav({super.key, this.currentIndex = 0, this.onTap});

  @override
  State<AppBottomNav> createState() => _AppBottomNavState();
}

class _AppBottomNavState extends State<AppBottomNav> {
  late int _currentIndex;

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
        Navigator.pushNamed(context, '/chat');            // push, can go back
        break;
      case 2:
        Navigator.pushNamed(context, '/profile');         // push, can go back
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: context.appColors.cardBackground,
        border: Border(
          top: BorderSide(color: context.appColors.divider, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 72,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _navItem(Icons.home_rounded, 'Home', 0, context),

                // ── Centre FAB (chat) ──────────────────────────
                GestureDetector(
                  onTap: () => _handleTap(context, 1),
                  child: Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      color: _currentIndex == 1
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4CAF50).withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(13.0),
                      child: SvgPicture.asset(
                        'images/assets/icons/comments.svg',
                        colorFilter: const ColorFilter.mode(
                            Colors.white, BlendMode.srcIn),
                        fit: BoxFit.contain,
                        placeholderBuilder: (context) => Image.asset(
                          'images/assets/icons/live-chat.png',
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                _navItem(Icons.person, 'Profile', 2, context),
              ],
            ),
          ),

          SizedBox(height: bottomPadding > 0 ? bottomPadding * 0.4 : 8.0),
        ],
      ),
    );
  }

  Widget _navItem(
      IconData icon, String label, int index, BuildContext context) {
    final selected = _currentIndex == index;

    return GestureDetector(
      onTap: () => _handleTap(context, index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF4CAF50).withOpacity(0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected
                  ? context.appColors.brandText
                  : context.appColors.textHint,
              size: 26,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? context.appColors.brandText
                    : context.appColors.textHint,
                fontSize: 14,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
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
    if (index == 4) {
      widget.onTap?.call(index);
      Navigator.pushNamed(context, '/more');
      return;
    }

    if (_currentIndex == index) return;

    setState(() => _currentIndex = index);
    widget.onTap?.call(index);

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/sales');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/chat');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/tasks');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFEEEEEE), width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _navItem(Icons.home_rounded, 'Home', 0, context),
                _navItem(Icons.grass_rounded, 'Advisory', 1, context),

                // ── Centre FAB (chat) ──────────────────────────
                GestureDetector(
                  onTap: () => _handleTap(context, 2),
                  child: Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
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
                      padding: const EdgeInsets.all(12.0),
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

                _navItem(Icons.content_paste_go, 'Tasks', 3, context),
                _navItem(Icons.menu, 'More', 4, context),
              ],
            ),
          ),

          // Safe area bottom padding
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          // Active pill: light green tint background
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
              // Active: solid green. Inactive: muted gray
              color: selected
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFFAAAAAA),
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFAAAAAA),
                fontSize: 10,
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
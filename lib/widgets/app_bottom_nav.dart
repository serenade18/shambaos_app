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
        Navigator.pushReplacementNamed(context, '/payments');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the system padding (e.g., for the iPhone home indicator)
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      color: const Color(0xFF1E3D1A),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Items Row
          SizedBox(
            height: 70,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _navItem(Icons.home_rounded, 'Home', 0, context),
                _navItem(Icons.grass_rounded, 'Community', 1, context),

                // Center → Chat
                GestureDetector(
                  onTap: () => _handleTap(context, 2),
                  child: Container(
                    height: 52,
                    width: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
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

                _navItem(Icons.document_scanner_outlined, 'Payment', 3, context),
                _navItem(Icons.menu, 'More', 4, context),
              ],
            ),
          ),

          // ✅ Reduced padding: Use 12.0 as a floor or 40% of the system padding
          // This keeps it tight but prevents it from touching the very bottom edge.
          SizedBox(height: bottomPadding > 0 ? bottomPadding * 0.4 : 10.0),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? const Color(0xFF4CAF50) : Colors.white54,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: selected ? const Color(0xFF4CAF50) : Colors.white54,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
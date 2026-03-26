import 'dart:ui';
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
    if (_currentIndex == index) return; // prevent reloading same screen
    setState(() => _currentIndex = index);

    widget.onTap?.call(index);

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/fields');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/chat');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/documents');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/more');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0xFF1E3D1A),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(Icons.home_rounded, 'Home', 0, context),
                _navItem(Icons.grass_rounded, 'Fields', 1, context),

                // Center → Chat (SVG or fallback PNG)
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
                        'images/assets/icons/comments.svg', // <-- SVG icon from Flaticon
                        color: Colors.white,
                        fit: BoxFit.contain,
                        placeholderBuilder: (context) => Image.asset(
                          'images/assets/icons/live-chat.png', // fallback PNG
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                _navItem(Icons.document_scanner_outlined, 'Document', 3, context),
                _navItem(Icons.more_horiz, 'More', 4, context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index, BuildContext context) {
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
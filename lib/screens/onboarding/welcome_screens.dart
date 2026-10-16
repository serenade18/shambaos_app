import 'dart:async'; // Required for the automatic timer
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../auth/login_screen.dart';
import '../../l10n/tr.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data model for each welcome page
// ─────────────────────────────────────────────────────────────────────────────
class _WelcomePage {
  final String image;
  final String tag;
  final String headline;
  final String subtitle;

  const _WelcomePage({
    required this.image,
    required this.tag,
    required this.headline,
    required this.subtitle,
  });
}

List<_WelcomePage> get _pages => [
  _WelcomePage(
    image: 'images/auth/farming.jpg',
    tag: 'FARM INTELLIGENCE'.tr,
    headline: 'Modern Farming.\nTraditional\nWisdom.'.tr,
    subtitle: 'Put the power of data in your pocket. Track your soil health and weather to ensure a bumper harvest every season.'.tr,
  ),
  _WelcomePage(
    image: 'images/auth/beans.jpg',
    tag: 'LIVESTOCK MANAGEMENT'.tr,
    headline: 'Your Digital\nFarm Manager,\n24/7.'.tr,
    subtitle: 'From poultry to dairy and fish—manage your entire inventory and production records without the paperwork.'.tr,
  ),
  // _WelcomePage(
  //   image: 'images/auth/cow.jpg',
  //   tag: 'SMART INPUTS',
  //   headline: 'Save on Costs.\nGrow Your\nProfits.',
  //   subtitle: 'Stop wasting expensive fertilizer and water. Our AI tells you exactly what your crops need to thrive.',
  // ),
  // _WelcomePage(
  //   image: 'images/auth/chicken.png',
  //   tag: 'MARKET ACCESS',
  //   headline: 'Direct Markets.\nBetter Prices.\nNo Brokers.',
  //   subtitle: 'Connect directly to verified buyers. Take control of your sales and keep the profit you worked for.',
  // ),
];

class WelcomeScreens extends StatefulWidget {
  const WelcomeScreens({super.key});

  @override
  State<WelcomeScreens> createState() => _WelcomeScreensState();
}

class _WelcomeScreensState extends State<WelcomeScreens> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _startAutoScroll();
  }

  // ── Auto Scroll Logic ──────────────────────────────────────
  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_currentPage < _pages.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      } else {
        _autoScrollTimer?.cancel();
        _goToLogin();
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel(); // Critical to stop timer when widget is destroyed
    _pageController.dispose();
    super.dispose();
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── PageView ───────────────────────────────────────
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (_, i) => _WelcomePageView(page: _pages[i]),
          ),

          // ── Skip button (Top Right) ────────────────────────
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: _goToLogin,
                child: Container(
                  margin: const EdgeInsets.only(top: 16, right: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                  ),
                  child: Text(
                    'Skip'.tr,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Dot Indicators (Centered Bottom) ───────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: SafeArea(
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(_pages.length, (i) {
                    final bool active = i == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 24 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(0xFF5CD65C)
                            : Colors.white.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomePageView extends StatefulWidget {
  final _WelcomePage page;
  const _WelcomePageView({required this.page});

  @override
  State<_WelcomePageView> createState() => _WelcomePageViewState();
}

class _WelcomePageViewState extends State<_WelcomePageView>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(widget.page.image, fit: BoxFit.cover),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.4, 0.6, 1.0],
                colors: [
                  Colors.black.withOpacity(0.1),
                  Colors.transparent,
                  Colors.black.withOpacity(0.5),
                  Colors.black.withOpacity(0.9),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 28,
          right: 28,
          bottom: 100,
          child: SlideTransition(
            position: _slideAnim,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5CD65C).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF5CD65C).withOpacity(0.4)),
                    ),
                    child: Text(
                      widget.page.tag,
                      style: const TextStyle(
                        color: Color(0xFF5CD65C),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.page.headline,
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.page.subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
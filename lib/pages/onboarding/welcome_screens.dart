import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../auth/login_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data model for each welcome page
// ─────────────────────────────────────────────────────────────────────────────
class _WelcomePage {
  final String image;       // asset path
  final String tag;         // small label above headline
  final String headline;
  final String subtitle;

  const _WelcomePage({
    required this.image,
    required this.tag,
    required this.headline,
    required this.subtitle,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Replace the image paths with your actual local assets.
// All images should live under  images/  in your project root.
// ─────────────────────────────────────────────────────────────────────────────
const List<_WelcomePage> _pages = [
  _WelcomePage(
    image: 'images/auth/farming.jpg',
    tag: 'FARM INTELLIGENCE',
    headline: 'Modern Farming.\nTraditional\nWisdom.',
    subtitle: 'Put the power of data in your pocket. Track your soil health and weather to ensure a bumper harvest every season.',
  ),
  _WelcomePage(
    image: 'images/auth/beans.jpg', // Swapped as requested
    tag: 'LIVESTOCK MANAGEMENT',
    headline: 'Your Digital\nFarm Manager,\n24/7.',
    subtitle: 'From poultry to dairy and fish—manage your entire inventory and production records without the paperwork.',
  ),
  _WelcomePage(
    image: 'images/auth/cow.jpg', // Swapped as requested
    tag: 'SMART INPUTS',
    headline: 'Save on Costs.\nGrow Your\nProfits.',
    subtitle: 'Stop wasting expensive fertilizer and water. Our AI tells you exactly what your crops need to thrive.',
  ),
  _WelcomePage(
    image: 'images/auth/chicken.png', // Swapped as requested
    tag: 'MARKET ACCESS',
    headline: 'Direct Markets.\nBetter Prices.\nNo Brokers.',
    subtitle: 'Connect directly to verified buyers. Take control of your sales and keep the profit you worked for.',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// WelcomeScreens  –  the PageView host
// ─────────────────────────────────────────────────────────────────────────────
class WelcomeScreens extends StatefulWidget {
  const WelcomeScreens({super.key});

  @override
  State<WelcomeScreens> createState() => _WelcomeScreensState();
}

class _WelcomeScreensState extends State<WelcomeScreens> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToGetStarted() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    } else {
      _goToGetStarted();
    }
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

          // ── Skip button — top right ────────────────────────
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: _goToGetStarted,
                child: Container(
                  margin: const EdgeInsets.only(top: 16, right: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Bottom controls ────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Dot indicators
                    Row(
                      children: List.generate(_pages.length, (i) {
                        final bool active = i == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(right: 6),
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

                    // // Next / Get Started button
                    GestureDetector(
                      onTap: _nextPage,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: _currentPage == _pages.length - 1 ? 160 : 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFF5CD65C),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: _currentPage == _pages.length - 1
                            ? const Center(
                                child: Text(
                                  'Get Started',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                                size: 22,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single welcome page widget
// ─────────────────────────────────────────────────────────────────────────────
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
      begin: const Offset(0, 0.15),
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
        // Background image
        Positioned.fill(
          child: Image.asset(
            widget.page.image,
            fit: BoxFit.cover,
          ),
        ),

        // Gradient overlay
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.4, 0.65, 1.0],
                colors: [
                  Colors.black.withOpacity(0.15),
                  Colors.transparent,
                  Colors.black.withOpacity(0.6),
                  Colors.black.withOpacity(0.95),
                ],
              ),
            ),
          ),
        ),

        // Text content
        Positioned(
          left: 28,
          right: 28,
          bottom: 110,
          child: SlideTransition(
            position: _slideAnim,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tag chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5CD65C).withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF5CD65C).withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      widget.page.tag,
                      style: const TextStyle(
                        color: Color(0xFF5CD65C),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Headline
                  Text(
                    widget.page.headline,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.08,
                      letterSpacing: 0.2,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Subtitle
                  Text(
                    widget.page.subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                      height: 1.6,
                      fontWeight: FontWeight.w400,
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

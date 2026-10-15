import 'package:flutter/material.dart';
import '../../services/app_colors.dart';
import 'package:flutter/services.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _arrowController;

  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _arrowAnim;

  @override
  void initState() {
    super.initState();

    // Text fade + slide up
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    // Arrow chevron pulse
    _arrowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _arrowAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _arrowController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    _slideController.forward();

    // Status bar style
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _arrowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Full-screen background image ───────────────────
          Positioned.fill(
            child: Image.asset(
              'images/auth/about-tech-farmer.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // ── Dark gradient overlay — bottom heavy ───────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.45, 0.72, 1.0],
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.55),
                    Colors.black.withOpacity(0.92),
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom content ─────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: SlideTransition(
                position: _slideAnim,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Headline
                        const Text(
                          'RUN YOUR FARM,\nLIKE A BUSINESS.',
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.05,
                            letterSpacing: 0.2,
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Subtitle
                        Text(
                          'Monitor crop health, optimize resources, and\nincrease yield with data driven insights.',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withOpacity(0.75),
                            height: 1.55,
                            fontWeight: FontWeight.w400,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Get Started button
                        _buildGetStartedButton(),

                        const SizedBox(height: 12),

                        // Home indicator line
                        // Center(
                        //   child: Container(
                        //     width: 120,
                        //     height: 4,
                        //     decoration: BoxDecoration(
                        //       color: Colors.white.withOpacity(0.3),
                        //       borderRadius: BorderRadius.circular(2),
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGetStartedButton() {
    return GestureDetector(
      onTap: () {
        // Navigate to next screen
      },
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          // Darker green with reduced opacity (0.85)
          color: const Color(0x144624).withOpacity(0.24),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          children: [
            // Left arrow circle - slightly darker for contrast
            Container(
              margin: const EdgeInsets.all(6),
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.brand, 
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward,
                color: Colors.white,
                size: 22,
              ),
            ),

            // Label
            const Expanded(
              child: Center(
                child: Text(
                  'Get Started',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),

            // Right chevrons
            AnimatedBuilder(
              animation: _arrowAnim,
              builder: (_, __) => Padding(
                padding: const EdgeInsets.only(right: 18),
                child: Row(
                  children: [
                    Icon(Icons.chevron_right,
                        color: Colors.white.withOpacity(_arrowAnim.value * 0.5),
                        size: 18),
                    Icon(Icons.chevron_right,
                        color: Colors.white.withOpacity(_arrowAnim.value * 0.75),
                        size: 18),
                    Icon(Icons.chevron_right,
                        color: Colors.white.withOpacity(_arrowAnim.value),
                        size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'onboarding.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _fadeOutController;

  late Animation<double> _scaleAnim;
  late Animation<double> _fadeInAnim;
  late Animation<double> _fadeOutAnim;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    // Logo scale + fade in
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scaleAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _fadeInAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // Whole screen fade out before navigation
    _fadeOutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeOutAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeOutController, curve: Curves.easeIn),
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    // Small delay then animate logo in
    await Future.delayed(const Duration(milliseconds: 300));
    await _logoController.forward();

    // Hold on logo
    await Future.delayed(const Duration(milliseconds: 1200));

    // Fade out and navigate
    await _fadeOutController.forward();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const OnboardingScreen(),
          transitionDuration: Duration.zero,
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _fadeOutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeOutAnim,
      builder: (context, child) => Opacity(
        opacity: _fadeOutAnim.value,
        child: child,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: AnimatedBuilder(
            animation: _logoController,
            builder: (context, _) => Opacity(
              opacity: _fadeInAnim.value,
              child: Transform.scale(
                scale: _scaleAnim.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo
                    Image.asset(
                      'images/logo.png',
                      width: 110,
                      height: 110,
                      fit: BoxFit.contain,
                    ),

                    // const SizedBox(height: 20),

                    // // App name below logo
                    // const Text(
                    //   'Shambaos',
                    //   style: TextStyle(
                    //     fontSize: 26,
                    //     fontWeight: FontWeight.w800,
                    //     color: Color(0xFF2E7D32),
                    //     letterSpacing: 1.2,
                    //   ),
                    // ),

                    // const SizedBox(height: 6),

                    // Text(
                    //   'Smart Farming Solutions',
                    //   style: TextStyle(
                    //     fontSize: 13,
                    //     color: Colors.grey[500],
                    //     letterSpacing: 0.5,
                    //     fontWeight: FontWeight.w400,
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
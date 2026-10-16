import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/tr.dart';
import '../../services/app_type.dart';
import '../auth/auth_ui.dart';
import 'welcome_screens.dart';

/// The leaf and name on shamba green while the app starts, then the welcome
/// pages.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  // The leaf, then the name 150 ms behind it: both fade in and grow from 80%.
  late final AnimationController _inCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1050));
  late final AnimationController _outCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  late final AnimationController _dotsCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

  static const _ease = Cubic(0.2, 0.8, 0.2, 1);
  late final Animation<double> _mark = CurvedAnimation(parent: _inCtrl, curve: const Interval(0, 900 / 1050, curve: _ease));
  late final Animation<double> _word = CurvedAnimation(parent: _inCtrl, curve: const Interval(150 / 1050, 1, curve: _ease));

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ));
    _startSequence();
  }

  Future<void> _startSequence() async {
    final still = WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    if (still) {
      _inCtrl.value = 1;
    } else {
      _dotsCtrl.repeat();
      await _inCtrl.forward();
    }
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    await _outCtrl.forward();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, __, ___) => const WelcomeScreens(),
      transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 500),
    ));
  }

  @override
  void dispose() {
    _inCtrl.dispose();
    _outCtrl.dispose();
    _dotsCtrl.dispose();
    super.dispose();
  }

  Widget _rise(Animation<double> a, Widget child) => AnimatedBuilder(
        animation: a,
        builder: (_, c) => Opacity(opacity: a.value.clamp(0.0, 1.0), child: Transform.scale(scale: 0.8 + 0.2 * a.value, child: c)),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: ReverseAnimation(_outCtrl),
      child: Scaffold(
        backgroundColor: Ledger.shamba,
        body: Stack(fit: StackFit.expand, children: [
          // Faint field rows along the bottom.
          const Positioned(left: 0, right: 0, bottom: 0, height: 300, child: CustomPaint(painter: _FieldRows())),
          Padding(
            padding: const EdgeInsets.only(bottom: 60),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Semantics(
                label: 'Shamba OS',
                image: true,
                child: _rise(_mark, const LeafLogo(size: 110, circle: Colors.white, leaf: Ledger.shamba)),
              ),
              const SizedBox(height: 20),
              _rise(
                _word,
                Column(children: [
                  const Text('Shamba OS',
                      style: TextStyle(fontFamily: AppType.text, fontSize: 34, height: 40 / 34, fontWeight: FontWeight.w500, letterSpacing: -0.34, color: Colors.white)),
                  const SizedBox(height: 6),
                  Text('Modern farming. Traditional wisdom.'.tr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontFamily: AppType.text, fontSize: 15, height: 22 / 15, color: Ledger.shambaTint)),
                ]),
              ),
            ]),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 56,
            child: Semantics(
              label: 'Loading'.tr,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) => _Dot(controller: _dotsCtrl, delay: i * 0.125)),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

/// A loading dot that brightens in turn with the others.
class _Dot extends StatelessWidget {
  final AnimationController controller;
  final double delay; // a fraction of the cycle
  const _Dot({required this.controller, required this.delay});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: controller,
        builder: (_, _) {
          final t = (controller.value - delay) % 1.0;
          // Bright at 40% of the cycle, dim (30%) from 80% round to the start.
          final o = t < 0.4 ? 0.3 + 0.7 * (t / 0.4) : t < 0.8 ? 1.0 - 0.7 * ((t - 0.4) / 0.4) : 0.3;
          return Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: controller.isAnimating ? o : 1), shape: BoxShape.circle),
          );
        },
      );
}

/// Five curved rows, white at 6%, like a ploughed field seen from above.
class _FieldRows extends CustomPainter {
  const _FieldRows();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    // Drawn on the design's 390-wide frame, rows 40 apart from 140 above the bottom edge.
    final sx = size.width / 390;
    for (var i = 0; i < 5; i++) {
      final y = size.height - 204 + i * 40.0;
      final p = Path()
        ..moveTo(-40 * sx, y)
        ..cubicTo(60 * sx, y - 40, 160 * sx, y + 20, 260 * sx, y - 20)
        ..cubicTo(360 * sx, y - 60, 420 * sx, y - 80, 460 * sx, y - 60);
      canvas.drawPath(p, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

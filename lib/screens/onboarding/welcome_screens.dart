import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/app_type.dart';
import '../auth/auth_ui.dart';
import '../auth/login_screen.dart';
import '../../l10n/tr.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Each welcome page: a full-bleed photo with its words at the bottom.
// ─────────────────────────────────────────────────────────────────────────────
class _WelcomePage {
  final String image;
  final String semantic; // what the photo shows, for screen readers
  final String tag;
  final String headline;
  final String subtitle;

  const _WelcomePage({required this.image, required this.semantic, required this.tag, required this.headline, required this.subtitle});
}

List<_WelcomePage> get _pages => [
      _WelcomePage(
        image: 'images/auth/farming.jpg',
        semantic: 'A farmer weeding young plants with her child on her back'.tr,
        tag: 'FARM INTELLIGENCE'.tr,
        headline: 'Modern farming.\nTraditional wisdom.'.tr,
        subtitle: 'Keep your animals, crops, stock and money in one record book, in Swahili, English or French.'.tr,
      ),
      _WelcomePage(
        image: 'images/auth/chicken.jpg',
        semantic: 'Chickens on a farm'.tr,
        tag: 'LIVESTOCK MANAGEMENT'.tr,
        headline: 'Your digital farm\nmanager, 24/7.'.tr,
        subtitle: 'From poultry to dairy and fish, keep every batch and herd on record without the paperwork.'.tr,
      ),
      _WelcomePage(
        image: 'images/auth/field.png',
        semantic: 'A green crop field'.tr,
        tag: 'FIELD SCAN'.tr,
        headline: 'Snap your field.\nKnow what it needs.'.tr,
        subtitle: 'Take a photo of a crop and the AI tells you what it sees and what to do next.'.tr,
      ),
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
      statusBarBrightness: Brightness.dark,
    ));
    _startAutoScroll();
  }

  // The pages turn on their own until the farmer swipes; "Get started" moves on.
  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_currentPage < _pages.length - 1) {
        _pageController.nextPage(duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _goToLogin() {
    _autoScrollTimer?.cancel();
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, __, ___) => const LoginScreen(),
      transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 400),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];
    return Scaffold(
      backgroundColor: const Color(0xFF101511),
      body: Stack(children: [
        // ── Photos ─────────────────────────────────────────────
        NotificationListener<ScrollStartNotification>(
          onNotification: (n) {
            if (n.dragDetails != null) _autoScrollTimer?.cancel();
            return false;
          },
          child: PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (_, i) => Semantics(
              image: true,
              label: _pages[i].semantic,
              child: Image.asset(_pages[i].image, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
            ),
          ),
        ),

        // ── Shade under the words: clear, then 85% from 45% of its height ──
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 520,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, 0.45],
                  colors: [Color(0x00101511), Color(0xD9101511)],
                ),
              ),
            ),
          ),
        ),

        // ── Logo and Skip ──────────────────────────────────────
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Row(children: [
              const LeafLogo(size: 40),
              const Spacer(),
              Semantics(
                button: true,
                child: TextButton(
                  onPressed: _goToLogin,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(fontFamily: AppType.text, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  child: Text('Skip'.tr),
                ),
              ),
            ]),
          ),
        ),

        // ── Words, page dots and Get started ───────────────────
        Positioned(
          left: 24,
          right: 24,
          bottom: 40,
          child: SafeArea(
            top: false,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Column(
                  key: ValueKey(_currentPage),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(page.tag,
                        style: const TextStyle(fontFamily: AppType.text, fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w700, letterSpacing: 0.96, color: Ledger.shambaTint)),
                    const SizedBox(height: 16),
                    Text(page.headline,
                        style: const TextStyle(fontFamily: AppType.text, fontSize: 40, height: 44 / 40, fontWeight: FontWeight.w500, letterSpacing: -0.4, color: Colors.white)),
                    const SizedBox(height: 16),
                    Text(page.subtitle, style: const TextStyle(fontFamily: AppType.text, fontSize: 17, height: 26 / 17, color: Color(0xFFE8EDE5))),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Semantics(
                label: 'Page {n} of {total}'.trArgs({'n': _currentPage + 1, 'total': _pages.length}),
                child: Row(
                  children: List.generate(_pages.length, (i) {
                    final active = i == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 6),
                      width: active ? 24 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: active ? Ledger.maize : Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 24),
              LedgerButton(label: 'Get started'.tr, kind: LedgerButtonKind.light, onPressed: _goToLogin),
            ]),
          ),
        ),
      ]),
    );
  }
}

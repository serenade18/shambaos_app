import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/app_type.dart';
import '../../services/app_theme.dart';
import '../../services/app_colors.dart';
import 'package:flutter/services.dart';
import 'auth_service.dart';
import 'verify_otp_screen.dart';
import '../home_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Brand tokens
// ─────────────────────────────────────────────────────────────────────────────
class _Brand {
  static const Color brand         = AppColors.brand;
  static const Color brandLight    = Color(0xFFE8F5E9);
  static const Color brandBorder   = Color(0xFFD6ECD9);
  static const Color scaffold      = Colors.white;
  static const Color card          = Colors.white;
  static const Color divider       = Color(0xFFF0F0F0);
  static const Color textPrimary   = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF777777);
  static const Color textHint      = Color(0xFFAAAAAA);
  static const Color errorRed      = Color(0xFFE53935);
}

// ─────────────────────────────────────────────────────────────────────────────
// Country model
// ─────────────────────────────────────────────────────────────────────────────
class _Country {
  final String flag;
  final String name;
  final String dialCode;
  const _Country({required this.flag, required this.name, required this.dialCode});
}

const List<_Country> _countries = [
  _Country(flag: '🇰🇪', name: 'Kenya',        dialCode: '+254'),
  _Country(flag: '🇺🇬', name: 'Uganda',       dialCode: '+256'),
  _Country(flag: '🇹🇿', name: 'Tanzania',     dialCode: '+255'),
  _Country(flag: '🇷🇼', name: 'Rwanda',       dialCode: '+250'),
  _Country(flag: '🇪🇹', name: 'Ethiopia',     dialCode: '+251'),
  _Country(flag: '🇳🇬', name: 'Nigeria',      dialCode: '+234'),
  _Country(flag: '🇬🇭', name: 'Ghana',        dialCode: '+233'),
  _Country(flag: '🇿🇦', name: 'South Africa', dialCode: '+27'),
];

// ─────────────────────────────────────────────────────────────────────────────
// LOGIN SCREEN  (phone entry)
// ─────────────────────────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  _Country _selectedCountry = _countries.first;
  final _phoneCtrl  = TextEditingController();
  final _phoneFocus = FocusNode();

  late AnimationController _animCtrl;
  late List<Animation<double>> _fadeAnims;
  late List<Animation<Offset>> _slideAnims;

  bool    _isLoading = false;
  String? _errorMsg;
  bool    _biometricReady = false;
  bool    _biometricBusy  = false;

  static const int _n = 5;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));

    _fadeAnims = List.generate(_n, (i) {
      final s = i * 0.12, e = (s + 0.5).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: _animCtrl,
              curve: Interval(s, e, curve: Curves.easeOut)));
    });
    _slideAnims = List.generate(_n, (i) {
      final s = i * 0.12, e = (s + 0.5).clamp(0.0, 1.0);
      return Tween<Offset>(
              begin: const Offset(0, 0.08), end: Offset.zero)
          .animate(CurvedAnimation(
              parent: _animCtrl,
              curve: Interval(s, e, curve: Curves.easeOut)));
    });

    Future.delayed(const Duration(milliseconds: 60), () {
      if (mounted) _animCtrl.forward();
    });
    _phoneFocus.addListener(() => setState(() {}));
    _checkBiometric();
  }

  // ── Biometric login ────────────────────────────────────────────────────────
  Future<void> _checkBiometric() async {
    final ready = await AuthService.canUseBiometricLogin();
    if (!mounted) return;
    setState(() => _biometricReady = ready);
    // Offer it straight away; the phone number stays available if they cancel.
    if (ready) Future.delayed(const Duration(milliseconds: 500), _handleBiometric);
  }

  Future<void> _handleBiometric() async {
    if (_biometricBusy || !mounted) return;
    setState(() { _biometricBusy = true; _errorMsg = null; });

    final res = await AuthService.biometricLogin();
    if (!mounted) return;
    setState(() => _biometricBusy = false);

    if (!res.error) {
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
        (_) => false,
      );
    } else {
      final ready = await AuthService.canUseBiometricLogin();
      if (!mounted) return;
      setState(() {
        _biometricReady = ready;
        // A cancelled prompt needs no message.
        _errorMsg = res.message == 'Biometric check was cancelled.' ? null : res.message;
      });
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _phoneCtrl.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  Widget _stagger(int i, Widget child) => SlideTransition(
      position: _slideAnims[i],
      child: FadeTransition(opacity: _fadeAnims[i], child: child));

  // ── Normalise to E.164 ────────────────────────────────────────────────────
  String _normalizedPhone() {
    final raw = _phoneCtrl.text.trim();
    if (raw.startsWith('0')) {
      return _selectedCountry.dialCode + raw.substring(1);
    }
    if (!raw.startsWith('+')) {
      return '${_selectedCountry.dialCode}$raw';
    }
    return raw;
  }

  // ── Request OTP ────────────────────────────────────────────────────────────
  Future<void> _handleContinue() async {
    final raw = _phoneCtrl.text.trim();
    if (raw.isEmpty) {
      _phoneFocus.requestFocus();
      return;
    }

    setState(() { _isLoading = true; _errorMsg = null; });

    final phone = _normalizedPhone();
    final res   = await AuthService.requestOtp(phone: phone);

    if (!mounted) return;
    setState(() => _isLoading = false);

    final sent = res.data is Map ? res.data['sent'] == true : false;

    if (!res.error && sent) {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => VerifyOtpScreen(
            phone: phone,
            displayPhone: '${_selectedCountry.dialCode} $raw',
          ),
          transitionsBuilder: (_, anim, __, child) => SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0), end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 350),
        ),
      );
    } else {
      setState(() => _errorMsg = res.data is Map
          ? res.data['message'] ?? 'Failed to send OTP. Try again.'
          : res.message ?? 'Failed to send OTP. Try again.');
    }
  }

  void _showCountryPicker() {
    _phoneFocus.unfocus();
    showModalBottomSheet(
      context: context,
      backgroundColor: _Brand.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: _Brand.divider,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 18),
          const Text('Select Country',
              style: TextStyle(color: _Brand.textPrimary, fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          const Divider(height: 1, color: _Brand.divider),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _countries.length,
            itemBuilder: (_, i) {
              final c   = _countries[i];
              final sel = c.dialCode == _selectedCountry.dialCode;
              return ListTile(
                onTap: () {
                  setState(() => _selectedCountry = c);
                  Navigator.pop(context);
                },
                tileColor: sel ? _Brand.brandLight : null,
                leading: Text(c.flag, style: const TextStyle(fontSize: 22)),
                title: Text(c.name,
                    style: TextStyle(
                        color: sel ? _Brand.brand : _Brand.textPrimary,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                        fontSize: 14)),
                trailing: Text(c.dialCode,
                    style: TextStyle(
                        color: sel ? _Brand.brand : _Brand.textSecondary,
                        fontWeight: FontWeight.w600, fontSize: 13)),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _Brand.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Need Help?',
            style: TextStyle(
                color: _Brand.textPrimary, fontWeight: FontWeight.w700)),
        content: const Text(
          'Enter your phone number (e.g. 0712 123456).\n'
          'We\'ll send a 6-digit SMS code to log in or create your account.',
          style: TextStyle(
              color: _Brand.textSecondary, height: 1.5, fontSize: 14),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Got it',
                  style: TextStyle(
                      color: _Brand.brand, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  // The sign-in screens keep their light design in both themes.
  @override
  Widget build(BuildContext context) =>
      Theme(data: AppTheme.light(), child: Builder(builder: _buildScreen));

  Widget _buildScreen(BuildContext context) {
    final focused = _phoneFocus.hasFocus;
    return Scaffold(
      backgroundColor: _Brand.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            _stagger(0, Container(
              width: double.infinity,
              color: _Brand.card,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: _Brand.brandLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _Brand.brandBorder)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: const [
                      Icon(Icons.agriculture_rounded,
                          color: _Brand.brand, size: 13),
                      SizedBox(width: 5),
                      Text('FARM INTELLIGENCE',
                          style: TextStyle(
                              color: _Brand.brand, fontSize: 10,
                              fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                    ]),
                  ),
                  const SizedBox(height: 18),
                  const Text("What's your phone number?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 30, fontWeight: FontWeight.w800,
                          color: _Brand.textPrimary, height: 1.15)),
                  const SizedBox(height: 8),
                  const Text('We use it to create your account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14,
                          color: _Brand.textSecondary,
                          height: 1.5)),
                ],
              ),
            )),

            const Divider(height: 1, thickness: 1, color: _Brand.divider),

            // ── Body ──────────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: Column(
                  children: [
                    // Phone input card
                    _stagger(1, AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: _Brand.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _errorMsg != null
                              ? _Brand.errorRed
                              : focused ? _Brand.brand : _Brand.divider,
                          width: focused || _errorMsg != null ? 1.5 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: focused
                                ? _Brand.brand.withOpacity(0.10)
                                : Colors.black.withOpacity(0.04),
                            blurRadius: focused ? 14 : 6,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Row(children: [
                        // Country selector
                        GestureDetector(
                          onTap: _showCountryPicker,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 16),
                            decoration: const BoxDecoration(
                                border: Border(
                                    right: BorderSide(color: _Brand.divider))),
                            child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(_selectedCountry.flag,
                                      style: const TextStyle(fontSize: 20)),
                                  const SizedBox(width: 6),
                                  Text(_selectedCountry.dialCode,
                                      style: const TextStyle(
                                          color: _Brand.textPrimary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 2),
                                  const Icon(Icons.keyboard_arrow_down_rounded,
                                      color: _Brand.textSecondary, size: 18),
                                ]),
                          ),
                        ),
                        // Number field
                        Expanded(
                          child: TextField(
                            controller: _phoneCtrl,
                            focusNode: _phoneFocus,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            onChanged: (_) {
                              if (_errorMsg != null) {
                                setState(() => _errorMsg = null);
                              }
                            },
                            style: const TextStyle(
                                color: _Brand.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w500),
                            decoration: const InputDecoration(
                              hintText: '712 123456',
                              hintStyle: TextStyle(
                                  color: _Brand.textHint, fontSize: 14),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 16),
                            ),
                            cursorColor: _Brand.brand,
                          ),
                        ),
                      ]),
                    )),

                    // Error message
                    if (_errorMsg != null) ...[
                      const SizedBox(height: 8),
                      _stagger(1, Row(children: [
                        const Icon(Icons.error_outline_rounded,
                            color: _Brand.errorRed, size: 15),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(_errorMsg!,
                              style: const TextStyle(
                                  color: _Brand.errorRed, fontSize: 12)),
                        ),
                      ])),
                    ],

                    const SizedBox(height: 12),

                    // Help row
                    _stagger(2, GestureDetector(
                      onTap: _showHelp,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: _Brand.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _Brand.divider),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: Row(children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                                color: _Brand.brandLight,
                                borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.help_outline_rounded,
                                color: _Brand.brand, size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Need help to connect?',
                                    style: TextStyle(
                                        color: _Brand.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14)),
                                SizedBox(height: 2),
                                Text('Learn how SMS login works',
                                    style: TextStyle(
                                        color: _Brand.textSecondary,
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                          Container(
                            width: 34, height: 34,
                            decoration: const BoxDecoration(
                                color: _Brand.brand, shape: BoxShape.circle),
                            child: const Icon(Icons.arrow_forward_rounded,
                                color: Colors.white, size: 16),
                          ),
                        ]),
                      ),
                    )),
                  ],
                ),
              ),
            ),

            // ── Bottom bar ────────────────────────────────────────────────
            Container(
              color: _Brand.card,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Divider(height: 1, thickness: 1, color: _Brand.divider),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  child: Column(children: [
                    RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        style: TextStyle(fontFamily: AppType.text,
                            color: _Brand.textHint, fontSize: 11, height: 1.5),
                        children: [
                          TextSpan(text: 'By continuing you agree to our '),
                          TextSpan(
                              text: 'Terms of Service',
                              style: TextStyle(
                                  color: _Brand.brand,
                                  fontWeight: FontWeight.w600)),
                          TextSpan(text: ' and '),
                          TextSpan(
                              text: 'Privacy Policy',
                              style: TextStyle(
                                  color: _Brand.brand,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _Brand.brand,
                          disabledBackgroundColor:
                              _Brand.brand.withOpacity(0.45),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          textStyle: const TextStyle(fontFamily: AppType.text,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5))
                            : const Text('Continue'),
                      ),
                    ),
                    if (_biometricReady) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: _biometricBusy || _isLoading ? null : _handleBiometric,
                          icon: _biometricBusy
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(
                                      color: _Brand.brand, strokeWidth: 2.2))
                              : const Icon(Icons.fingerprint_rounded, size: 24),
                          label: const Text('Sign in with biometrics'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _Brand.brand,
                            side: const BorderSide(color: _Brand.brand, width: 1.2),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            textStyle: const TextStyle(fontFamily: AppType.text,
                                fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ]),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
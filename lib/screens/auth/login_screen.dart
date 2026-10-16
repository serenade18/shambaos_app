import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/app_type.dart';
import '../../services/app_theme.dart';
import 'auth_ui.dart';
import 'package:flutter/services.dart';
import 'auth_service.dart';
import 'verify_otp_screen.dart';
import 'after_sign_in.dart';
import '../../l10n/tr.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Country model
// ─────────────────────────────────────────────────────────────────────────────
class _Country {
  final String flag;
  final String iso;
  final String name;
  final String dialCode;
  const _Country({required this.flag, required this.iso, required this.name, required this.dialCode});
}

List<_Country> get _countries => [
  _Country(flag: '🇰🇪', iso: 'KE', name: 'Kenya'.tr,        dialCode: '+254'),
  _Country(flag: '🇺🇬', iso: 'UG', name: 'Uganda'.tr,       dialCode: '+256'),
  _Country(flag: '🇹🇿', iso: 'TZ', name: 'Tanzania'.tr,     dialCode: '+255'),
  _Country(flag: '🇷🇼', iso: 'RW', name: 'Rwanda'.tr,       dialCode: '+250'),
  _Country(flag: '🇪🇹', iso: 'ET', name: 'Ethiopia'.tr,     dialCode: '+251'),
  _Country(flag: '🇳🇬', iso: 'NG', name: 'Nigeria'.tr,      dialCode: '+234'),
  _Country(flag: '🇬🇭', iso: 'GH', name: 'Ghana'.tr,        dialCode: '+233'),
  _Country(flag: '🇿🇦', iso: 'ZA', name: 'South Africa'.tr, dialCode: '+27'),
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
  bool    _googleAvailable = false;
  bool    _googleBusy      = false;
  // Set when someone new continued with Google: they add a phone number to finish.
  String? _googleTicket;
  String? _googleEmail;

  static const int _n = 5;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
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
    _checkGoogle();
  }

  void _goHome() => goHomeAfterSignIn(context);

  // ── Google sign-in ─────────────────────────────────────────────────────────
  Future<void> _checkGoogle() async {
    final available = await AuthService.isGoogleAvailable();
    if (mounted) setState(() => _googleAvailable = available);
  }

  Future<void> _handleGoogle() async {
    if (_googleBusy || _isLoading) return;
    setState(() { _googleBusy = true; _errorMsg = null; });

    final res = await AuthService.googleSignIn();
    if (!mounted) return;
    setState(() => _googleBusy = false);

    if (res.error) {
      if (res.message != AuthService.googleCancelled) {
        setState(() => _errorMsg = res.message ?? "Google sign-in didn't work. Try again.".tr);
      }
    } else if (res.data is Map && res.data['needs_phone'] == true) {
      setState(() {
        _googleTicket = res.data['google_ticket']?.toString();
        final email = res.data['email']?.toString() ?? '';
        _googleEmail = email.isEmpty ? null : email;
      });
      _phoneFocus.requestFocus();
    } else {
      _goHome();
    }
  }

  void _cancelGoogle() => setState(() { _googleTicket = null; _googleEmail = null; });

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
      _goHome();
    } else {
      final ready = await AuthService.canUseBiometricLogin();
      if (!mounted) return;
      setState(() {
        _biometricReady = ready;
        // A cancelled prompt needs no message.
        _errorMsg = res.message == 'Biometric check was cancelled.'.tr ? null : res.message;
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
            googleTicket: _googleTicket,
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
          ? res.data['message'] ?? 'Failed to send OTP. Try again.'.tr
          : res.message ?? 'Failed to send OTP. Try again.'.tr);
    }
  }

  void _showCountryPicker() {
    _phoneFocus.unfocus();
    showModalBottomSheet(
      context: context,
      backgroundColor: Ledger.sheet,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Ledger.radiusSheet))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 5, decoration: BoxDecoration(color: Ledger.rule, borderRadius: BorderRadius.circular(999))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Align(alignment: Alignment.centerLeft, child: Text('Select Country'.tr, style: Ledger.title.copyWith(fontSize: 19, height: 24 / 19))),
          ),
          for (final c in _countries)
            InkWell(
              onTap: () {
                setState(() => _selectedCountry = c);
                Navigator.pop(context);
              },
              child: Container(
                constraints: const BoxConstraints(minHeight: 56),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: c.dialCode == _selectedCountry.dialCode ? Ledger.shambaTint : null,
                  border: const Border(top: BorderSide(color: Ledger.rule)),
                ),
                child: Row(children: [
                  Text(c.flag, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(c.name, style: Ledger.label)),
                  Text('${c.iso} ${c.dialCode}', style: Ledger.code.copyWith(fontSize: 15, color: Ledger.inkMuted)),
                ]),
              ),
            ),
          const SizedBox(height: 12),
        ]),
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Ledger.sheet,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Need Help?'.tr, style: Ledger.title.copyWith(fontSize: 19, height: 24 / 19)),
        content: Text(
          'Enter your phone number (e.g. 0712 123456).\nWe\'ll send a 6-digit SMS code to log in or create your account.'.tr,
          style: Ledger.body,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Got it'.tr, style: Ledger.link)),
        ],
      ),
    );
  }

  // Shown while someone new who continued with Google adds their phone number.
  Widget _googleBanner() => Container(
        padding: const EdgeInsets.fromLTRB(14, 6, 4, 6),
        decoration: BoxDecoration(color: Ledger.shambaTint, borderRadius: BorderRadius.circular(Ledger.radiusField)),
        child: Row(children: [
          Image.asset('images/assets/google.png', width: 20, height: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _googleEmail != null
                  ? 'Continuing with Google as {googleEmail}'.trArgs({'googleEmail': _googleEmail})
                  : 'Continuing with Google'.tr,
              style: Ledger.caption.copyWith(color: Ledger.ink, fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            onPressed: _cancelGoogle,
            tooltip: 'Use phone only'.tr,
            icon: const LineIcon(LineIcon.x, size: 18, color: Ledger.inkMuted),
          ),
        ]),
      );

  // The sign-in screens keep their light design in both themes.
  @override
  Widget build(BuildContext context) =>
      Theme(data: AppTheme.light(), child: Builder(builder: _buildScreen));

  Widget _buildScreen(BuildContext context) {
    final google = _googleAvailable && _googleTicket == null;
    final others = google || _biometricReady;
    return Scaffold(
      backgroundColor: Ledger.paper,
      // The photo fills whatever the sheet leaves, running 28 under its rounded top.
      body: CustomMultiChildLayout(delegate: _PhotoAndSheet(), children: [
        LayoutId(
          id: _PhotoAndSheet.photo,
          child: Stack(fit: StackFit.expand, children: [
            Semantics(
              image: true,
              label: 'A farmer weeding young plants with her child on her back'.tr,
              child: Image.asset('images/auth/farming.jpg', fit: BoxFit.cover, alignment: Alignment.topCenter),
            ),
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 200,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x8C17211A), Color(0x0017211A)],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: _stagger(0, Row(children: [
                    const LeafLogo(size: 40),
                    const SizedBox(width: 10),
                    const Text('Shamba OS',
                        style: TextStyle(fontFamily: AppType.text, fontSize: 20, height: 24 / 20, fontWeight: FontWeight.w700, color: Colors.white)),
                  ])),
                ),
              ),
            ),
          ]),
        ),

        // ── The sheet ──────────────────────────────────────────
        LayoutId(
          id: _PhotoAndSheet.sheet,
          child: SingleChildScrollView(
            child: _stagger(1, Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              decoration: const BoxDecoration(
                color: Ledger.sheet,
                borderRadius: BorderRadius.vertical(top: Radius.circular(Ledger.radiusSheet)),
                boxShadow: Ledger.shadowSheet,
              ),
              child: SafeArea(
                top: false,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text('KARIBU · WELCOME'.tr, style: Ledger.eyebrow),
                  const SizedBox(height: 6),
                  Text(_googleTicket != null ? 'One more step'.tr : 'Sign in with your phone'.tr, style: Ledger.title),
                  const SizedBox(height: 6),
                  Text(
                    _googleTicket != null
                        ? 'Add your phone number to finish setting up your account'.tr
                        : 'We will send a 6-digit code by SMS.'.tr,
                    style: Ledger.body,
                  ),
                  if (_googleTicket != null) ...[
                    const SizedBox(height: 16),
                    _googleBanner(),
                  ],
                  const SizedBox(height: 16),

                  // Phone number, with the country code in front
                  LedgerField(
                    label: 'Phone number'.tr,
                    focused: _phoneFocus.hasFocus,
                    error: _errorMsg,
                    prefix: Semantics(
                      button: true,
                      label: 'Country code {code}. Change country'.trArgs({'code': _selectedCountry.dialCode}),
                      child: GestureDetector(
                        onTap: _showCountryPicker,
                        behavior: HitTestBehavior.opaque,
                        child: ExcludeSemantics(
                          child: Text('${_selectedCountry.iso} ${_selectedCountry.dialCode}',
                              style: Ledger.code.copyWith(fontSize: 17, letterSpacing: 0)),
                        ),
                      ),
                    ),
                    input: TextField(
                      controller: _phoneCtrl,
                      focusNode: _phoneFocus,
                      keyboardType: TextInputType.phone,
                      autofillHints: const [AutofillHints.telephoneNumberNational],
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      onChanged: (_) {
                        if (_errorMsg != null) setState(() => _errorMsg = null);
                      },
                      onSubmitted: (_) => _handleContinue(),
                      style: Ledger.code,
                      cursorColor: Ledger.shamba,
                      decoration: InputDecoration(
                        hintText: '712 345 678',
                        hintStyle: Ledger.code.copyWith(color: Ledger.inkFaint),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        filled: false,
                        isCollapsed: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  LedgerButton(label: 'Continue'.tr, busy: _isLoading, onPressed: _handleContinue),

                  if (others) ...[
                    const SizedBox(height: 16),
                    Row(children: [
                      const Expanded(child: Divider(height: 1, thickness: 1, color: Ledger.rule)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('or'.tr, style: Ledger.caption.copyWith(color: Ledger.inkFaint)),
                      ),
                      const Expanded(child: Divider(height: 1, thickness: 1, color: Ledger.rule)),
                    ]),
                    const SizedBox(height: 16),
                    Row(children: [
                      if (google)
                        Expanded(
                          child: LedgerButton(
                            label: 'Continue with Google'.tr,
                            kind: LedgerButtonKind.secondary,
                            large: false,
                            busy: _googleBusy,
                            onPressed: _isLoading ? null : _handleGoogle,
                          ),
                        ),
                      if (google && _biometricReady) const SizedBox(width: 10),
                      if (_biometricReady)
                        SizedBox(
                          width: google ? 56 : null,
                          child: google
                              ? LedgerButton(
                                  label: '',
                                  semanticLabel: 'Sign in with biometrics'.tr,
                                  kind: LedgerButtonKind.secondary,
                                  large: false,
                                  busy: _biometricBusy,
                                  icon: const LineIcon(LineIcon.fingerprint),
                                  onPressed: _isLoading ? null : _handleBiometric,
                                )
                              : null,
                        ),
                      if (_biometricReady && !google)
                        Expanded(
                          child: LedgerButton(
                            label: 'Sign in with biometrics'.tr,
                            kind: LedgerButtonKind.secondary,
                            large: false,
                            busy: _biometricBusy,
                            icon: const LineIcon(LineIcon.fingerprint),
                            onPressed: _isLoading ? null : _handleBiometric,
                          ),
                        ),
                    ]),
                  ],
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: _showHelp,
                      style: TextButton.styleFrom(minimumSize: const Size(0, 32), foregroundColor: Ledger.shambaInk),
                      child: Text('Need help to connect?'.tr, style: Ledger.link),
                    ),
                  ),
                ]),
              ),
            )),
          ),
        ),
      ]),
    );
  }
}

/// Lays the sheet at the bottom at its own height, and the photo above it,
/// reaching 28 under the sheet so the rounded corners show the photo.
class _PhotoAndSheet extends MultiChildLayoutDelegate {
  static const photo = 'photo';
  static const sheet = 'sheet';

  @override
  void performLayout(Size size) {
    final sheetSize = layoutChild(sheet, BoxConstraints(maxWidth: size.width, minWidth: size.width, maxHeight: size.height));
    positionChild(sheet, Offset(0, size.height - sheetSize.height));
    final photoHeight = (size.height - sheetSize.height + Ledger.radiusSheet).clamp(0.0, size.height);
    layoutChild(photo, BoxConstraints.tight(Size(size.width, photoHeight)));
    positionChild(photo, Offset.zero);
  }

  @override
  bool shouldRelayout(covariant MultiChildLayoutDelegate oldDelegate) => false;
}

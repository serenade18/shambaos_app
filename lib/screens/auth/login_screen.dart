import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/app_type.dart';
import '../../services/app_theme.dart';
import 'auth_ui.dart';
import 'package:flutter/services.dart';
import 'auth_service.dart';
import 'verify_otp_screen.dart';
import 'after_sign_in.dart';
import 'countries.dart';
import 'forgot_password_sheet.dart';
import 'sign_up_screen.dart';
import '../../l10n/tr.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LOGIN SCREEN  (phone + SMS code in Kenya; username or email and password elsewhere)
// ─────────────────────────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  Country _country = countries.first;
  final _phoneCtrl  = TextEditingController();
  final _phoneFocus = FocusNode();
  // Outside Kenya: username or email, and password.
  final _idCtrl     = TextEditingController();
  final _idFocus    = FocusNode();
  final _pwCtrl     = TextEditingController();
  final _pwFocus    = FocusNode();

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
    _idFocus.addListener(() => setState(() {}));
    _pwFocus.addListener(() => setState(() {}));
    _loadCountry();
    _checkBiometric();
    _checkGoogle();
  }

  Future<void> _loadCountry() async {
    final country = await initialCountry();
    if (mounted) setState(() => _country = country);
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
    } else if (res.data is Map && res.data['needs_phone'] == true && !_country.signsInBySms) {
      // A new account needs an SMS code, which only Kenyan numbers get.
      setState(() => _errorMsg = 'No account uses this Google account yet. Create one with your email below.'.tr);
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
    _idCtrl.dispose();
    _idFocus.dispose();
    _pwCtrl.dispose();
    _pwFocus.dispose();
    super.dispose();
  }

  Widget _stagger(int i, Widget child) => SlideTransition(
      position: _slideAnims[i],
      child: FadeTransition(opacity: _fadeAnims[i], child: child));

  // ── Request OTP ────────────────────────────────────────────────────────────
  Future<void> _handleContinue() async {
    final raw = _phoneCtrl.text.trim();
    if (raw.isEmpty) {
      _phoneFocus.requestFocus();
      return;
    }

    setState(() { _isLoading = true; _errorMsg = null; });

    final phone = _country.e164(raw);
    final res   = await AuthService.requestOtp(phone: phone);

    if (!mounted) return;
    setState(() => _isLoading = false);

    final sent = res.data is Map ? res.data['sent'] == true : false;

    if (!res.error && sent) {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => VerifyOtpScreen(
            phone: phone,
            displayPhone: '${_country.dialCode} $raw',
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

  // ── Username or email, and password ───────────────────────────────────────
  Future<void> _handlePasswordSignIn() async {
    final id = _idCtrl.text.trim();
    if (id.isEmpty) return _idFocus.requestFocus();
    if (_pwCtrl.text.isEmpty) return _pwFocus.requestFocus();

    setState(() { _isLoading = true; _errorMsg = null; });
    final res = await AuthService.login(email: id, password: _pwCtrl.text);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!res.error) {
      _goHome();
    } else {
      setState(() => _errorMsg = res.message ?? "Couldn't sign in. Try again.".tr);
    }
  }

  Future<void> _openSignUp() async {
    final username = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => SignUpScreen(country: _country)),
    );
    // Back from "Check your email": ready to sign in once the link is opened.
    if (username != null && username.isNotEmpty && mounted) {
      setState(() => _idCtrl.text = username);
      _pwFocus.requestFocus();
    }
  }

  Future<void> _showCountryPicker() async {
    final picked = await showCountryPicker(context, _country);
    if (picked == null || !mounted) return;
    setState(() {
      _country = picked;
      _errorMsg = null;
      if (!picked.signsInBySms) { _googleTicket = null; _googleEmail = null; }
    });
    saveCountry(picked);
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Ledger.sheet,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Need Help?'.tr, style: Ledger.title.copyWith(fontSize: 19, height: 24 / 19)),
        content: Text(
          _country.signsInBySms
              ? 'Enter your phone number (e.g. 0712 123456).\nWe\'ll send a 6-digit SMS code to log in or create your account.'.tr
              : 'Sign in with your username or email and password. New here? Create an account and we\'ll email you a link to start it.'.tr,
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
    final sms = _country.signsInBySms;
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
                  Text(
                    _googleTicket != null
                        ? 'One more step'.tr
                        : sms ? 'Sign in with your phone'.tr : 'Sign in to Shamba OS'.tr,
                    style: Ledger.title,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _googleTicket != null
                        ? 'Add your phone number to finish setting up your account'.tr
                        : sms ? 'We will send a 6-digit code by SMS.'.tr : 'Use your username or email, and your password.'.tr,
                    style: Ledger.body,
                  ),
                  if (_googleTicket != null) ...[
                    const SizedBox(height: 16),
                    _googleBanner(),
                  ],
                  const SizedBox(height: 16),

                  // Where they farm decides how they sign in
                  LedgerField(
                    label: 'Country'.tr,
                    input: Semantics(
                      button: true,
                      label: 'Country {name}. Change country'.trArgs({'name': _country.name}),
                      child: InkWell(
                        onTap: _showCountryPicker,
                        child: ExcludeSemantics(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Row(children: [
                              Text(_country.flag, style: const TextStyle(fontSize: 22)),
                              const SizedBox(width: 10),
                              Expanded(child: Text(_country.name, style: Ledger.input, overflow: TextOverflow.ellipsis)),
                              const LineIcon(LineIcon.chevronDown, size: 20, color: Ledger.inkMuted),
                            ]),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (sms) ...[
                    // Phone number, with the country code in front
                    LedgerField(
                      label: 'Phone number'.tr,
                      focused: _phoneFocus.hasFocus,
                      error: _errorMsg,
                      prefix: Semantics(
                        button: true,
                        label: 'Country code {code}. Change country'.trArgs({'code': _country.dialCode}),
                        child: GestureDetector(
                          onTap: _showCountryPicker,
                          behavior: HitTestBehavior.opaque,
                          child: ExcludeSemantics(
                            child: Text(_country.dialLabel, style: Ledger.code.copyWith(fontSize: 17, letterSpacing: 0)),
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
                        decoration: Ledger.bare('712 345 678', style: Ledger.code),
                      ),
                    ),
                    const SizedBox(height: 16),
                    LedgerButton(label: 'Continue'.tr, busy: _isLoading, onPressed: _handleContinue),
                  ] else
                    AutofillGroup(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        LedgerField(
                          label: 'Username or email'.tr,
                          focused: _idFocus.hasFocus,
                          input: TextField(
                            controller: _idCtrl,
                            focusNode: _idFocus,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.username, AutofillHints.email],
                            autocorrect: false,
                            textInputAction: TextInputAction.next,
                            onChanged: (_) {
                              if (_errorMsg != null) setState(() => _errorMsg = null);
                            },
                            onSubmitted: (_) => _pwFocus.requestFocus(),
                            style: Ledger.input,
                            cursorColor: Ledger.shamba,
                            decoration: Ledger.bare(''),
                          ),
                        ),
                        const SizedBox(height: 16),
                        LedgerField(
                          label: 'Password'.tr,
                          focused: _pwFocus.hasFocus,
                          error: _errorMsg,
                          input: PasswordInput(
                            controller: _pwCtrl,
                            focusNode: _pwFocus,
                            onChanged: (_) {
                              if (_errorMsg != null) setState(() => _errorMsg = null);
                            },
                            onSubmitted: (_) => _handlePasswordSignIn(),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => showForgotPassword(context, email: _idCtrl.text.trim()),
                            style: TextButton.styleFrom(minimumSize: const Size(0, 40), foregroundColor: Ledger.shambaInk),
                            child: Text('Forgot password?'.tr, style: Ledger.link),
                          ),
                        ),
                        LedgerButton(label: 'Sign in'.tr, busy: _isLoading, onPressed: _handlePasswordSignIn),
                      ]),
                    ),

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
                  if (!sms) ...[
                    const SizedBox(height: 16),
                    LedgerButton(
                      label: 'Create an account'.tr,
                      kind: LedgerButtonKind.secondary,
                      large: false,
                      onPressed: _isLoading ? null : _openSignUp,
                    ),
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

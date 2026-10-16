import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/app_theme.dart';
import 'auth_service.dart';
import 'auth_ui.dart';
import '../home_screen.dart';
import 'package:sms_autofill/sms_autofill.dart';
import '../../l10n/tr.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String phone;        // E.164 e.g. +254712123456  (sent to API)
  final String displayPhone; // Formatted for display e.g. +254 712 123456
  final String? googleTicket; // Someone new who continued with Google

  const VerifyOtpScreen({
    super.key,
    required this.phone,
    required this.displayPhone,
    this.googleTicket,
  });

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen>
    with SingleTickerProviderStateMixin, CodeAutoFill {
  final _codeCtrl = TextEditingController();
  final _codeFocus = FocusNode();

  late final AnimationController _animCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  late final Animation<double> _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
  late final Animation<Offset> _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
      .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));

  bool _isVerifying = false;
  bool _isResending = false;
  String? _errorMsg;

  int _resendSeconds = 60;
  Timer? _countdownTimer;

  // ── Lifecycle ───────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));
    Future.delayed(const Duration(milliseconds: 200), listenForCode);
    _animCtrl.forward();
    _startCountdown();
    _codeFocus.addListener(() => setState(() {}));
  }

  // ── SMS autofill callback ───────────────────────────────────────────────────
  @override
  void codeUpdated() {
    final receivedCode = code;
    if (receivedCode == null || receivedCode.length != 6) return;
    _codeCtrl.text = receivedCode;
    if (mounted) FocusScope.of(context).unfocus();
    _verifyOtp();
  }

  @override
  void dispose() {
    cancel();
    _countdownTimer?.cancel();
    _codeCtrl.dispose();
    _codeFocus.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  // ── Countdown timer ─────────────────────────────────────────────────────────
  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _resendSeconds = 60);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _resendSeconds--);
      if (_resendSeconds <= 0) t.cancel();
    });
  }

  String get _otpValue => _codeCtrl.text.replaceAll(' ', '');

  void _onCodeChanged(String _) {
    if (_errorMsg != null) setState(() => _errorMsg = null);
    setState(() {}); // the button follows the code's length
    if (_otpValue.length == 6 && !_isVerifying) _verifyOtp();
  }

  // ── Verify OTP ──────────────────────────────────────────────────────────────
  Future<void> _verifyOtp() async {
    final otp = _otpValue;
    if (otp.length < 6 || _isVerifying) return;

    setState(() { _isVerifying = true; _errorMsg = null; });

    final res = await AuthService.verifyOtp(
        phone: widget.phone, otp: otp, googleTicket: widget.googleTicket);

    if (!mounted) return;
    setState(() => _isVerifying = false);

    if (res.statusCode == 200 && !res.error) {
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
      _codeCtrl.clear();
      _codeFocus.requestFocus();
      setState(() => _errorMsg = res.message ?? 'Invalid code. Please try again.'.tr);
    }
  }

  // ── Resend OTP ──────────────────────────────────────────────────────────────
  Future<void> _resendOtp() async {
    if (_resendSeconds > 0 || _isResending) return;

    setState(() { _isResending = true; _errorMsg = null; });
    _codeCtrl.clear();

    final res = await AuthService.requestOtp(phone: widget.phone);

    if (!mounted) return;
    setState(() => _isResending = false);

    if (!res.error) {
      _startCountdown();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Ledger.shamba,
        content: Text('New code sent!'.tr),
      ));
    } else {
      setState(() => _errorMsg = res.message ?? 'Could not resend. Try again.'.tr);
    }
  }

  String get _countdown =>
      '${_resendSeconds ~/ 60}:${(_resendSeconds % 60).toString().padLeft(2, '0')}';

  // ── Build ───────────────────────────────────────────────────────────────────
  // The sign-in screens keep their light design in both themes.
  @override
  Widget build(BuildContext context) =>
      Theme(data: AppTheme.light(), child: Builder(builder: _buildScreen));

  Widget _buildScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: Ledger.paper,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              // ── Back ───────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Semantics(
                    button: true,
                    label: 'Back'.tr,
                    child: Container(
                      decoration: const BoxDecoration(color: Ledger.sheet, shape: BoxShape.circle, boxShadow: Ledger.shadowSoft),
                      child: Material(
                        type: MaterialType.transparency,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => Navigator.pop(context),
                          child: const SizedBox(width: 44, height: 44, child: Center(child: LineIcon(LineIcon.arrowLeft))),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(color: Ledger.shambaTint, shape: BoxShape.circle),
                        child: const Center(child: LineIcon(LineIcon.phone, size: 30, color: Ledger.shambaInk)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('Enter the 6-digit code'.tr, style: Ledger.title),
                    const SizedBox(height: 6),
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(text: 'Sent by SMS to'.tr),
                        const TextSpan(text: ' '),
                        TextSpan(text: widget.displayPhone, style: Ledger.code.copyWith(fontSize: 17, height: 26 / 17, letterSpacing: 0)),
                      ]),
                      style: Ledger.body.copyWith(fontSize: 17, height: 26 / 17),
                    ),
                    const SizedBox(height: 20),

                    // ── The code ─────────────────────────────────────────────
                    LedgerField(
                      label: 'Sign-in code'.tr,
                      focused: _codeFocus.hasFocus,
                      error: _errorMsg,
                      hint: 'This code expires in 10 minutes. Never share it with anyone.'.tr,
                      input: Center(
                        child: TextField(
                          controller: _codeCtrl,
                          focusNode: _codeFocus,
                          autofocus: true,
                          keyboardType: TextInputType.number,
                          autofillHints: const [AutofillHints.oneTimeCode],
                          textAlign: TextAlign.center,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          onChanged: _onCodeChanged,
                          style: Ledger.code.copyWith(fontSize: 26, height: 1.2, letterSpacing: 5.2),
                          cursorColor: Ledger.shamba,
                          decoration: InputDecoration(
                            hintText: '••••••',
                            hintStyle: Ledger.code.copyWith(fontSize: 26, height: 1.2, letterSpacing: 5.2, color: Ledger.inkFaint),
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            filled: false,
                            isCollapsed: true,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Resend ───────────────────────────────────────────────
                    Row(children: [
                      Expanded(child: Text("Didn't get it?".tr, style: Ledger.caption)),
                      if (_isResending)
                        const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Ledger.shamba, strokeWidth: 2))
                      else if (_resendSeconds > 0)
                        Text('Resend in {time}'.trArgs({'time': _countdown}), style: Ledger.caption)
                      else
                        TextButton(
                          onPressed: _resendOtp,
                          style: TextButton.styleFrom(minimumSize: const Size(0, 32), padding: EdgeInsets.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                          child: Text('Resend code'.tr, style: Ledger.link),
                        ),
                    ]),
                  ]),
                ),
              ),

              // ── Verify ─────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                child: LedgerButton(
                  label: 'Verify and sign in'.tr,
                  busy: _isVerifying,
                  onPressed: _otpValue.length < 6 ? null : _verifyOtp,
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

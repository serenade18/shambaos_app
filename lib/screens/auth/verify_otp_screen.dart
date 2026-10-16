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
                    Text('Sign-in code'.tr, style: Ledger.label),
                    const SizedBox(height: 6),
                    _CodeBoxes(
                      controller: _codeCtrl,
                      focusNode: _codeFocus,
                      hasError: _errorMsg != null,
                      onChanged: _onCodeChanged,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _errorMsg ?? 'This code expires in 10 minutes. Never share it with anyone.'.tr,
                      style: Ledger.caption.copyWith(color: _errorMsg != null ? Ledger.dangerInk : Ledger.inkMuted),
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

/// The code as six boxes, a wider gap after the third. One invisible field
/// underneath takes the typing, so SMS autofill, paste and backspace work as in
/// any text field; the boxes only show its digits.
class _CodeBoxes extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final ValueChanged<String> onChanged;

  const _CodeBoxes({required this.controller, required this.focusNode, required this.hasError, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Stack(children: [
        ExcludeSemantics(
          child: ListenableBuilder(
            listenable: Listenable.merge([controller, focusNode]),
            builder: (_, _) {
              final digits = controller.text;
              // The box the next digit goes in; the last one once all six are in.
              final current = focusNode.hasFocus ? digits.length.clamp(0, 5) : -1;
              return Row(children: [
                for (var i = 0; i < 6; i++) ...[
                  if (i > 0) SizedBox(width: i == 3 ? 16 : 8),
                  Expanded(child: _box(i < digits.length ? digits[i] : '', i == current, i < digits.length)),
                ],
              ]);
            },
          ),
        ),
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              onChanged: onChanged,
              showCursor: false,
              decoration: InputDecoration(
                labelText: 'Sign-in code'.tr,
                border: InputBorder.none,
                counterText: '',
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _box(String digit, bool focused, bool filled) {
    final border = hasError
        ? Ledger.dangerInk
        : filled || focused
            ? Ledger.shambaInk
            : Ledger.ruleStrong;
    return Container(
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Ledger.sheet,
        borderRadius: BorderRadius.circular(Ledger.radiusField),
        border: Border.all(color: border, width: 1.5),
        // The 3px focus ring.
        boxShadow: focused && !hasError ? const [BoxShadow(color: Ledger.focus, spreadRadius: 3)] : null,
      ),
      child: Text(digit, style: Ledger.code.copyWith(fontSize: 26, height: 1, letterSpacing: 0)),
    );
  }
}

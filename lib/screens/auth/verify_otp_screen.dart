import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'auth_service.dart';
import '../home_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Brand tokens (keep in sync with login_screen.dart)
// ─────────────────────────────────────────────────────────────────────────────
class _Brand {
  static const Color brand         = Color(0xFF4CAF50);
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

class VerifyOtpScreen extends StatefulWidget {
  final String phone;        // E.164 e.g. +254712123456  (sent to API)
  final String displayPhone; // Formatted for display e.g. +254 712 123456

  const VerifyOtpScreen({
    super.key,
    required this.phone,
    required this.displayPhone,
  });

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _ctrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _foci = List.generate(6, (_) => FocusNode());

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  bool _isVerifying = false;
  bool _isResending = false;
  String? _errorMsg;

  int _resendSeconds = 60;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));

    _animCtrl.forward();
    _startCountdown();

    for (final c in _ctrls) {
      c.addListener(_onDigitChanged);
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    for (final c in _ctrls) { c.removeListener(_onDigitChanged); c.dispose(); }
    for (final f in _foci) { f.dispose(); }
    _animCtrl.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _resendSeconds = 60);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _resendSeconds--);
      if (_resendSeconds <= 0) t.cancel();
    });
  }

  String get _otpValue => _ctrls.map((c) => c.text).join();

  void _onDigitChanged() {
    if (_otpValue.length == 6 && !_isVerifying) {
      _verifyOtp();
    }
  }

  void _onKey(int index, String value) {
    if (value.length == 6) {
      for (int i = 0; i < 6; i++) _ctrls[i].text = value[i];
      _foci[5].requestFocus();
      return;
    }
    if (value.isNotEmpty && index < 5) _foci[index + 1].requestFocus();
  }

  void _onBackspace(int index) {
    if (_ctrls[index].text.isEmpty && index > 0) {
      _ctrls[index - 1].clear();
      _foci[index - 1].requestFocus();
    }
  }

  // ── Verify OTP ─────────────────────────────────────────────────────────────
  Future<void> _verifyOtp() async {
    final otp = _otpValue;
    if (otp.length < 6) return;

    setState(() { _isVerifying = true; _errorMsg = null; });

    final res = await AuthService.verifyOtp(phone: widget.phone, otp: otp);

    if (!mounted) return;
    setState(() => _isVerifying = false);

    if (res.error) {
      // ✅ Navigate to HomeScreen — clear the entire auth stack
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
        (_) => false, // removes all previous routes (login + otp)
      );
    } else {
      // Clear boxes and refocus on error
      for (final c in _ctrls) { c.clear(); }
      _foci[0].requestFocus();
      setState(() => _errorMsg = res.message ?? 'Invalid code. Please try again.');
    }
  }

  // ── Resend OTP ─────────────────────────────────────────────────────────────
  Future<void> _resendOtp() async {
    if (_resendSeconds > 0 || _isResending) return;

    setState(() { _isResending = true; _errorMsg = null; });
    for (final c in _ctrls) { c.clear(); }

    final res = await AuthService.requestOtp(phone: widget.phone);

    if (!mounted) return;
    setState(() => _isResending = false);

    if (res.error) {
      _startCountdown();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: _Brand.brand,
        content: Text('New code sent!'),
      ));
    } else {
      setState(() => _errorMsg = res.message ?? 'Could not resend. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Brand.scaffold,
      appBar: AppBar(
        backgroundColor: _Brand.card,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _Brand.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Verification',
            style: TextStyle(color: _Brand.textPrimary, fontSize: 16,
                fontWeight: FontWeight.w700)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: _Brand.divider),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Column(
              children: [
                // ── Header card ──────────────────────────────────────────
                Container(
                  width: double.infinity,
                  color: _Brand.card,
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                            color: _Brand.brandLight,
                            shape: BoxShape.circle,
                            border: Border.all(color: _Brand.brandBorder, width: 1.5)),
                        child: const Icon(Icons.sms_outlined,
                            color: _Brand.brand, size: 30),
                      ),
                      const SizedBox(height: 16),
                      const Text('Enter the 6-digit code',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800,
                              color: _Brand.textPrimary, height: 1.2)),
                      const SizedBox(height: 8),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: const TextStyle(fontSize: 14,
                              color: _Brand.textSecondary, height: 1.5),
                          children: [
                            const TextSpan(text: 'Sent via SMS to\n'),
                            TextSpan(
                              text: widget.displayPhone,
                              style: const TextStyle(
                                  color: _Brand.textPrimary, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, thickness: 1, color: _Brand.divider),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
                    child: Column(
                      children: [
                        // ── OTP boxes ────────────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(6, (i) => _OtpBox(
                            controller: _ctrls[i],
                            focusNode: _foci[i],
                            hasError: _errorMsg != null,
                            onChanged: (v) => _onKey(i, v),
                            onBackspace: () => _onBackspace(i),
                          )),
                        ),

                        if (_errorMsg != null) ...[
                          const SizedBox(height: 12),
                          Row(children: [
                            const Icon(Icons.error_outline_rounded,
                                color: _Brand.errorRed, size: 15),
                            const SizedBox(width: 6),
                            Expanded(child: Text(_errorMsg!,
                                style: const TextStyle(
                                    color: _Brand.errorRed, fontSize: 12))),
                          ]),
                        ],

                        const SizedBox(height: 32),

                        // ── Resend row ────────────────────────────────────
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Text("Didn't receive a code? ",
                              style: TextStyle(color: _Brand.textSecondary, fontSize: 13)),
                          _isResending
                              ? const SizedBox(width: 16, height: 16,
                                  child: CircularProgressIndicator(
                                      color: _Brand.brand, strokeWidth: 2))
                              : GestureDetector(
                                  onTap: _resendSeconds > 0 ? null : _resendOtp,
                                  child: Text(
                                    _resendSeconds > 0
                                        ? 'Resend in ${_resendSeconds}s'
                                        : 'Resend',
                                    style: TextStyle(
                                      color: _resendSeconds > 0
                                          ? _Brand.textHint
                                          : _Brand.brand,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                        ]),

                        const SizedBox(height: 28),

                        // ── Security note ─────────────────────────────────
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _Brand.brandLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _Brand.brandBorder),
                          ),
                          child: Row(children: [
                            const Icon(Icons.info_outline_rounded,
                                color: _Brand.brand, size: 18),
                            const SizedBox(width: 10),
                            const Expanded(child: Text(
                              'This code expires in 10 minutes.\nNever share it with anyone.',
                              style: TextStyle(color: _Brand.brand,
                                  fontSize: 12, height: 1.5),
                            )),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Verify button ─────────────────────────────────────────
                Container(
                  color: _Brand.card,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Divider(height: 1, thickness: 1, color: _Brand.divider),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                      child: SizedBox(
                        width: double.infinity, height: 52,
                        child: ElevatedButton(
                          onPressed: (_isVerifying || _otpValue.length < 6)
                              ? null
                              : _verifyOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _Brand.brand,
                            disabledBackgroundColor: _Brand.brand.withOpacity(0.35),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            textStyle: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                          child: _isVerifying
                              ? const SizedBox(width: 22, height: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5))
                              : const Text('Verify & Sign In'),
                        ),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single OTP digit box widget
// ─────────────────────────────────────────────────────────────────────────────
class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspace;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.onChanged,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46, height: 56,
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (e) {
          if (e is KeyDownEvent &&
              e.logicalKey == LogicalKeyboardKey.backspace) {
            onBackspace();
          }
        },
        child: AnimatedBuilder(
          animation: focusNode,
          builder: (_, __) {
            final isFocused = focusNode.hasFocus;
            return TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: onChanged,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800,
                  color: _Brand.textPrimary),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: isFocused ? _Brand.brandLight : _Brand.card,
                contentPadding: EdgeInsets.zero,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: hasError ? _Brand.errorRed : _Brand.divider,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: hasError ? _Brand.errorRed : _Brand.brand,
                    width: 2,
                  ),
                ),
              ),
              cursorColor: _Brand.brand,
              cursorWidth: 1.5,
            );
          },
        ),
      ),
    );
  }
}
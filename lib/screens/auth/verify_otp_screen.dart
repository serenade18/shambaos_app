import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'set_password_screen.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String email;

  const VerifyOtpScreen({super.key, required this.email});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _secondsRemaining = 60;
  bool _canResend = false;
  Timer? _timer;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 60;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        timer.cancel();
        setState(() => _canResend = true);
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  @override
  void dispose() {
    for (var c in _controllers) c.dispose();
    for (var f in _focusNodes) f.dispose();
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _onOtpChanged(String value, int index) {
    // If a value is typed, move to next
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } 
    // If value is deleted, move to previous
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    
    // Auto-verify if 6th digit is reached
    if (_otpCode.length == 6) {
      _handleVerify();
    }
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ── Background & Gradient ──
          SizedBox.expand(child: Image.asset('images/auth/plain.jpg', fit: BoxFit.cover)),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withOpacity(0.2), Colors.black.withOpacity(0.5)],
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.07),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.17),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.5),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildHeaderIcon(),
                            const SizedBox(height: 24),
                            const Text("Verify Email", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
                            const SizedBox(height: 10),
                            Text("We sent a 6-digit code to", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                            Text(widget.email, style: const TextStyle(color: Color(0xFF3DBE6E), fontWeight: FontWeight.bold)),
                            const SizedBox(height: 32),

                            // 🔢 SCALABLE OTP Grid
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(6, (index) {
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: _buildOtpBox(index),
                                  ),
                                );
                              }),
                            ),

                            const SizedBox(height: 32),
                            _buildTimerSection(),
                            const SizedBox(height: 32),
                            _buildVerifyButton(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          _buildBackButton(),
        ],
      ),
    );
  }

  // ── Helper Widgets ──

  Widget _buildHeaderIcon() {
    return Container(
      height: 80,
      width: 80,
      decoration: BoxDecoration(
        color: const Color(0xFF3DBE6E).withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF3DBE6E).withOpacity(0.5), width: 2),
      ),
      child: const Icon(Icons.mark_email_read_outlined, size: 40, color: Colors.white),
    );
  }

  Widget _buildTimerSection() {
    return _canResend
        ? GestureDetector(
            onTap: _startTimer,
            child: const Text("Didn't receive code? Resend",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          )
        : Text(
            "Resend code in 0:${_secondsRemaining.toString().padLeft(2, '0')}",
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
          );
  }

  Widget _buildVerifyButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _handleVerify,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3DBE6E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: const Text("Verify Code",
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildBackButton() {
    return Positioned(
      top: 50,
      left: 20,
      child: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: AspectRatio(
          aspectRatio: 0.85,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                // We use alignment center here to help the TextField's position
                alignment: Alignment.center,
                child: RawKeyboardListener(
                  focusNode: FocusNode(),
                  onKey: (event) {
                    if (event.runtimeType == RawKeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.backspace &&
                        _controllers[index].text.isEmpty &&
                        index > 0) {
                      _focusNodes[index - 1].requestFocus();
                    }
                  },
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    textAlign: TextAlign.center,
                    // 🎯 FIX 1: Explicitly center the text vertically
                    textAlignVertical: TextAlignVertical.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.055,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      // 🎯 FIX 2: Ensure the height of the text doesn't add extra leading/padding
                      height: 1, 
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      counterText: "",
                      // 🎯 FIX 3: Remove all default padding that pushes text down
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (val) => _onOtpChanged(val, index),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleVerify() {
    if (_otpCode.length == 6) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SetPasswordScreen(email: widget.email, code: _otpCode),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the complete 6-digit code")),
      );
    }
  }
}
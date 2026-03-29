import 'dart:ui';
import 'package:flutter/material.dart';
import 'verify_otp_screen.dart';
import 'auth_service.dart';
import '../../widgets/auth_dialog.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ── Background (Consistent with Auth Flow) ──
          SizedBox.expand(
            child: Image.asset(
              'images/auth/mountains.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // ── Darker Gradient for Readability ──
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.2),
                  Colors.black.withOpacity(0.5),
                ],
              ),
            ),
          ),

          // ── Main Content ──
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
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.17),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.35),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 🔑 Icon Header
                            Container(
                              height: 80,
                              width: 80,
                              decoration: BoxDecoration(
                                color: const Color(0xFF3DBE6E).withOpacity(0.2),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF3DBE6E).withOpacity(0.5),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.lock_reset_rounded,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),

                            const SizedBox(height: 24),

                            const Text(
                              "Forgot Password?",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),

                            const SizedBox(height: 10),

                            Text(
                              "Enter your email address and we'll send\nyou a reset code to get back in.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.75),
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),

                            const SizedBox(height: 32),

                            // ── Glass Email Field ──
                            _buildGlassField(
                              controller: _emailController,
                              hint: "Email address",
                              icon: Icons.email_outlined,
                            ),

                            const SizedBox(height: 24),

                            // ── Send Button ──
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleSendCode,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3DBE6E),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        "Send Reset Code",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // ── Back to Login Link ──
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Text.rich(
                                TextSpan(
                                  text: "Remembered? ",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.75),
                                    fontSize: 13,
                                  ),
                                  children: const [
                                    TextSpan(
                                      text: "Back to Sign In",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Back Button (Positioned at top) ──
          Positioned(
            top: 50,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // REUSABLE GLASS FIELD (Matches Login/Register)
  // ─────────────────────────────────────────────
  Widget _buildGlassField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.30),
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontSize: 14,
              ),
              prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.6), size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
            ),
          ),
        ),
      ),
    );
  }

  // ── Logic ──
  Future<void> _handleSendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      AuthDialog.show(
        context,
        type: AuthDialogType.error,
        title: 'Missing Email',
        message: 'Please enter your email address to continue.',
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await AuthService.forgotPassword(email: email);
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (response.success) {
        AuthDialog.show(
          context,
          type: AuthDialogType.success,
          title: 'Code Sent',
          message: response.message ?? 'Check your inbox for the reset code.',
          onDone: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => VerifyOtpScreen(email: email)),
            );
          },
        );
      } else {
        AuthDialog.show(
          context,
          type: AuthDialogType.error,
          title: 'Request Failed',
          message: response.message ?? 'We couldn\'t find an account with that email.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AuthDialog.show(
          context,
          type: AuthDialogType.error,
          title: 'Network Error',
          message: 'Please check your connection and try again.',
        );
      }
    }
  }
}
import 'dart:ui';
import 'package:flutter/material.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'auth_service.dart';
import '../../widgets/auth_dialog.dart';
import '../home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      AuthDialog.show(
        context,
        type: AuthDialogType.error,
        title: 'Missing Fields!',
        message: 'Please enter your email\nand password to continue.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await AuthService.login(
        email: email,
        password: password,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result.success) {
        AuthDialog.show(
          context,
          type: AuthDialogType.success,
          title: 'Login Successful!',
          message: 'Please wait...\nYou will be directed to the homepage.',
          autoDismiss: const Duration(seconds: 3),
          onDone: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          },
        );
      } else {
        AuthDialog.show(
          context,
          type: AuthDialogType.error,
          title: 'Login Failed!',
          message: result.message ?? 'Invalid credentials.\nPlease try again.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AuthDialog.show(
          context,
          type: AuthDialogType.error,
          title: 'Connection Error!',
          message: 'Network error.\nPlease check your connection.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ✨ Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFFFFFF),
                  Color(0xFFF2F4F7),
                  Color(0xFFE8F0EC),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // ✨ Floating Blobs
          Positioned(
            top: -80,
            left: -60,
            child: _blurCircle(200, const Color(0xFF48B67C).withOpacity(0.08)),
          ),
          Positioned(
            bottom: -100,
            right: -50,
            child: _blurCircle(250, const Color(0xFF48B67C).withOpacity(0.06)),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Log in",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Enter your email and password to securely access\nyour account and manage your services.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.6),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 40),

                    _buildTextField(
                      controller: _emailController,
                      hint: "Email address",
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _passwordController,
                      hint: "Password",
                      icon: Icons.lock_outline,
                      isPassword: true,
                      obscure: _obscurePassword,
                      onToggleObscure: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              activeColor: const Color(0xFF48B67C),
                              checkColor: Colors.white,
                              onChanged: (value) =>
                                  setState(() => _rememberMe = value!),
                            ),
                            const Text(
                              "Remember me",
                              style: TextStyle(
                                  color: Colors.black87, fontSize: 13),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen()),
                          ),
                          child: const Text(
                            "Forgot Password",
                            style: TextStyle(
                              color: Color(0xFF48B67C),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF48B67C),
                          disabledBackgroundColor:
                              const Color(0xFF48B67C).withOpacity(0.6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 4,
                          shadowColor:
                              const Color(0xFF48B67C).withOpacity(0.4),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                "Login",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RegisterScreen()),
                      ),
                      child: const Text.rich(
                        TextSpan(
                          text: "Don't have an account? ",
                          style:
                              TextStyle(color: Colors.black54, fontSize: 13),
                          children: [
                            TextSpan(
                              text: "Sign Up here",
                              style: TextStyle(
                                color: Color(0xFF48B67C),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 50),

                    Text(
                      "Or Continue With Account",
                      style: TextStyle(
                          color: Colors.black.withOpacity(0.5), fontSize: 12),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _socialButton('images/assets/facebook.png'),
                        const SizedBox(width: 20),
                        _socialButton('images/assets/google.png'),
                        const SizedBox(width: 20),
                        _socialButton('images/assets/tik-tok.png'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggleObscure,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? obscure : false,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.black87, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFF48B67C), size: 22),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.grey,
                    size: 20,
                  ),
                  onPressed: onToggleObscure,
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        ),
      ),
    );
  }

  Widget _socialButton(String assetPath) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 50,
          width: 50,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.5),
              width: 1.5,
            ),
          ),
          child: Center(child: Image.asset(assetPath, height: 22)),
        ),
      ),
    );
  }

  Widget _blurCircle(double size, Color color) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
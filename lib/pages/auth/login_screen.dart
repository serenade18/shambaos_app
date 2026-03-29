import 'dart:ui';
import 'package:flutter/material.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'auth_service.dart';
import '../../widgets/auth_dialog.dart';
import '../home_screen.dart';
import '../../services/biometric_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with WidgetsBindingObserver {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();

  bool _rememberMe      = false;
  bool _obscurePassword = true;
  bool _isLoading       = false;

  // Biometric button visibility — refreshed on resume too
  bool _biometricReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshBiometricState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check when user comes back from Settings after enrolling biometrics
    if (state == AppLifecycleState.resumed) {
      _refreshBiometricState();
    }
  }

  Future<void> _refreshBiometricState() async {
    final ready = await BiometricService.isReadyToUse();
    if (mounted) setState(() => _biometricReady = ready);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // STANDARD LOGIN
  // ─────────────────────────────────────────────
  Future<void> _handleLogin() async {
    final email    = _emailController.text.trim();
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
      final result = await AuthService.login(email: email, password: password);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result.success && result.data != null) {
        final accessToken  = result.data['access']?.toString();
        final refreshToken = result.data['refresh']?.toString();

        if (accessToken == null || refreshToken == null) {
          throw Exception("Invalid token response");
        }

        // ── Ask user if they want biometric login ──────────────────────────
        final biometricAvailable = await BiometricService.isAvailable();
        final alreadyEnabled     = await BiometricService.isEnabled();

        if (biometricAvailable && !alreadyEnabled && mounted) {
          _showEnableBiometricDialog(
            accessToken:  accessToken,
            refreshToken: refreshToken,
            onComplete:   () => _navigateHome(),
          );
        } else {
          // Refresh tokens in secure storage if already enabled
          if (alreadyEnabled) {
            await BiometricService.enableAndSaveTokens(
              access:  accessToken,
              refresh: refreshToken,
            );
          }
          _showSuccessAndNavigate();
        }
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

  // ─────────────────────────────────────────────
  // BIOMETRIC OPT-IN DIALOG
  // ─────────────────────────────────────────────
  void _showEnableBiometricDialog({
    required String accessToken,
    required String refreshToken,
    required VoidCallback onComplete,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.fingerprint, color: Color(0xFF48B67C), size: 28),
            SizedBox(width: 10),
            Text(
              'Enable Biometric Login?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Skip the password next time.\nUse your fingerprint or face ID to log in instantly.',
          style: TextStyle(color: Colors.black54, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onComplete();
            },
            child: const Text(
              'Not now',
              style: TextStyle(color: Colors.black45),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await BiometricService.enableAndSaveTokens(
                access:  accessToken,
                refresh: refreshToken,
              );
              onComplete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF48B67C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'Enable',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessAndNavigate() {
    AuthDialog.show(
      context,
      type: AuthDialogType.success,
      title: 'Login Successful!',
      message: 'Redirecting...',
      autoDismiss: const Duration(seconds: 2),
      onDone: _navigateHome,
    );
  }

  void _navigateHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  // ─────────────────────────────────────────────
  // BIOMETRIC LOGIN
  // ─────────────────────────────────────────────
  Future<void> _handleBiometricLogin() async {
    if (_isLoading) return;

    final success = await BiometricService.authenticate();

    if (!success) {
      if (!mounted) return;
      AuthDialog.show(
        context,
        type: AuthDialogType.error,
        title: 'Authentication Failed',
        message: 'Biometric check failed.\nPlease try again.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final accessToken  = await BiometricService.getAccessToken();
      final refreshToken = await BiometricService.getRefreshToken();

      if (accessToken == null || refreshToken == null) {
        throw Exception("Missing tokens — please login with password first.");
      }

      // Validate / silently refresh the session server-side
      final isValid = await AuthService.validateToken(
        accessToken:  accessToken,
        refreshToken: refreshToken,
      );

      if (!isValid) throw Exception("Session expired");

      if (!mounted) return;
      _navigateHome();
    } catch (e) {
      await BiometricService.clear();
      await _refreshBiometricState(); // hide the button

      if (!mounted) return;
      AuthDialog.show(
        context,
        type: AuthDialogType.error,
        title: 'Session Expired',
        message: 'Please login with your\npassword again.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
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

          // Floating blobs
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
                      onToggleObscure: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
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
                              onChanged: (v) =>
                                  setState(() => _rememberMe = v!),
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

                    // ── Login button ──────────────────────────────────────
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

                    const SizedBox(height: 20),

                    // ── Biometric button — only shown when ready ──────────
                    if (_biometricReady) ...[
                      const Text(
                        "Or login with biometrics",
                        style:
                            TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: _handleBiometricLogin,
                        child: Container(
                          height: 60,
                          width: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFF48B67C).withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF48B67C).withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.fingerprint,
                            color: Color(0xFF48B67C),
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── Sign up link ──────────────────────────────────────
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

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // HELPER WIDGETS
  // ─────────────────────────────────────────────
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
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.black87, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          prefixIcon:
              Icon(icon, color: const Color(0xFF48B67C), size: 22),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscure ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
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
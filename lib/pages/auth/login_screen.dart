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

class _LoginScreenState extends State<LoginScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();

  bool    _rememberMe      = false;
  bool    _obscurePassword = true;
  bool    _isLoading       = false;

  // The user who has biometric login set up on this device (may be null)
  String? _biometricUserId;

  late AnimationController _animController;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));

    _animController.forward();
    _loadBiometricUser();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check when user returns from Settings after enrolling biometrics
    if (state == AppLifecycleState.resumed) _loadBiometricUser();
  }

  /// Checks if any user has biometric login enabled on this device.
  Future<void> _loadBiometricUser() async {
    final available = await BiometricService.isAvailable();
    if (!available) {
      if (mounted) setState(() => _biometricUserId = null);
      return;
    }
    final userId = await BiometricService.getCurrentBiometricUser();
    if (userId != null) {
      final enabled = await BiometricService.isEnabledForUser(userId);
      if (mounted) setState(() => _biometricUserId = enabled ? userId : null);
    } else {
      if (mounted) setState(() => _biometricUserId = null);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animController.dispose();
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

        // Use email as the userId — stable and unique per user
        final userId = email.toLowerCase();

        // Always refresh stored tokens if this user already has biometrics on
        await BiometricService.refreshTokensForUser(
          userId:  userId,
          access:  accessToken,
          refresh: refreshToken,
        );

        final alreadyEnabled     = await BiometricService.isEnabledForUser(userId);
        final biometricAvailable = await BiometricService.isAvailable();

        if (biometricAvailable && !alreadyEnabled && mounted) {
          // First time — prompt opt-in
          _showEnableBiometricDialog(
            userId:       userId,
            accessToken:  accessToken,
            refreshToken: refreshToken,
            onComplete:   _navigateHome,
          );
        } else {
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
    required String userId,
    required String accessToken,
    required String refreshToken,
    required VoidCallback onComplete,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: AlertDialog(
          backgroundColor: Colors.white.withOpacity(0.92),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.fingerprint, color: Color(0xFF3DBE6E), size: 28),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Enable Biometric Login?',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A2E1A)),
                ),
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
              child: const Text('Not now',
                  style: TextStyle(color: Colors.black38)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await BiometricService.enableForUser(
                  userId:  userId,
                  access:  accessToken,
                  refresh: refreshToken,
                );
                if (mounted) setState(() => _biometricUserId = userId);
                onComplete();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3DBE6E),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              child:
                  const Text('Enable', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
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
    if (_isLoading || _biometricUserId == null) return;
    final userId = _biometricUserId!;

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
      final accessToken  = await BiometricService.getAccessToken(userId);
      final refreshToken = await BiometricService.getRefreshToken(userId);

      if (accessToken == null || refreshToken == null) {
        throw Exception("Missing tokens");
      }

      final isValid = await AuthService.validateToken(
        accessToken:  accessToken,
        refreshToken: refreshToken,
      );

      if (!isValid) throw Exception("Session expired");

      if (!mounted) return;
      _navigateHome();
    } catch (e) {
      await BiometricService.disableForUser(userId);
      await _loadBiometricUser(); // hides the button

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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ── Full-screen nature background ──────────────────────────────
          SizedBox.expand(
            child: Image.asset(
              'images/auth/mountains.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // ── Gradient overlay for contrast ──────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.10),
                  Colors.black.withOpacity(0.40),
                ],
              ),
            ),
          ),

          // ── Main scrollable content ────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.06,
                  vertical: 24,
                ),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.17),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.35),
                              width: 1.5,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 36),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [

                              // ── Header ─────────────────────────────────
                              const Text(
                                "Login",
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black26,
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Welcome back, please login to your account",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.80),
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 32),

                              // ── Email ───────────────────────────────────
                              _buildGlassField(
                                controller: _emailController,
                                hint: "Email address",
                                icon: Icons.person_outline_rounded,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 14),

                              // ── Password ────────────────────────────────
                              _buildGlassField(
                                controller: _passwordController,
                                hint: "Password",
                                icon: Icons.lock_outline_rounded,
                                isPassword: true,
                                obscure: _obscurePassword,
                                onToggleObscure: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                              const SizedBox(height: 14),

                              // ── Remember me + Forgot password ───────────
                              Row(
                                children: [
                                  SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      activeColor: const Color(0xFF3DBE6E),
                                      checkColor: Colors.white,
                                      side: BorderSide(
                                        color: Colors.white.withOpacity(0.7),
                                        width: 1.5,
                                      ),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(4)),
                                      onChanged: (v) =>
                                          setState(() => _rememberMe = v!),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    "Remember me",
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.85),
                                      fontSize: 13,
                                    ),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const ForgotPasswordScreen()),
                                    ),
                                    child: Text(
                                      "Forgot Password?",
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.75),
                                        fontSize: 12,
                                        decoration: TextDecoration.underline,
                                        decorationColor:
                                            Colors.white.withOpacity(0.4),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 28),

                              // ── Login button ────────────────────────────
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3DBE6E),
                                    disabledBackgroundColor: const Color(0xFF3DBE6E).withOpacity(0.5),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    elevation: 0,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                        )
                                      : const Text(
                                          "Login",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                ),
                              ),

                              // ── NEW BIOMETRIC SECTION ─────────────────────
                              if (_biometricUserId != null) ...[
                                const SizedBox(height: 20),
                                Center(
                                  child: Column(
                                    children: [
                                      Text(
                                        "or continue with",
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.6),
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      GestureDetector(
                                        onTap: _handleBiometricLogin,
                                        child: Column(
                                          children: [
                                            Container(
                                              height: 60,
                                              width: 60,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF3DBE6E).withOpacity(0.2),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: const Color(0xFF3DBE6E).withOpacity(0.6),
                                                  width: 2,
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.fingerprint,
                                                color: Colors.white,
                                                size: 32,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              "Login as $_biometricUserId",
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.8),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 24),

                              // ── Sign up link ────────────────────────────
                              Center(
                                child: GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                                  ),
                                  child: Text.rich(
                                    TextSpan(
                                      text: "Don't have an account? ",
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.75),
                                        fontSize: 13,
                                      ),
                                      children: const [
                                        TextSpan(
                                          text: "Sign Up here",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 28),

                              // ── Social Divider ──────────────────────────
                              Row(
                                children: [
                                  Expanded(child: Divider(color: Colors.white.withOpacity(0.2), thickness: 1)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text(
                                      "Social Login",
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                        fontSize: 10,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                  Expanded(child: Divider(color: Colors.white.withOpacity(0.2), thickness: 1)),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // ── Social buttons (Cleaned) ────────────────
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
                                                            
                              // Biometric account hint
                              // if (_biometricUserId != null) ...[
                              //   const SizedBox(height: 10),
                              //   Center(
                              //     child: Text(
                              //       "Tap fingerprint to login as $_biometricUserId",
                              //       style: TextStyle(
                              //         color: Colors.white.withOpacity(0.55),
                              //         fontSize: 10.5,
                              //       ),
                              //     ),
                              //   ),
                              // ],

                              // const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // GLASS TEXT FIELD
  // ─────────────────────────────────────────────
  Widget _buildGlassField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggleObscure,
    TextInputType? keyboardType,
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
            obscureText: obscure,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.55), fontSize: 14),
              // Icon on the right to match the reference design
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.white.withOpacity(0.6),
                        size: 20,
                      ),
                      onPressed: onToggleObscure,
                    )
                  : Icon(icon,
                      color: Colors.white.withOpacity(0.55), size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  vertical: 16, horizontal: 18),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SOCIAL BUTTON
  // ─────────────────────────────────────────────
  Widget _socialButton(String assetPath) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 50,
          width: 50,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.20),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.40),
              width: 1.5,
            ),
          ),
          child: Center(child: Image.asset(assetPath, height: 22)),
        ),
      ),
    );
  }
}
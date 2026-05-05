import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Brand tokens — sourced from HomeScreen / AppColors
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Country model
// ─────────────────────────────────────────────────────────────────────────────
class _Country {
  final String flag;
  final String name;
  final String dialCode;
  const _Country({required this.flag, required this.name, required this.dialCode});
}

const List<_Country> _countries = [
  _Country(flag: '🇰🇪', name: 'Kenya',        dialCode: '+254'),
  _Country(flag: '🇺🇬', name: 'Uganda',       dialCode: '+256'),
  _Country(flag: '🇹🇿', name: 'Tanzania',     dialCode: '+255'),
  _Country(flag: '🇷🇼', name: 'Rwanda',       dialCode: '+250'),
  _Country(flag: '🇪🇹', name: 'Ethiopia',     dialCode: '+251'),
  _Country(flag: '🇳🇬', name: 'Nigeria',      dialCode: '+234'),
  _Country(flag: '🇬🇭', name: 'Ghana',        dialCode: '+233'),
  _Country(flag: '🇿🇦', name: 'South Africa', dialCode: '+27'),
];

// ─────────────────────────────────────────────────────────────────────────────
// Login Screen
// ─────────────────────────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  _Country _selectedCountry = _countries.first;
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocus = FocusNode();

  late AnimationController _animCtrl;
  late List<Animation<double>> _fadeAnims;
  late List<Animation<Offset>> _slideAnims;

  bool _isLoading = false;

  static const int _staggerCount = 5;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnims = List.generate(_staggerCount, (i) {
      final start = i * 0.12;
      final end = (start + 0.5).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _animCtrl,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    _slideAnims = List.generate(_staggerCount, (i) {
      final start = i * 0.12;
      final end = (start + 0.5).clamp(0.0, 1.0);
      return Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
          .animate(CurvedAnimation(
        parent: _animCtrl,
        curve: Interval(start, end, curve: Curves.easeOut),
      ));
    });

    Future.delayed(const Duration(milliseconds: 60), () {
      if (mounted) _animCtrl.forward();
    });

    _phoneFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _phoneController.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  Widget _stagger(int index, Widget child) => SlideTransition(
        position: _slideAnims[index],
        child: FadeTransition(opacity: _fadeAnims[index], child: child),
      );

  // ── Country Picker ─────────────────────────────────────────────────────────
  void _showCountryPicker() {
    _phoneFocus.unfocus();
    showModalBottomSheet(
      context: context,
      backgroundColor: _Brand.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: _Brand.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Select Country',
            style: TextStyle(
              color: _Brand.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: _Brand.divider),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _countries.length,
            itemBuilder: (_, i) {
              final c = _countries[i];
              final selected = c.dialCode == _selectedCountry.dialCode;
              return ListTile(
                onTap: () {
                  setState(() => _selectedCountry = c);
                  Navigator.pop(context);
                },
                tileColor: selected ? _Brand.brandLight : null,
                leading: Text(c.flag, style: const TextStyle(fontSize: 22)),
                title: Text(
                  c.name,
                  style: TextStyle(
                    color: selected ? _Brand.brand : _Brand.textPrimary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
                trailing: Text(
                  c.dialCode,
                  style: TextStyle(
                    color: selected ? _Brand.brand : _Brand.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Continue ───────────────────────────────────────────────────────────────
  Future<void> _handleContinue() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _phoneFocus.requestFocus();
      return;
    }
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _isLoading = false);
    // TODO: Navigator.of(context).push(...) → OTP screen
  }

  // ── Help dialog ────────────────────────────────────────────────────────────
  void _showHelp() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _Brand.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Need Help?',
          style: TextStyle(color: _Brand.textPrimary, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Enter your phone number (e.g. 0712 123456). We\'ll send a verification code via SMS to log in or create your account.',
          style: TextStyle(color: _Brand.textSecondary, height: 1.5, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Got it',
              style: TextStyle(color: _Brand.brand, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final focused = _phoneFocus.hasFocus;

    return Scaffold(
      backgroundColor: _Brand.scaffold,
      body: SafeArea(
        child: Column(
          children: [

            // ── Header card — mirrors HomeScreen header style ──────────────
            _stagger(
              0,
              Container(
                color: _Brand.card,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Brand pill — same pattern as HomeScreen update chips
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _Brand.brandLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _Brand.brandBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.agriculture_rounded,
                              color: _Brand.brand, size: 13),
                          SizedBox(width: 5),
                          Text(
                            'FARM INTELLIGENCE',
                            style: TextStyle(
                              color: _Brand.brand,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    const Text(
                      "What's your phone number?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: _Brand.textPrimary,
                        height: 1.15,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'We use it to create your account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: _Brand.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 1, thickness: 1, color: _Brand.divider),

            // ── Scrollable body ────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Phone input card ───────────────────────────────────
                    _stagger(
                      1,
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: _Brand.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: focused ? _Brand.brand : _Brand.divider,
                            width: focused ? 1.5 : 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: focused
                                  ? _Brand.brand.withOpacity(0.10)
                                  : Colors.black.withOpacity(0.04),
                              blurRadius: focused ? 14 : 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Country dial selector
                            GestureDetector(
                              onTap: _showCountryPicker,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 16),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    right: BorderSide(color: _Brand.divider),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(_selectedCountry.flag,
                                        style: const TextStyle(fontSize: 20)),
                                    const SizedBox(width: 6),
                                    Text(
                                      _selectedCountry.dialCode,
                                      style: const TextStyle(
                                        color: _Brand.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: _Brand.textSecondary,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Number field
                            Expanded(
                              child: TextField(
                                controller: _phoneController,
                                focusNode: _phoneFocus,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(10),
                                ],
                                style: const TextStyle(
                                  color: _Brand.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: const InputDecoration(
                                  hintText: '712 123456',
                                  hintStyle: TextStyle(
                                    color: _Brand.textHint,
                                    fontSize: 14,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 16),
                                ),
                                cursorColor: _Brand.brand,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Help row card — mirrors HomeScreen ListTile style ──
                    _stagger(
                      2,
                      GestureDetector(
                        onTap: _showHelp,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: _Brand.card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _Brand.divider),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Icon box — same as HomeScreen update card icon
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: _Brand.brandLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.help_outline_rounded,
                                  color: _Brand.brand,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Need help to connect?',
                                      style: TextStyle(
                                        color: _Brand.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Learn how SMS login works',
                                      style: TextStyle(
                                        color: _Brand.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Arrow circle — same as HomeScreen update card
                              Container(
                                width: 34,
                                height: 34,
                                decoration: const BoxDecoration(
                                  color: _Brand.brand,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  ],
                ),
              ),
            ),

            // ── Bottom bar — sticky, white, same pattern as HomeScreen bottom ─
            Container(
              color: _Brand.card,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Divider(height: 1, thickness: 1, color: _Brand.divider),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    child: Column(
                      children: [
                        // Terms
                        RichText(
                          textAlign: TextAlign.center,
                          text: const TextSpan(
                            style: TextStyle(
                              color: _Brand.textHint,
                              fontSize: 11,
                              height: 1.5,
                            ),
                            children: [
                              TextSpan(text: 'By continuing you agree to our '),
                              TextSpan(
                                text: 'Terms of Service',
                                style: TextStyle(
                                  color: _Brand.brand,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(
                                  color: _Brand.brand,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Continue — ElevatedButton matching HomeScreen poster CTAs
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleContinue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _Brand.brand,
                              disabledBackgroundColor:
                                  _Brand.brand.withOpacity(0.45),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text('Continue'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Trust chip widget — mirrors quick-menu card box ──────────────────────
  Widget _trustChip(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _Brand.brandLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _Brand.brandBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: _Brand.brand, size: 20),
            const SizedBox(height: 5),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _Brand.brand,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}




// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'register_screen.dart';
// import 'forgot_password_screen.dart';
// import 'auth_service.dart';
// import '../../widgets/auth_dialog.dart';
// import '../home_screen.dart';
// import '../../services/biometric_service.dart';

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen>
//     with WidgetsBindingObserver, SingleTickerProviderStateMixin {
//   final _emailController    = TextEditingController();
//   final _passwordController = TextEditingController();

//   bool    _rememberMe      = false;
//   bool    _obscurePassword = true;
//   bool    _isLoading       = false;

//   // The user who has biometric login set up on this device (may be null)
//   String? _biometricUserId;

//   late AnimationController _animController;
//   late Animation<double>   _fadeAnim;
//   late Animation<Offset>   _slideAnim;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);

//     _animController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 900),
//     );
//     _fadeAnim = CurvedAnimation(
//       parent: _animController,
//       curve: Curves.easeOut,
//     );
//     _slideAnim = Tween<Offset>(
//       begin: const Offset(0, 0.08),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(
//       parent: _animController,
//       curve: Curves.easeOut,
//     ));

//     _animController.forward();
//     _loadBiometricUser();
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     // Re-check when user returns from Settings after enrolling biometrics
//     if (state == AppLifecycleState.resumed) _loadBiometricUser();
//   }

//   /// Checks if any user has biometric login enabled on this device.
//   Future<void> _loadBiometricUser() async {
//     final available = await BiometricService.isAvailable();
//     if (!available) {
//       if (mounted) setState(() => _biometricUserId = null);
//       return;
//     }
//     final userId = await BiometricService.getCurrentBiometricUser();
//     if (userId != null) {
//       final enabled = await BiometricService.isEnabledForUser(userId);
//       if (mounted) setState(() => _biometricUserId = enabled ? userId : null);
//     } else {
//       if (mounted) setState(() => _biometricUserId = null);
//     }
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     _animController.dispose();
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }

//   // ─────────────────────────────────────────────
//   // STANDARD LOGIN
//   // ─────────────────────────────────────────────
//   Future<void> _handleLogin() async {
//     final email    = _emailController.text.trim();
//     final password = _passwordController.text;

//     if (email.isEmpty || password.isEmpty) {
//       AuthDialog.show(
//         context,
//         type: AuthDialogType.error,
//         title: 'Missing Fields!',
//         message: 'Please enter your email\nand password to continue.',
//       );
//       return;
//     }

//     setState(() => _isLoading = true);

//     try {
//       final result = await AuthService.login(email: email, password: password);
//       if (!mounted) return;
//       setState(() => _isLoading = false);

//       if (result.success && result.data != null) {
//         final accessToken  = result.data['access']?.toString();
//         final refreshToken = result.data['refresh']?.toString();

//         if (accessToken == null || refreshToken == null) {
//           throw Exception("Invalid token response");
//         }

//         // Use email as the userId — stable and unique per user
//         final userId = email.toLowerCase();

//         // Always refresh stored tokens if this user already has biometrics on
//         await BiometricService.refreshTokensForUser(
//           userId:  userId,
//           access:  accessToken,
//           refresh: refreshToken,
//         );

//         final alreadyEnabled     = await BiometricService.isEnabledForUser(userId);
//         final biometricAvailable = await BiometricService.isAvailable();

//         if (biometricAvailable && !alreadyEnabled && mounted) {
//           // First time — prompt opt-in
//           _showEnableBiometricDialog(
//             userId:       userId,
//             accessToken:  accessToken,
//             refreshToken: refreshToken,
//             onComplete:   _navigateHome,
//           );
//         } else {
//           _showSuccessAndNavigate();
//         }
//       } else {
//         AuthDialog.show(
//           context,
//           type: AuthDialogType.error,
//           title: 'Login Failed!',
//           message: result.message ?? 'Invalid credentials.\nPlease try again.',
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() => _isLoading = false);
//         AuthDialog.show(
//           context,
//           type: AuthDialogType.error,
//           title: 'Connection Error!',
//           message: 'Network error.\nPlease check your connection.',
//         );
//       }
//     }
//   }

//   // ─────────────────────────────────────────────
//   // BIOMETRIC OPT-IN DIALOG
//   // ─────────────────────────────────────────────
//   void _showEnableBiometricDialog({
//     required String userId,
//     required String accessToken,
//     required String refreshToken,
//     required VoidCallback onComplete,
//   }) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (ctx) => BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
//         child: AlertDialog(
//           backgroundColor: Colors.white.withOpacity(0.92),
//           shape:
//               RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
//           title: const Row(
//             children: [
//               Icon(Icons.fingerprint, color: Color(0xFF3DBE6E), size: 28),
//               SizedBox(width: 10),
//               Expanded(
//                 child: Text(
//                   'Enable Biometric Login?',
//                   style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                       color: Color(0xFF1A2E1A)),
//                 ),
//               ),
//             ],
//           ),
//           content: const Text(
//             'Skip the password next time.\nUse your fingerprint or face ID to log in instantly.',
//             style: TextStyle(color: Colors.black54, height: 1.5),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(ctx).pop();
//                 onComplete();
//               },
//               child: const Text('Not now',
//                   style: TextStyle(color: Colors.black38)),
//             ),
//             ElevatedButton(
//               onPressed: () async {
//                 Navigator.of(ctx).pop();
//                 await BiometricService.enableForUser(
//                   userId:  userId,
//                   access:  accessToken,
//                   refresh: refreshToken,
//                 );
//                 if (mounted) setState(() => _biometricUserId = userId);
//                 onComplete();
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF3DBE6E),
//                 shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(30)),
//               ),
//               child:
//                   const Text('Enable', style: TextStyle(color: Colors.white)),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showSuccessAndNavigate() {
//     AuthDialog.show(
//       context,
//       type: AuthDialogType.success,
//       title: 'Login Successful!',
//       message: 'Redirecting...',
//       autoDismiss: const Duration(seconds: 2),
//       onDone: _navigateHome,
//     );
//   }

//   void _navigateHome() {
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (_) => const HomeScreen()),
//     );
//   }

//   // ─────────────────────────────────────────────
//   // BIOMETRIC LOGIN
//   // ─────────────────────────────────────────────
//   Future<void> _handleBiometricLogin() async {
//     if (_isLoading || _biometricUserId == null) return;
//     final userId = _biometricUserId!;

//     final success = await BiometricService.authenticate();
//     if (!success) {
//       if (!mounted) return;
//       AuthDialog.show(
//         context,
//         type: AuthDialogType.error,
//         title: 'Authentication Failed',
//         message: 'Biometric check failed.\nPlease try again.',
//       );
//       return;
//     }

//     setState(() => _isLoading = true);

//     try {
//       final accessToken  = await BiometricService.getAccessToken(userId);
//       final refreshToken = await BiometricService.getRefreshToken(userId);

//       if (accessToken == null || refreshToken == null) {
//         throw Exception("Missing tokens");
//       }

//       final isValid = await AuthService.validateToken(
//         accessToken:  accessToken,
//         refreshToken: refreshToken,
//       );

//       if (!isValid) throw Exception("Session expired");

//       if (!mounted) return;
//       _navigateHome();
//     } catch (e) {
//       await BiometricService.disableForUser(userId);
//       await _loadBiometricUser(); // hides the button

//       if (!mounted) return;
//       AuthDialog.show(
//         context,
//         type: AuthDialogType.error,
//         title: 'Session Expired',
//         message: 'Please login with your\npassword again.',
//       );
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   // ─────────────────────────────────────────────
//   // BUILD
//   // ─────────────────────────────────────────────
//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;

//     return Scaffold(
//       body: Stack(
//         children: [
//           // ── Full-screen nature background ──────────────────────────────
//           SizedBox.expand(
//             child: Image.asset(
//               'images/auth/plain.jpg',
//               fit: BoxFit.cover,
//             ),
//           ),

//           // ── Gradient overlay for contrast ──────────────────────────────
//           Container(
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//                 colors: [
//                   Colors.black.withOpacity(0.10),
//                   Colors.black.withOpacity(0.40),
//                 ],
//               ),
//             ),
//           ),

//           // ── Main scrollable content ────────────────────────────────────
//           SafeArea(
//             child: Center(
//               child: SingleChildScrollView(
//                 padding: EdgeInsets.symmetric(
//                   horizontal: size.width * 0.06,
//                   vertical: 24,
//                 ),
//                 child: FadeTransition(
//                   opacity: _fadeAnim,
//                   child: SlideTransition(
//                     position: _slideAnim,
//                     child: ClipRRect(
//                       borderRadius: BorderRadius.circular(28),
//                       child: BackdropFilter(
//                         filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
//                         child: Container(
//                           decoration: BoxDecoration(
//                             color: Colors.white.withOpacity(0.17),
//                             borderRadius: BorderRadius.circular(28),
//                             border: Border.all(
//                               color: Colors.white.withOpacity(0.35),
//                               width: 1.5,
//                             ),
//                           ),
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 28, vertical: 36),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             mainAxisSize: MainAxisSize.min,
//                             children: [

//                               // ── Header ─────────────────────────────────
//                               const Text(
//                                 "Login",
//                                 style: TextStyle(
//                                   fontSize: 36,
//                                   fontWeight: FontWeight.w800,
//                                   color: Colors.white,
//                                   letterSpacing: -0.5,
//                                   shadows: [
//                                     Shadow(
//                                       color: Colors.black26,
//                                       blurRadius: 8,
//                                       offset: Offset(0, 2),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                               const SizedBox(height: 6),
//                               Text(
//                                 "Welcome back, please login to your account",
//                                 style: TextStyle(
//                                   fontSize: 13,
//                                   color: Colors.white.withOpacity(0.80),
//                                   height: 1.4,
//                                 ),
//                               ),
//                               const SizedBox(height: 32),

//                               // ── Email ───────────────────────────────────
//                               _buildGlassField(
//                                 controller: _emailController,
//                                 hint: "Email address",
//                                 icon: Icons.person_outline_rounded,
//                                 keyboardType: TextInputType.emailAddress,
//                               ),
//                               const SizedBox(height: 14),

//                               // ── Password ────────────────────────────────
//                               _buildGlassField(
//                                 controller: _passwordController,
//                                 hint: "Password",
//                                 icon: Icons.lock_outline_rounded,
//                                 isPassword: true,
//                                 obscure: _obscurePassword,
//                                 onToggleObscure: () => setState(
//                                     () => _obscurePassword = !_obscurePassword),
//                               ),
//                               const SizedBox(height: 14),

//                               // ── Remember me + Forgot password ───────────
//                               Row(
//                                 children: [
//                                   SizedBox(
//                                     height: 22,
//                                     width: 22,
//                                     child: Checkbox(
//                                       value: _rememberMe,
//                                       activeColor: const Color(0xFF3DBE6E),
//                                       checkColor: Colors.white,
//                                       side: BorderSide(
//                                         color: Colors.white.withOpacity(0.7),
//                                         width: 1.5,
//                                       ),
//                                       shape: RoundedRectangleBorder(
//                                           borderRadius:
//                                               BorderRadius.circular(4)),
//                                       onChanged: (v) =>
//                                           setState(() => _rememberMe = v!),
//                                     ),
//                                   ),
//                                   const SizedBox(width: 10),
//                                   Text(
//                                     "Remember me",
//                                     style: TextStyle(
//                                       color: Colors.white.withOpacity(0.85),
//                                       fontSize: 13,
//                                     ),
//                                   ),
//                                   const Spacer(),
//                                   GestureDetector(
//                                     onTap: () => Navigator.push(
//                                       context,
//                                       MaterialPageRoute(
//                                           builder: (_) =>
//                                               const ForgotPasswordScreen()),
//                                     ),
//                                     child: Text(
//                                       "Forgot Password?",
//                                       style: TextStyle(
//                                         color: Colors.white.withOpacity(0.75),
//                                         fontSize: 12,
//                                         decoration: TextDecoration.underline,
//                                         decorationColor:
//                                             Colors.white.withOpacity(0.4),
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),

//                               const SizedBox(height: 28),

//                               // ── Login button ────────────────────────────
//                               SizedBox(
//                                 width: double.infinity,
//                                 height: 52,
//                                 child: ElevatedButton(
//                                   onPressed: _isLoading ? null : _handleLogin,
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor: const Color(0xFF3DBE6E),
//                                     disabledBackgroundColor: const Color(0xFF3DBE6E).withOpacity(0.5),
//                                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//                                     elevation: 0,
//                                   ),
//                                   child: _isLoading
//                                       ? const SizedBox(
//                                           height: 20,
//                                           width: 20,
//                                           child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
//                                         )
//                                       : const Text(
//                                           "Login",
//                                           style: TextStyle(
//                                             color: Colors.white,
//                                             fontSize: 16,
//                                             fontWeight: FontWeight.w700,
//                                             letterSpacing: 0.3,
//                                           ),
//                                         ),
//                                 ),
//                               ),

//                               // ── NEW BIOMETRIC SECTION ─────────────────────
//                               if (_biometricUserId != null) ...[
//                                 const SizedBox(height: 20),
//                                 Center(
//                                   child: Column(
//                                     children: [
//                                       Text(
//                                         "or continue with",
//                                         style: TextStyle(
//                                           color: Colors.white.withOpacity(0.6),
//                                           fontSize: 12,
//                                         ),
//                                       ),
//                                       const SizedBox(height: 12),
//                                       GestureDetector(
//                                         onTap: _handleBiometricLogin,
//                                         child: Column(
//                                           children: [
//                                             Container(
//                                               height: 60,
//                                               width: 60,
//                                               decoration: BoxDecoration(
//                                                 color: const Color(0xFF3DBE6E).withOpacity(0.2),
//                                                 shape: BoxShape.circle,
//                                                 border: Border.all(
//                                                   color: const Color(0xFF3DBE6E).withOpacity(0.6),
//                                                   width: 2,
//                                                 ),
//                                               ),
//                                               child: const Icon(
//                                                 Icons.fingerprint,
//                                                 color: Colors.white,
//                                                 size: 32,
//                                               ),
//                                             ),
//                                             const SizedBox(height: 8),
//                                             Text(
//                                               "Login as $_biometricUserId",
//                                               style: TextStyle(
//                                                 color: Colors.white.withOpacity(0.8),
//                                                 fontSize: 11,
//                                                 fontWeight: FontWeight.w500,
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ],

//                               const SizedBox(height: 24),

//                               // ── Sign up link ────────────────────────────
//                               Center(
//                                 child: GestureDetector(
//                                   onTap: () => Navigator.push(
//                                     context,
//                                     MaterialPageRoute(builder: (_) => const RegisterScreen()),
//                                   ),
//                                   child: Text.rich(
//                                     TextSpan(
//                                       text: "Don't have an account? ",
//                                       style: TextStyle(
//                                         color: Colors.white.withOpacity(0.75),
//                                         fontSize: 13,
//                                       ),
//                                       children: const [
//                                         TextSpan(
//                                           text: "Sign Up here",
//                                           style: TextStyle(
//                                             color: Colors.white,
//                                             fontWeight: FontWeight.w800,
//                                             fontSize: 13,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//                               ),

//                               const SizedBox(height: 28),

//                               // ── Social Divider ──────────────────────────
//                               Row(
//                                 children: [
//                                   Expanded(child: Divider(color: Colors.white.withOpacity(0.2), thickness: 1)),
//                                   Padding(
//                                     padding: const EdgeInsets.symmetric(horizontal: 12),
//                                     child: Text(
//                                       "Social Login",
//                                       style: TextStyle(
//                                         color: Colors.white.withOpacity(0.5),
//                                         fontSize: 10,
//                                         letterSpacing: 1,
//                                       ),
//                                     ),
//                                   ),
//                                   Expanded(child: Divider(color: Colors.white.withOpacity(0.2), thickness: 1)),
//                                 ],
//                               ),

//                               const SizedBox(height: 20),

//                               // ── Social buttons (Cleaned) ────────────────
//                               Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   _socialButton('images/assets/facebook.png'),
//                                   const SizedBox(width: 20),
//                                   _socialButton('images/assets/google.png'),
//                                   const SizedBox(width: 20),
//                                   _socialButton('images/assets/tik-tok.png'),
//                                 ],
//                               ),
                                                            
//                               // Biometric account hint
//                               // if (_biometricUserId != null) ...[
//                               //   const SizedBox(height: 10),
//                               //   Center(
//                               //     child: Text(
//                               //       "Tap fingerprint to login as $_biometricUserId",
//                               //       style: TextStyle(
//                               //         color: Colors.white.withOpacity(0.55),
//                               //         fontSize: 10.5,
//                               //       ),
//                               //     ),
//                               //   ),
//                               // ],

//                               // const SizedBox(height: 8),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ─────────────────────────────────────────────
//   // GLASS TEXT FIELD
//   // ─────────────────────────────────────────────
//   Widget _buildGlassField({
//     required TextEditingController controller,
//     required String hint,
//     required IconData icon,
//     bool isPassword = false,
//     bool obscure = false,
//     VoidCallback? onToggleObscure,
//     TextInputType? keyboardType,
//   }) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(14),
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
//         child: Container(
//           decoration: BoxDecoration(
//             color: Colors.white.withOpacity(0.15),
//             borderRadius: BorderRadius.circular(14),
//             border: Border.all(
//               color: Colors.white.withOpacity(0.30),
//               width: 1,
//             ),
//           ),
//           child: TextField(
//             controller: controller,
//             obscureText: obscure,
//             keyboardType: keyboardType,
//             style: const TextStyle(color: Colors.white, fontSize: 15),
//             decoration: InputDecoration(
//               hintText: hint,
//               hintStyle: TextStyle(
//                   color: Colors.white.withOpacity(0.55), fontSize: 14),
//               // Icon on the right to match the reference design
//               suffixIcon: isPassword
//                   ? IconButton(
//                       icon: Icon(
//                         obscure
//                             ? Icons.visibility_off_outlined
//                             : Icons.visibility_outlined,
//                         color: Colors.white.withOpacity(0.6),
//                         size: 20,
//                       ),
//                       onPressed: onToggleObscure,
//                     )
//                   : Icon(icon,
//                       color: Colors.white.withOpacity(0.55), size: 20),
//               border: InputBorder.none,
//               contentPadding: const EdgeInsets.symmetric(
//                   vertical: 16, horizontal: 18),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // ─────────────────────────────────────────────
//   // SOCIAL BUTTON
//   // ─────────────────────────────────────────────
//   Widget _socialButton(String assetPath) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(50),
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//         child: Container(
//           height: 50,
//           width: 50,
//           decoration: BoxDecoration(
//             color: Colors.white.withOpacity(0.20),
//             shape: BoxShape.circle,
//             border: Border.all(
//               color: Colors.white.withOpacity(0.40),
//               width: 1.5,
//             ),
//           ),
//           child: Center(child: Image.asset(assetPath, height: 22)),
//         ),
//       ),
//     );
//   }
// }
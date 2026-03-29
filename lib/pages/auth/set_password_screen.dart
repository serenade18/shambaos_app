import 'dart:ui';
import 'package:flutter/material.dart';
import 'auth_service.dart';
import '../../widgets/auth_dialog.dart';

class SetPasswordScreen extends StatefulWidget {
  final String email;
  final String code;

  const SetPasswordScreen({
    super.key,
    required this.email,
    required this.code,
  });

  @override
  State<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends State<SetPasswordScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  double _strength = 0;
  String _strengthLabel = '';
  Color _strengthColor = Colors.transparent;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_checkStrength);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  void _checkStrength() {
    final p = _passwordController.text;
    double strength = 0;
    if (p.length >= 8) strength += 0.25;
    if (p.contains(RegExp(r'[A-Z]'))) strength += 0.25;
    if (p.contains(RegExp(r'[0-9]'))) strength += 0.25;
    if (p.contains(RegExp(r'[!@#\$&*~%^()_\-+=]'))) strength += 0.25;

    setState(() {
      _strength = strength;
      if (strength <= 0.25) { _strengthLabel = 'Weak'; _strengthColor = Colors.redAccent; }
      else if (strength <= 0.5) { _strengthLabel = 'Fair'; _strengthColor = Colors.orangeAccent; }
      else if (strength <= 0.75) { _strengthLabel = 'Good'; _strengthColor = Colors.amberAccent; }
      else { _strengthLabel = 'Strong'; _strengthColor = const Color(0xFF3DBE6E); }
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    _animController.dispose();
    super.dispose();
  }

  bool get _passwordsMatch =>
      _passwordController.text == _confirmController.text && _confirmController.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ── Background ──
          SizedBox.expand(child: Image.asset('images/auth/mountains.jpg', fit: BoxFit.cover)),
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
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.17),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.5),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.lock_outline_rounded, size: 50, color: Colors.white),
                            const SizedBox(height: 16),
                            const Text("Set Password", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
                            const SizedBox(height: 8),
                            Text("Create a secure new password", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                            const SizedBox(height: 32),

                            _buildGlassField(
                              controller: _passwordController,
                              hint: "New Password",
                              obscure: _obscurePassword,
                              onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            
                            if (_passwordController.text.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _buildStrengthIndicator(),
                            ],

                            const SizedBox(height: 16),

                            _buildGlassField(
                              controller: _confirmController,
                              hint: "Confirm Password",
                              obscure: _obscureConfirm,
                              onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                            ),

                            const SizedBox(height: 20),
                            _buildRequirements(),
                            const SizedBox(height: 32),

                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: (_passwordsMatch && _strength >= 0.5 && !_loading) ? _handleSave : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3DBE6E),
                                  disabledBackgroundColor: Colors.white.withOpacity(0.1),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  elevation: 0,
                                ),
                                child: _loading 
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text("Save Password", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  Widget _buildGlassField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
              suffixIcon: IconButton(
                icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: Colors.white60),
                onPressed: onToggle,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStrengthIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: _strength,
          backgroundColor: Colors.white10,
          valueColor: AlwaysStoppedAnimation<Color>(_strengthColor),
          minHeight: 4,
        ),
        const SizedBox(height: 4),
        Text("Strength: $_strengthLabel", style: TextStyle(color: _strengthColor, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildRequirements() {
    final p = _passwordController.text;
    bool match = _passwordsMatch;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _reqRow("8+ Characters", p.length >= 8),
          _reqRow("Uppercase & Number", p.contains(RegExp(r'[A-Z]')) && p.contains(RegExp(r'[0-9]'))),
          _reqRow("Passwords Match", match),
        ],
      ),
    );
  }

  Widget _reqRow(String text, bool met) {
    return Row(
      children: [
        Icon(met ? Icons.check_circle : Icons.circle_outlined, size: 14, color: met ? const Color(0xFF3DBE6E) : Colors.white30),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: met ? Colors.white : Colors.white38, fontSize: 12)),
      ],
    );
  }

  // Future<void> _handleSave() async {
  //   setState(() => _loading = true);
  //   final response = await AuthService.resetPassword(
  //     email: widget.email,
  //     code: widget.code,
  //     newPassword: _passwordController.text.trim(),
  //   );
  //   if (!mounted) return;
  //   setState(() => _loading = false);

  //   if (response.success) {
  //     _showSuccessDialog();
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.message ?? "Error")));
  //   }
  // }

  Future<void> _handleSave() async {
    setState(() => _loading = true);
    
    final response = await AuthService.resetPassword(
      email: widget.email,
      code: widget.code,
      newPassword: _passwordController.text.trim(),
    );
    
    if (!mounted) return;
    setState(() => _loading = false);

    if (response.success) {
      // 🚀 Use the new AuthDialog for Success
      AuthDialog.show(
        context,
        type: AuthDialogType.success,
        title: 'Password Reset!',
        message: 'Your password has been updated.\nReturning to login...',
        onDone: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      );
    } else {
      // ❌ Use the new AuthDialog for Error
      AuthDialog.show(
        context,
        type: AuthDialogType.error,
        title: 'Reset Failed',
        message: response.message ?? 'Something went wrong. Please try again.',
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: Colors.white.withOpacity(0.9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text("Success!"),
          content: const Text("Your password has been reset. Please sign in with your new credentials."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              child: const Text("Back to Login", style: TextStyle(color: Color(0xFF3DBE6E), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
import 'dart:ui';
import 'package:flutter/material.dart';
import 'auth_service.dart';

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

class _SetPasswordScreenState extends State<SetPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  // Password strength
  double _strength = 0;
  String _strengthLabel = '';
  Color _strengthColor = Colors.transparent;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_checkStrength);
  }

  void _checkStrength() {
    final p = _passwordController.text;
    double strength = 0;

    if (p.length >= 8) strength += 0.25;
    if (p.contains(RegExp(r'[A-Z]'))) strength += 0.25;
    if (p.contains(RegExp(r'[0-9]'))) strength += 0.25;
    if (p.contains(RegExp(r'[!@#\$&*~%^()_\-+=]'))) strength += 0.25;

    String label;
    Color color;

    if (strength <= 0.25) {
      label = 'Weak';
      color = Colors.red;
    } else if (strength <= 0.5) {
      label = 'Fair';
      color = Colors.orange;
    } else if (strength <= 0.75) {
      label = 'Good';
      color = Colors.amber;
    } else {
      label = 'Strong';
      color = const Color(0xFF48B67C);
    }

    setState(() {
      _strength = strength;
      _strengthLabel = label;
      _strengthColor = color;
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool get _passwordsMatch =>
      _passwordController.text == _confirmController.text &&
      _confirmController.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🌿 Background Gradient
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

          // 🌿 Blobs
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
            child: Stack(
              children: [
                // 🔙 Back Button
                Positioned(
                  top: 20,
                  left: 20,
                  child: _glassBackButton(context),
                ),

                // 📄 Content
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      children: [
                        // 🔐 Icon
                        Container(
                          height: 90,
                          width: 90,
                          decoration: BoxDecoration(
                            color: const Color(0xFF48B67C).withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_outline_rounded,
                            size: 44,
                            color: Color(0xFF48B67C),
                          ),
                        ),

                        const SizedBox(height: 28),

                        const Text(
                          "Set New Password",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          "Your new password must be different\nfrom your previous password.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.6),
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 40),

                        // 🔒 Password Field
                        _buildPasswordField(
                          controller: _passwordController,
                          hint: "New Password",
                          obscure: _obscurePassword,
                          onToggle: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),

                        // 💪 Strength Indicator
                        if (_passwordController.text.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildStrengthIndicator(),
                        ],

                        const SizedBox(height: 16),

                        // 🔒 Confirm Password Field
                        _buildPasswordField(
                          controller: _confirmController,
                          hint: "Confirm Password",
                          obscure: _obscureConfirm,
                          onToggle: () => setState(
                              () => _obscureConfirm = !_obscureConfirm),
                          showMatchIcon: _confirmController.text.isNotEmpty,
                          isMatching: _passwordsMatch,
                        ),

                        // ✅ Match hint
                        if (_confirmController.text.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const SizedBox(width: 16),
                              Icon(
                                _passwordsMatch
                                    ? Icons.check_circle_outline
                                    : Icons.cancel_outlined,
                                size: 14,
                                color: _passwordsMatch
                                    ? const Color(0xFF48B67C)
                                    : Colors.red,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _passwordsMatch
                                    ? "Passwords match"
                                    : "Passwords do not match",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _passwordsMatch
                                      ? const Color(0xFF48B67C)
                                      : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 14),

                        // 📋 Requirements checklist
                        _buildRequirements(),

                        const SizedBox(height: 30),

                        // 🚀 Save Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: (_passwordsMatch && _strength >= 0.5 && !_loading)
                              ? () async {
                                  final password = _passwordController.text.trim();

                                  setState(() => _loading = true);

                                  final response = await AuthService.resetPassword(
                                    email: widget.email,
                                    code: widget.code,
                                    newPassword: password,
                                  );

                                  if (!mounted) return;

                                  setState(() => _loading = false);

                                  if (response.success) {
                                    _showSuccessDialog(context);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          response.message ?? "Failed to reset password",
                                        ),
                                      ),
                                    );
                                  }
                                }
                              : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF48B67C),
                              disabledBackgroundColor:
                                  const Color(0xFF48B67C).withOpacity(0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 0,
                            ),
                            child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  "Save New Password",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    bool showMatchIcon = false,
    bool isMatching = false,
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
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          prefixIcon:
              const Icon(Icons.lock_outline, color: Color(0xFF48B67C)),
          suffixIcon: IconButton(
            icon: Icon(
              obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: Colors.grey,
            ),
            onPressed: onToggle,
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        ),
      ),
    );
  }

  Widget _buildStrengthIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: _strength,
            backgroundColor: Colors.grey.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(_strengthColor),
            minHeight: 5,
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            "Password strength: $_strengthLabel",
            style: TextStyle(
              fontSize: 12,
              color: _strengthColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequirements() {
    final p = _passwordController.text;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Password must contain:",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          _requirementRow("At least 8 characters", p.length >= 8),
          _requirementRow("One uppercase letter",
              p.contains(RegExp(r'[A-Z]'))),
          _requirementRow(
              "One number", p.contains(RegExp(r'[0-9]'))),
          _requirementRow("One special character",
              p.contains(RegExp(r'[!@#\$&*~%^()_\-+=]'))),
        ],
      ),
    );
  }

  Widget _requirementRow(String text, bool met) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 15,
            color: met ? const Color(0xFF48B67C) : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: met ? const Color(0xFF48B67C) : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 72,
                width: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF48B67C).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 38,
                  color: Color(0xFF48B67C),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Password Reset!",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Your password has been successfully reset. You can now sign in with your new password.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black.withOpacity(0.6),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    // Pop all routes and go to login
                    Navigator.of(context)
                        .popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF48B67C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Back to Sign In",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glassBackButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _blurCircle(double size, Color color) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
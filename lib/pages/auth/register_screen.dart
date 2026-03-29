import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'auth_service.dart';
import '../../widgets/auth_dialog.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _phoneNumber = '';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    // ... your existing validation logic ...
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty || _phoneNumber.isEmpty) {
      AuthDialog.show(context, type: AuthDialogType.error, title: 'Missing Fields', message: 'Please fill in all fields.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await AuthService.register(
        name: name,
        phone: _phoneNumber,
        email: email,
        password: password,
      );
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (response.success) {
        AuthDialog.show(
          context,
          type: AuthDialogType.success,
          title: 'Account Created!',
          message: 'Redirecting to login...',
          onDone: () => Navigator.pop(context),
        );
      } else {
        AuthDialog.show(context, type: AuthDialogType.error, title: 'Registration Failed', message: response.message ?? 'Error');
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ── Background (Matching Login) ──
          SizedBox.expand(child: Image.asset('images/auth/plain.jpg', fit: BoxFit.cover)),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withOpacity(0.15), Colors.black.withOpacity(0.5)],
              ),
            ),
          ),

          // ── Content ──
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.06, vertical: 24),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Create Account", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
                            const SizedBox(height: 8),
                            Text("Fill in the details to get started", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                            const SizedBox(height: 28),

                            _buildGlassField(controller: _nameController, hint: "Full Name", icon: Icons.person_outline),
                            const SizedBox(height: 14),
                            
                            _buildGlassPhoneField(),
                            const SizedBox(height: 14),

                            _buildGlassField(controller: _emailController, hint: "Email Address", icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                            const SizedBox(height: 14),

                            _buildGlassField(
                              controller: _passwordController,
                              hint: "Password",
                              icon: Icons.lock_outline,
                              isPassword: true,
                              obscure: _obscurePassword,
                              onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            const SizedBox(height: 14),

                            _buildGlassField(
                              controller: _confirmPasswordController,
                              hint: "Confirm Password",
                              icon: Icons.lock_reset_outlined,
                              isPassword: true,
                              obscure: _obscureConfirm,
                              onToggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
                            ),
                            
                            const SizedBox(height: 32),

                            // ── Register Button ──
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleRegister,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3DBE6E),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  elevation: 0,
                                ),
                                child: _isLoading 
                                  ? const CircularProgressIndicator(color: Colors.white) 
                                  : const Text("Sign Up", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            
                            const SizedBox(height: 24),

                            Center(
                              child: GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Text.rich(
                                  TextSpan(
                                    text: "Already have an account? ",
                                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                                    children: const [
                                      TextSpan(text: "Login here", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
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
          
          // Back Button
          Positioned(
            top: 50,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
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
            border: Border.all(color: Colors.white.withOpacity(0.30)),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 14),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: Colors.white.withOpacity(0.6)),
                      onPressed: onToggleObscure,
                    )
                  : Icon(icon, color: Colors.white.withOpacity(0.55), size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassPhoneField() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.30)),
          ),
          child: IntlPhoneField(
            initialCountryCode: 'KE', // Set to Kenya for Agrosight/shambaos
            style: const TextStyle(color: Colors.white, fontSize: 15),
            dropdownTextStyle: const TextStyle(color: Colors.white),
            cursorColor: Colors.white,
            dropdownIcon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Phone Number',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
            ),
            onChanged: (phone) => _phoneNumber = phone.completeNumber,
          ),
        ),
      ),
    );
  }
}
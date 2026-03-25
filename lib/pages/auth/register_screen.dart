import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ✨ White Glossy Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFFFFFF), // pure white
                  Color(0xFFF2F4F7), // soft grey-white
                  Color(0xFFE8F0EC), // hint of green-white
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // ✨ Floating Blobs (Subtle Depth)
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
                // Back Button
                Positioned(
                  top: 20,
                  left: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            size: 18,
                            color: Color(0xFF1A1A1A),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                  ),
                ),

                // Main Content
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Create Account",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Create a new account to get started and enjoy\nseamless access to our features.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.6),
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Name Field
                        _buildTextField(
                          hint: "Name",
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 16),

                        // Email Field
                        _buildTextField(
                          hint: "Email address",
                          icon: Icons.email_outlined,
                        ),
                        const SizedBox(height: 16),

                        // Password Field
                        _buildTextField(
                          hint: "Password",
                          icon: Icons.lock_outline,
                          isPassword: true,
                        ),
                        const SizedBox(height: 16),

                        // Confirm Password Field
                        _buildTextField(
                          hint: "Confirm Password",
                          icon: Icons.lock_outline,
                          isPassword: true,
                        ),

                        const SizedBox(height: 30),

                        // Create Account Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              // Logic to save user to ShambaOS DB
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF48B67C),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 4,
                              shadowColor:
                                  const Color(0xFF48B67C).withOpacity(0.4),
                            ),
                            child: const Text(
                              "Create Account",
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

                        // Sign In Link
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text.rich(
                            TextSpan(
                              text: "Already have an account? ",
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 13,
                              ),
                              children: [
                                TextSpan(
                                  text: "Sign In here",
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
                        const SizedBox(height: 40),

                        Text(
                          "Or Continue With Account",
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.5),
                            fontSize: 12,
                          ),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔤 Solid White TextField (Clear Input Area)
  Widget _buildTextField({
    required String hint,
    required IconData icon,
    bool isPassword = false,
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
        obscureText: isPassword,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: const Color(0xFF48B67C),
            size: 22,
          ),
          suffixIcon: isPassword
              ? Icon(
                  Icons.visibility_off_outlined,
                  color: Colors.grey,
                  size: 20,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 20,
          ),
        ),
      ),
    );
  }

  // 🔘 Social Button (Glass Effect with Asset Icons)
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
          child: Center(
            child: Image.asset(assetPath, height: 22),
          ),
        ),
      ),
    );
  }

  // ✨ Blurred Circle (Background Glow)
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
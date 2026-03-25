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

                        const Text(
                          "Create Account",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          "Create a new account to get started and enjoy\nseamless access to our features.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.6),
                          ),
                        ),

                        const SizedBox(height: 40),

                        _buildTextField(
                          hint: "Name",
                          icon: Icons.person_outline,
                        ),

                        const SizedBox(height: 16),

                        // 📱 FIXED PHONE FIELD
                        _buildPhoneField(),

                        const SizedBox(height: 16),

                        _buildTextField(
                          hint: "Email address",
                          icon: Icons.email_outlined,
                        ),

                        const SizedBox(height: 16),

                        _buildTextField(
                          hint: "Password",
                          icon: Icons.lock_outline,
                          isPassword: true,
                        ),

                        const SizedBox(height: 16),

                        _buildTextField(
                          hint: "Confirm Password",
                          icon: Icons.lock_outline,
                          isPassword: true,
                        ),

                        const SizedBox(height: 30),

                        // 🚀 Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF48B67C),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              "Create Account",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text.rich(
                            TextSpan(
                              text: "Already have an account? ",
                              children: [
                                TextSpan(
                                  text: "Sign In here",
                                  style: TextStyle(
                                    color: Color(0xFF48B67C),
                                    fontWeight: FontWeight.bold,
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

  // ================= PHONE FIELD =================
  Widget _buildPhoneField() {
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
      child: IntlPhoneField(
        initialCountryCode: 'KE',
        showCountryFlag: true,
        dropdownIconPosition: IconPosition.trailing,
        dropdownIcon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
        flagsButtonPadding: const EdgeInsets.only(left: 15),
        flagsButtonMargin: EdgeInsets.zero, // 👈 Add this
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(fontSize: 15, color: Colors.black87),
        dropdownTextStyle: const TextStyle(fontSize: 15, color: Colors.black87),
        decoration: const InputDecoration(
          hintText: "Phone Number",
          hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
          border: InputBorder.none,
          counterText: "",
          contentPadding: EdgeInsets.symmetric(vertical: 20),
        ),
        onChanged: (phone) {
          print(phone.completeNumber);
        },
      ),
    );
  }

  // ================= TEXT FIELD =================
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
          ),
        ],
      ),
      child: TextField(
        obscureText: isPassword,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: const Color(0xFF48B67C)),
          suffixIcon: isPassword
              ? const Icon(Icons.visibility_off_outlined)
              : null,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        ),
      ),
    );
  }

  // ================= BUTTONS =================
  Widget _socialButton(String assetPath) {
    return Container(
      height: 50,
      width: 50,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      child: Center(
        child: Image.asset(assetPath, height: 22),
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
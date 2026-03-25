import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _rememberMe = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7), // The soft grey background
      body: SafeArea(
        child: Stack(
          children: [
            // // 1. Top Back Button
            // Positioned(
            //   top: 20,
            //   left: 20,
            //   child: Container(
            //     decoration: const BoxDecoration(
            //       color: Colors.white,
            //       shape: BoxShape.circle,
            //     ),
            //     child: IconButton(
            //       icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black),
            //       onPressed: () => Navigator.pop(context),
            //     ),
            //   ),
            // ),

            // 2. Main Content
            Center(
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
                        color: Colors.grey[600],
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 40),

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

                    // Remember Me & Forgot Password Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              activeColor: const Color(0xFF48B67C),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              onChanged: (value) {
                                setState(() => _rememberMe = value!);
                              },
                            ),
                            const Text("Remember me", style: TextStyle(fontSize: 13)),
                          ],
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            "Forgot Password",
                            style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF48B67C),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          elevation: 0,
                        ),
                        child: const Text(
                          "Login",
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Sign Up Link
                    GestureDetector(
                      onTap: () {},
                      child: const Text.rich(
                        TextSpan(
                          text: "Don't have an account? ",
                          style: TextStyle(color: Colors.grey),
                          children: [
                            TextSpan(
                              text: "Sign Up here",
                              style: TextStyle(
                                color: Color(0xFF48B67C),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),

                    // Social Logins
                    const Text(
                      "Or Continue With Account",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _socialButton('assets/facebook.png'), // Replace with your asset paths
                        const SizedBox(width: 20),
                        _socialButton('assets/google.png'),
                        const SizedBox(width: 20),
                        _socialButton('assets/apple.png'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper for Input Fields
  Widget _buildTextField({required String hint, required IconData icon, bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        obscureText: isPassword,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          prefixIcon: Icon(icon, color: Colors.grey[400], size: 22),
          suffixIcon: isPassword ? const Icon(Icons.visibility_off_outlined, color: Colors.grey, size: 20) : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        ),
      ),
    );
  }

  // Helper for Social Buttons
  Widget _socialButton(String assetPath) {
    return Container(
      height: 50,
      width: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Image.network( // Using network for placeholder, change to Image.asset later
          'https://cdn-icons-png.flaticon.com/512/2991/2991148.png', // Example Google Icon
          height: 24,
        ),
      ),
    );
  }
}
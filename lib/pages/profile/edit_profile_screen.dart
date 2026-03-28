import 'dart:ui';
import 'package:flutter/material.dart';
import 'profile_service.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class EditProfileScreen extends StatefulWidget {
  final String name;
  final String email;
  final String phone;
  final String username;

  const EditProfileScreen({
    super.key,
    required this.name,
    required this.email,
    required this.phone,
    required this.username,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController usernameController;

  bool isLoading = false;
  bool isFetching = true;

  String fullPhoneNumber = '';

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.name);
    emailController = TextEditingController(text: widget.email);
    phoneController = TextEditingController(text: widget.phone);
    usernameController = TextEditingController(text: widget.username);

    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final response = await ProfileService.getProfile();

    if (response.success && response.data != null) {
      final data = response.data;

      nameController.text = data['name'] ?? widget.name;
      emailController.text = data['email'] ?? widget.email;
      phoneController.text = data['phone'] ?? widget.phone;
      usernameController.text = data['username'] ?? widget.username;
    }

    setState(() => isFetching = false);
  }

  Future<void> _saveProfile() async {
    setState(() => isLoading = true);

    final response = await ProfileService.updateProfile(
      name: nameController.text,
      email: emailController.text,
      phone: fullPhoneNumber.isEmpty
          ? phoneController.text
          : fullPhoneNumber,
      username: usernameController.text,
    );

    setState(() => isLoading = false);

    if (response.success) {
      Navigator.pop(context, {
        "name": nameController.text,
        "email": emailController.text,
        "phone": fullPhoneNumber.isEmpty
            ? phoneController.text
            : fullPhoneNumber,
        "username": usernameController.text,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: isFetching
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // BACK
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: _softContainer(
                            child: const Icon(Icons.arrow_back),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // HEADER
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Edit Profile",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "Update your details",
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // AVATAR
                  _softContainer(
                    padding: const EdgeInsets.all(20),
                    shape: BoxShape.circle,
                    child: const Icon(Icons.person, size: 50),
                  ),

                  const SizedBox(height: 20),

                  // FORM
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _softContainer(
                        padding: const EdgeInsets.all(20),
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              _input(nameController, "Full Name"),
                              _input(emailController, "Email"),

                              IntlPhoneField(
                                initialValue: phoneController.text,
                                decoration: _inputDecoration("Phone"),
                                initialCountryCode: 'KE',
                                onChanged: (phone) {
                                  fullPhoneNumber =
                                      phone.completeNumber;
                                },
                              ),

                              _input(usernameController, "Username"),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // BUTTON
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C853),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 5,
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                "Save Changes",
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ✨ SOFT WHITE CONTAINER (Neumorphism)
  Widget _softContainer({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(12),
    BoxShape shape = BoxShape.rectangle,
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        shape: shape,
        borderRadius:
            shape == BoxShape.rectangle ? BorderRadius.circular(20) : null,
        boxShadow: const [
          BoxShadow(
            color: Colors.white,
            offset: Offset(-4, -4),
            blurRadius: 10,
          ),
          BoxShadow(
            color: Colors.black12,
            offset: Offset(4, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _input(TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        decoration: _inputDecoration(hint),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF7F9FC),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
    );
  }
}
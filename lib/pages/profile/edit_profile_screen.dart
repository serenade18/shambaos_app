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

  Future<void> _fetchProfile() async {
    final response = await ProfileService.getProfile();

    if (response.success && response.data != null) {
      final data = response.data;

      nameController.text = data['name'] ?? widget.name;
      emailController.text = data['email'] ?? widget.email;
      phoneController.text = data['phone'] ?? widget.phone;
      usernameController.text = data['username'] ?? widget.username;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message ?? 'Failed to load profile')),
      );
    }

    setState(() => isFetching = false);
  }

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.name);
    emailController = TextEditingController(text: widget.email);
    phoneController = TextEditingController(text: widget.phone);
    usernameController = TextEditingController(text: widget.username);

    _fetchProfile();
  }

  Future<void> _saveProfile() async {
    setState(() => isLoading = true);

    final response = await ProfileService.updateProfile(
      name: nameController.text,
      email: emailController.text,
      phone: phoneController.text,
      username: usernameController.text,
    );

    setState(() => isLoading = false);

    if (response.success) {
      Navigator.pop(context, {
        "name": nameController.text,
        "email": emailController.text,
        "phone": phoneController.text,
        "username": usernameController.text,
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message ?? 'Update failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: isFetching
          ? const Center(child: CircularProgressIndicator())
          : Column(
          children: [
            // 🔙 BACK + TITLE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, size: 22),
                  ),
                ],
              ),
            ),

            // 🧾 HEADER
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Edit Your Profile",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Edit your profile details below",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 👤 AVATAR
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey.shade200,
                  child: const Icon(Icons.person, size: 50, color: Colors.grey),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    height: 34,
                    width: 34,
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(255, 223, 176, 21),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // 📥 FORM
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _input(nameController, "Full Name"),
                    _input(emailController, "Email"),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: IntlPhoneField(
                        initialValue: phoneController.text,
                        decoration: InputDecoration(
                          hintText: "Phone",
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        initialCountryCode: 'KE', // 🔁 change to your default (e.g. US, NG, IN)
                        onChanged: (phone) {
                          fullPhoneNumber = phone.completeNumber; // ✅ FULL number with country code
                        },
                        onCountryChanged: (country) {
                          // optional debug
                          // print('Country changed to: ${country.name}');
                        },
                      ),
                    ),
                    _input(usernameController, "Username"),
                  ],
                ),
              ),
            ),

            // 🔥 BUTTON
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 16, 150, 65),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Save Changes",
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  // ✨ CUSTOM INPUT (Rounded like your design)
  Widget _input(TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
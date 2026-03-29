import 'dart:ui';
import 'package:flutter/material.dart';
import 'profile_service.dart';
import '../../widgets/auth_dialog.dart'; // Using the AuthDialog we created earlier
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

  final Color themeGreen = const Color(0xFF3DBE6E);
  final Color inputBg = const Color(0xFFE9E9E9);

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
      setState(() {
        nameController.text = data['name'] ?? widget.name;
        emailController.text = data['email'] ?? widget.email;
        phoneController.text = data['phone'] ?? widget.phone;
        usernameController.text = data['username'] ?? widget.username;
      });
    }
    setState(() => isFetching = false);
  }

  Future<void> _saveProfile() async {
    setState(() => isLoading = true);

    final response = await ProfileService.updateProfile(
      name: nameController.text.trim(),
      email: emailController.text.trim(),
      phone: fullPhoneNumber.isEmpty ? phoneController.text : fullPhoneNumber,
      username: usernameController.text.trim(),
    );

    setState(() => isLoading = false);

    if (response.success) {
      AuthDialog.show(
        context,
        type: AuthDialogType.success,
        title: "Profile Updated",
        message: "Your changes have been saved successfully.",
        onDone: () => Navigator.pop(context, true),
      );
    } else {
      AuthDialog.show(
        context,
        type: AuthDialogType.error,
        title: "Update Failed",
        message: response.message ?? "Could not update profile.",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Personal info",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      body: isFetching
          ? Center(child: CircularProgressIndicator(color: themeGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  
                  // 🤳 Selfie Section
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: inputBg,
                          child: Icon(Icons.person_outline, size: 50, color: Colors.black.withOpacity(0.3)),
                        ),
                        const SizedBox(height: 16),
                        const Text("Take a Selfie", 
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(
                          "Add your photo so drivers can recognise you\nwhen picking or delivering your package.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black.withOpacity(0.5), fontSize: 13, height: 1.4),
                        ),
                        const SizedBox(height: 16),
                        _buildPhotoButton(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // 📝 Form Fields
                  _fieldLabel("Name"),
                  _buildInput(nameController),

                  _fieldLabel("Email"),
                  _buildInput(emailController),

                  _fieldLabel("Phone Number"),
                  _buildPhoneInput(),

                  _fieldLabel("Username"),
                  _buildInput(usernameController),

                  const SizedBox(height: 40),

                  // 💾 Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Save Changes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 16),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
    );
  }

  Widget _buildInput(TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildPhoneInput() {
    return Container(
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IntlPhoneField(
        initialValue: phoneController.text,
        disableLengthCheck: true,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        initialCountryCode: 'KE',
        onChanged: (phone) => fullPhoneNumber = phone.completeNumber,
      ),
    );
  }

  Widget _buildPhotoButton() {
    return TextButton.icon(
      onPressed: () {}, // Add Image Picker Logic here
      icon: Icon(Icons.camera_alt_outlined, color: themeGreen, size: 20),
      label: Text("Take Photo", style: TextStyle(color: themeGreen, fontWeight: FontWeight.bold)),
      style: TextButton.styleFrom(
        backgroundColor: themeGreen.withOpacity(0.1),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
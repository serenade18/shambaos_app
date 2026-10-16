import 'dart:ui';
import 'package:flutter/material.dart';
import 'profile_service.dart';
import '../../services/app_colors.dart';
import '../../widgets/auth_dialog.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../l10n/tr.dart';

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

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    usernameController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    final response = await ProfileService.getProfile();
    if (!response.error && response.data != null) {  
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

    if (!response.error) {  
      AuthDialog.show(
        context,
        type: AuthDialogType.success,
        title: 'Profile Updated'.tr,
        message: 'Your changes have been saved successfully.'.tr,
        onDone: () => Navigator.pop(context, true),
      );
    } else {
      AuthDialog.show(
        context,
        type: AuthDialogType.error,
        title: 'Update Failed'.tr,
        message: response.message ?? 'Could not update profile.'.tr,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.cardBackground,
      appBar: AppBar(
        backgroundColor: colors.cardBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: colors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Personal info'.tr,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: isFetching
          ? Center(
              child: CircularProgressIndicator(color: AppColors.brand),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // ── Avatar / selfie section ─────────────────────
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: colors.scaffoldBackground,
                          child: Icon(
                            Icons.person_outline,
                            size: 50,
                            color: colors.textHint,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Take a Selfie'.tr,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add a profile photo to identify yourself in our community'.tr,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildPhotoButton(colors),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ── Form fields ─────────────────────────────────
                  _fieldLabel('Name'.tr, colors),
                  _buildInput(nameController, colors),

                  _fieldLabel('Email'.tr, colors),
                  _buildInput(emailController, colors),

                  _fieldLabel('Phone Number'.tr, colors),
                  _buildPhoneInput(colors),

                  _fieldLabel('Username'.tr, colors),
                  _buildInput(usernameController, colors),

                  const SizedBox(height: 40),

                  // ── Save button ─────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brand,
                        disabledBackgroundColor:
                            AppColors.brand.withOpacity(0.6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Save Changes'.tr,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  // ── Field label ──────────────────────────────────────────────
  Widget _fieldLabel(String label, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 16),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: colors.textPrimary,
        ),
      ),
    );
  }

  // ── Text input ───────────────────────────────────────────────
  Widget _buildInput(TextEditingController controller, AppColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.scaffoldBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: colors.textPrimary),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          hintStyle: TextStyle(color: colors.textHint),
        ),
      ),
    );
  }

  // ── Phone input ──────────────────────────────────────────────
  Widget _buildPhoneInput(AppColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.scaffoldBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IntlPhoneField(
        initialValue: phoneController.text,
        disableLengthCheck: true,
        style: TextStyle(color: colors.textPrimary),
        dropdownTextStyle: TextStyle(color: colors.textPrimary),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          hintStyle: TextStyle(color: colors.textHint),
        ),
        initialCountryCode: 'KE',
        onChanged: (phone) => fullPhoneNumber = phone.completeNumber,
      ),
    );
  }

  // ── Photo button ─────────────────────────────────────────────
  Widget _buildPhotoButton(AppColors colors) {
    return TextButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.camera_alt_outlined,
          color: AppColors.brand, size: 20),
      label: Text(
        'Take Photo'.tr,
        style: TextStyle(
          color: AppColors.brand,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: TextButton.styleFrom(
        backgroundColor: AppColors.brand.withOpacity(0.1),
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
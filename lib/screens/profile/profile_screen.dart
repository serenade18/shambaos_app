import 'package:flutter/material.dart';
import '../../services/app_colors.dart';
import 'package:flutter/services.dart';
import '../auth/auth_service.dart';
import '../onboarding/welcome_screens.dart';
import '../../main.dart';
import 'edit_profile_screen.dart';
import 'notification_screen.dart';
import '../../services/api_service.dart';
import '../../services/biometric_service.dart';
import '../../l10n/tr.dart';

class ProfileScreen extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String userPhone;
  final String username;

  const ProfileScreen({
    super.key,
    this.userName = 'User',
    this.userEmail = '',
    this.userPhone = '',
    this.username = '',
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late String _userName;
  late String _userEmail;
  late String _userPhone;
  late String _username;
  bool _biometricAvailable = false;
  bool _biometricOn = false;

  @override
  void initState() {
    super.initState();
    _userName = widget.userName;
    _userEmail = widget.userEmail;
    _userPhone = widget.userPhone;
    _username = widget.username;
    themeNotifier.addListener(_onThemeChange);
    _loadUser();
    _loadBiometric();
  }

  Future<void> _loadBiometric() async {
    final available = await BiometricService.isAvailable();
    final on = await AuthService.isBiometricEnabled();
    if (!mounted) return;
    setState(() {
      _biometricAvailable = available;
      _biometricOn = on;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    String? problem;
    if (value) {
      problem = await AuthService.enableBiometricLogin();
    } else {
      await AuthService.disableBiometricLogin();
    }
    if (!mounted) return;
    setState(() => _biometricOn = value && problem == null);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(problem ??
          (value
              ? 'Biometric login is on. Next time, sign in with your fingerprint or face.'.tr
              : 'Biometric login is off.'.tr)),
    ));
  }

  Future<void> _loadUser() async {
    // First try cached user from SharedPreferences
    final cached = await ApiService.getUser();
    if (cached != null && mounted) {
      setState(() {
        _userName  = cached['name']  ?? _userName;
        _userEmail = cached['email'] ?? _userEmail;
        _userPhone = cached['phone'] ?? _userPhone;
        _username  = cached['username'] ?? _username;
      });
    }

    // Then fetch fresh from API
    final res = await ApiService.get('/me', requiresAuth: true);
    if (!res.error && res.data != null && mounted) {
      final data = res.data;
      await ApiService.setUser(data); // update cache
      setState(() {
        _userName  = data['name']  ?? _userName;
        _userEmail = data['email'] ?? _userEmail;
        _userPhone = data['phone'] ?? _userPhone;
        _username  = data['username'] ?? _username;
      });
    }
  }

  @override
  void dispose() {
    themeNotifier.removeListener(_onThemeChange);
    super.dispose();
  }

  void _onThemeChange() => setState(() {});

  // ── Language ───────────────────────────────────────────────────────────────
  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.appColors.cardBackground,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 18),
            Text('Language'.tr,
                style: TextStyle(
                    color: context.appColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Messages from Shamba OS, SMS and emails use it'.tr,
                style: TextStyle(color: context.appColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 10),
            for (final entry in ApiService.languages.entries)
              ListTile(
                title: Text(entry.value,
                    style: TextStyle(color: context.appColors.textPrimary, fontSize: 15)),
                trailing: entry.key == ApiService.locale
                    ? const Icon(Icons.check_rounded, color: AppColors.brand)
                    : null,
                onTap: () {
                  Navigator.pop(sheet);
                  _setLanguage(entry.key);
                },
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _setLanguage(String code) async {
    if (code == ApiService.locale) return;
    final previous = ApiService.locale;
    await ApiService.setLocale(code);
    if (mounted) setState(() {});

    final res = await ApiService.patch('/me', {'preferred_locale': code});
    if (!mounted) return;
    if (!res.error && res.data is Map) {
      await ApiService.setUser(Map<String, dynamic>.from(res.data));
    } else {
      await ApiService.setLocale(previous);
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res.message ?? "Couldn't change the language. Check your connection.".tr),
      ));
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(context.overlayStyle);

    return Scaffold(
      backgroundColor: context.appColors.scaffoldBackground,

      // ── White AppBar — matches MenuScreen exactly ──────
      appBar: AppBar(
        backgroundColor: context.appColors.cardBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: context.overlayStyle,
        centerTitle: false,
        title: Text(
          'Profile'.tr,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: context.appColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: context.appColors.brandText,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Notification icon on top right
          IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              color: context.appColors.textPrimary,
              size: 22,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const NotificationScreen()),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: context.appColors.divider),
        ),
      ),

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Profile identity card ──────────────────
            _buildProfileCard(),

            const SizedBox(height: 20),

            // ── My Account section ─────────────────────
            _buildSectionLabel(
              icon: Icons.person_outline_rounded,
              label: 'MY ACCOUNT'.tr,
              trailing: '0 Points  ›'.tr,
            ),
            _buildMenuGroup([
              _MenuItem(
                color: const Color(0xFFFF6B35),
                icon: Icons.card_membership_rounded,
                label: 'Rewards Member'.tr,
                onTap: () {},
              ),
              _MenuItem(
                color: const Color(0xFF2196F3),
                icon: Icons.favorite_outline_rounded,
                label: 'Favourites'.tr,
                onTap: () {},
              ),
              _MenuItem(
                color: const Color(0xFFE91E8C),
                icon: Icons.credit_card_outlined,
                label: 'Payment Method'.tr,
                onTap: () {},
              ),
              _MenuItem(
                color: AppColors.brand,
                icon: Icons.calendar_today_outlined,
                label: 'Scheduled'.tr,
                onTap: () {},
              ),
              _MenuItem(
                color: const Color(0xFFFFC107),
                icon: Icons.business_center_outlined,
                label: 'Business Centre'.tr,
                onTap: () {},
              ),
              _MenuItem(
                color: const Color(0xFF9C27B0),
                icon: Icons.group_add_outlined,
                label: 'Invite and Earn'.tr,
                onTap: () {},
              ),
            ]),

            const SizedBox(height: 20),

            // ── General section ────────────────────────
            _buildSectionLabel(
              icon: Icons.settings_outlined,
              label: 'GENERAL'.tr,
            ),
            _buildMenuGroup([
              _MenuItem(
                color: const Color(0xFFFF6B35),
                icon: Icons.shield_outlined,
                label: 'Privacy Policy'.tr,
                onTap: () {},
              ),
              _MenuItem(
                color: const Color(0xFF2196F3),
                icon: Icons.description_outlined,
                label: 'Terms of Service'.tr,
                onTap: () {},
              ),
              _MenuItem(
                color: AppColors.brand,
                icon: Icons.notifications_outlined,
                label: 'Notifications'.tr,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationScreen()),
                  );
                },
              ),
              _MenuItem(
                color: const Color(0xFF9C27B0),
                icon: Icons.language_outlined,
                label: 'Language'.tr,
                value: ApiService.languages[ApiService.locale],
                onTap: _showLanguagePicker,
              ),
              _MenuItem(
                color: Colors.blueGrey,
                icon: Icons.dark_mode_outlined,
                label: 'Dark Mode'.tr,
                isToggle: true,
                toggleValue: themeNotifier.isDark,
                onToggle: (val) => themeNotifier.toggle(val),
              ),
              if (_biometricAvailable)
                _MenuItem(
                  color: const Color(0xFF00897B),
                  icon: Icons.fingerprint_rounded,
                  label: 'Biometric Login'.tr,
                  isToggle: true,
                  toggleValue: _biometricOn,
                  onToggle: _toggleBiometric,
                ),
            ]),

            const SizedBox(height: 20),

            // ── Logout ─────────────────────────────────
            _buildLogoutTile(),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // PROFILE CARD — avatar, name, email, edit button
  // ══════════════════════════════════════════════════════════
  Widget _buildProfileCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.appColors.divider, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar circle
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.brand,
            ),
            child: Center(
              child: Text(
                _getInitials(_userName),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Name + email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName.isEmpty ? 'User'.tr : _userName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.appColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _userEmail.isEmpty ? 'Farm Administrator'.tr : _userEmail,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.appColors.textSecondary,
                  ),
                ),
                if (_userPhone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    _userPhone,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.appColors.textHint,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Edit button
          GestureDetector(
            onTap: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditProfileScreen(
                    name: _userName,
                    email: _userEmail,
                    phone: _userPhone,
                    username: _username,
                  ),
                ),
              );
              if (updated != null) {
                setState(() {
                  _userName = updated['name'];
                  _userEmail = updated['email'];
                  _userPhone = updated['phone'];
                  _username = updated['username'];
                });
              }
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.brand,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_outlined, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Edit'.tr,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // SECTION LABEL
  // ══════════════════════════════════════════════════════════
  Widget _buildSectionLabel({
    required IconData icon,
    required String label,
    String? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Row(
        children: [
          Icon(icon, size: 13, color: context.appColors.textHint),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: context.appColors.textHint,
              letterSpacing: 1.1,
            ),
          ),
          const Spacer(),
          if (trailing != null)
            Text(
              trailing,
              style: TextStyle(
                fontSize: 12,
                color: context.appColors.brandText,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // MENU GROUP — white card, green-tinted icon boxes
  // ══════════════════════════════════════════════════════════
  Widget _buildMenuGroup(List<_MenuItem> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: context.appColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.appColors.divider, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isLast = index == items.length - 1;
          return Column(
            children: [
              _buildMenuTile(item),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 66,
                  endIndent: 16,
                  color: context.appColors.divider,
                ),
            ],
          );
        }),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // MENU TILE
  // ══════════════════════════════════════════════════════════
  Widget _buildMenuTile(_MenuItem item) {
    return GestureDetector(
      onTap: item.isToggle ? null : item.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            // A green icon well, the same for every item: colour is kept for states.
            Container(
              height: 38,
              width: 38,
              decoration: BoxDecoration(
                color: context.appColors.brandSoft,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(item.icon, color: context.appColors.brandText, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: context.appColors.textPrimary,
                ),
              ),
            ),
            if (item.isToggle)
              Switch(
                value: item.toggleValue ?? false,
                onChanged: item.onToggle,
                activeColor: Colors.white,
                activeTrackColor: AppColors.brand,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: context.appColors.border,
              )
            else ...[
              if (item.value != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    item.value!,
                    style: TextStyle(fontSize: 13, color: context.appColors.textSecondary),
                  ),
                ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: context.appColors.textHint,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // LOGOUT TILE
  // ══════════════════════════════════════════════════════════
  Widget _buildLogoutTile() {
    return GestureDetector(
      onTap: _showLogoutConfirm,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: context.appColors.cardBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFFEBEB), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 38,
              width: 38,
              decoration: BoxDecoration(
                color: Colors.red.shade400,
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  const Icon(Icons.logout_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 14),
            Text(
              'Log out'.tr,
              style: TextStyle(
                fontSize: 14,
                color: Colors.red.shade400,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: Colors.red.shade200,
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // LOGOUT DIALOG
  // ══════════════════════════════════════════════════════════
  void _showLogoutConfirm() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Log Out'.tr,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        content: Text(
          'Are you sure you want to log out?'.tr,
          style: TextStyle(color: context.appColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel'.tr,
              style: TextStyle(color: context.appColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              AuthService.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (_) => const WelcomeScreens()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Log Out'.tr,
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Menu Item Model ──────────────────────────────────────────────
class _MenuItem {
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isToggle;
  final bool? toggleValue;
  final ValueChanged<bool>? onToggle;
  final String? value; // shown before the arrow, e.g. the chosen language

  const _MenuItem({
    required this.color,
    required this.icon,
    required this.label,
    this.value,
    this.onTap,
    this.isToggle = false,
    this.toggleValue,
    this.onToggle,
  });
}
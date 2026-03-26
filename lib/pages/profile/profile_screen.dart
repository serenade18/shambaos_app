import 'dart:ui';
import 'package:flutter/material.dart';
import '../auth/auth_service.dart';
import '../onboarding/welcome_screens.dart';

class ProfileScreen extends StatefulWidget {
  final String userName;
  final String userEmail;

  const ProfileScreen({
    super.key,
    this.userName = 'User',
    this.userEmail = '',
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _darkMode = false;

  String _getInitials(String name) {
    if (name.isEmpty) return "U";
    final parts = name.trim().split(" ");
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Color _getAvatarColor(String name) {
    final colors = [
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];
    return colors[name.hashCode % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Gradient background ──────────────────────────────
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

          // ── Blobs ────────────────────────────────────────────
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── App Bar ────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      // Back button
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          height: 38,
                          width: 38,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.07),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            size: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Profile Card ───────────────────────
                        _buildProfileCard(),

                        const SizedBox(height: 28),

                        // ── Other Settings label ───────────────
                        const Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 12),
                          child: Text(
                            'Other Settings',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ),

                        // ── Settings Group 1 ───────────────────
                        _buildSettingsGroup([
                          _SettingItem(
                            icon: Icons.person_outline_rounded,
                            label: 'Profile Details',
                            onTap: () {},
                          ),
                          _SettingItem(
                            icon: Icons.lock_outline_rounded,
                            label: 'Password',
                            onTap: () {},
                          ),
                          _SettingItem(
                            icon: Icons.notifications_outlined,
                            label: 'Notifications',
                            onTap: () {},
                          ),
                          _SettingItem(
                            icon: Icons.dark_mode_outlined,
                            label: 'Dark Mode',
                            isToggle: true,
                            toggleValue: _darkMode,
                            onToggle: (val) =>
                                setState(() => _darkMode = val),
                          ),
                        ]),

                        const SizedBox(height: 16),

                        // ── Settings Group 2 ───────────────────
                        _buildSettingsGroup([
                          _SettingItem(
                            icon: Icons.headset_mic_outlined,
                            label: 'Support',
                            onTap: () {},
                          ),
                          _SettingItem(
                            icon: Icons.info_outline_rounded,
                            label: 'Report an Issue',
                            onTap: () {},
                          ),
                          _SettingItem(
                            icon: Icons.help_outline_rounded,
                            label: 'About ShambaOS',
                            onTap: () {},
                          ),
                          _SettingItem(
                            icon: Icons.language_outlined,
                            label: 'Language',
                            onTap: () {},
                          ),
                        ]),

                        const SizedBox(height: 16),

                        // ── Logout ─────────────────────────────
                        _buildLogoutTile(),

                        const SizedBox(height: 32),
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

  // ── Profile Card ─────────────────────────────────────────────
  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getAvatarColor(widget.userName),
              border: Border.all(
                color: const Color(0xFF48B67C).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                _getInitials(widget.userName),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),

          const SizedBox(width: 14),

          // Name + role
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName.isEmpty ? 'User' : widget.userName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.userEmail.isEmpty
                      ? 'Farm Administrator'
                      : widget.userEmail,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),

          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: Colors.black38,
          ),
        ],
      ),
    );
  }

  // ── Settings Group ────────────────────────────────────────────
  Widget _buildSettingsGroup(List<_SettingItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              _buildSettingTile(item),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 52,
                  color: Colors.black.withOpacity(0.06),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildSettingTile(_SettingItem item) {
    return GestureDetector(
      onTap: item.isToggle ? null : item.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              item.icon,
              size: 20,
              color: Colors.black54,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                item.label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            if (item.isToggle)
              Switch(
                value: item.toggleValue ?? false,
                onChanged: item.onToggle,
                activeColor: const Color(0xFF48B67C),
                activeTrackColor: const Color(0xFF48B67C).withOpacity(0.3),
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Colors.black26,
              )
            else
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Colors.black38,
              ),
          ],
        ),
      ),
    );
  }

  // ── Logout Tile ───────────────────────────────────────────────
  Widget _buildLogoutTile() {
    return GestureDetector(
      onTap: () => _showLogoutConfirm(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.logout_rounded,
              size: 20,
              color: Colors.red.shade400,
            ),
            const SizedBox(width: 14),
            Text(
              'Log out',
              style: TextStyle(
                fontSize: 14,
                color: Colors.red.shade400,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirm() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              AuthService.logout();   // clear token
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const WelcomeScreens()),
                (route) => false,     // remove ALL routes — back to welcome
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Log Out',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _blurCircle(double size, Color color) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

// ── Model ──────────────────────────────────────────────────────
class _SettingItem {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isToggle;
  final bool? toggleValue;
  final ValueChanged<bool>? onToggle;

  const _SettingItem({
    required this.icon,
    required this.label,
    this.onTap,
    this.isToggle = false,
    this.toggleValue,
    this.onToggle,
  });
}
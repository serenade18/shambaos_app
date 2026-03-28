import 'package:flutter/material.dart';
import '../auth/auth_service.dart';
import '../onboarding/welcome_screens.dart';
import 'edit_profile_screen.dart';
import 'notification_screen.dart'; // ← connect NotificationScreen

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
  bool _darkMode = false;

  late String _userName;
  late String _userEmail;
  late String _userPhone;
  late String _username;

  @override
  void initState() {
    super.initState();
    _userName = widget.userName;
    _userEmail = widget.userEmail;
    _userPhone = widget.userPhone;
    _username = widget.username;
  }

  String _getInitials(String name) {
    if (name.isEmpty) return "U";
    final parts = name.trim().split(" ");
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFFF4A03A),
      const Color(0xFFE57373),
      const Color(0xFF4DB6AC),
    ];
    return colors[name.hashCode % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              _buildHeader(context),
              Positioned(
                bottom: -35,
                left: 0,
                right: 0,
                child: _buildProfileCard(),
              ),
            ],
          ),
          const SizedBox(height: 50),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildSectionLabel(
                    icon: Icons.person_outline_rounded,
                    label: 'MY ACCOUNT',
                    trailing: '0 Points  >',
                  ),
                  _buildMenuGroup([
                    _MenuItem(
                      color: const Color(0xFFFF6B35),
                      icon: Icons.card_membership_rounded,
                      label: 'Rewards Member',
                      onTap: () {},
                    ),
                    _MenuItem(
                      color: const Color(0xFF2196F3),
                      icon: Icons.favorite_outline_rounded,
                      label: 'Favourites',
                      onTap: () {},
                    ),
                    _MenuItem(
                      color: const Color(0xFFE91E8C),
                      icon: Icons.credit_card_outlined,
                      label: 'Payment Method',
                      onTap: () {},
                    ),
                    _MenuItem(
                      color: const Color(0xFF4CAF50),
                      icon: Icons.calendar_today_outlined,
                      label: 'Scheduled',
                      onTap: () {},
                    ),
                    _MenuItem(
                      color: const Color(0xFFFFC107),
                      icon: Icons.business_center_outlined,
                      label: 'Business Centre',
                      onTap: () {},
                    ),
                    _MenuItem(
                      color: const Color(0xFF9C27B0),
                      icon: Icons.group_add_outlined,
                      label: 'Invite and Earn',
                      onTap: () {},
                    ),
                  ]),
                  const SizedBox(height: 20),
                  _buildSectionLabel(
                    icon: Icons.settings_outlined,
                    label: 'GENERAL',
                  ),
                  _buildMenuGroup([
                    _MenuItem(
                      color: const Color(0xFFFF6B35),
                      icon: Icons.shield_outlined,
                      label: 'Privacy Policy',
                      onTap: () {},
                    ),
                    _MenuItem(
                      color: const Color(0xFF2196F3),
                      icon: Icons.description_outlined,
                      label: 'Terms of Service',
                      onTap: () {},
                    ),
                    _MenuItem(
                      color: const Color(0xFF4CAF50),
                      icon: Icons.notifications_outlined,
                      label: 'Notifications',
                      // ── CONNECTED ──────────────────────────────────
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationScreen(),
                          ),
                        );
                      },
                    ),
                    _MenuItem(
                      color: const Color(0xFF9C27B0),
                      icon: Icons.language_outlined,
                      label: 'Language',
                      onTap: () {},
                    ),
                    _MenuItem(
                      color: Colors.blueGrey,
                      icon: Icons.dark_mode_outlined,
                      label: 'Dark Mode',
                      isToggle: true,
                      toggleValue: _darkMode,
                      onToggle: (val) => setState(() => _darkMode = val),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  _buildLogoutTile(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1B4332),
            Color(0xFF2D5A27),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back, size: 22, color: Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Profile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getAvatarColor(_userName),
            ),
            child: Center(
              child: Text(
                _getInitials(_userName),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName.isEmpty ? 'User' : _userName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _userEmail.isEmpty ? 'Farm Administrator' : _userEmail,
                  style: TextStyle(fontSize: 13, color: Colors.black.withOpacity(0.5)),
                ),
              ],
            ),
          ),
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 16, 150, 65),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_outlined, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Edit',
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

  Widget _buildSectionLabel({
    required IconData icon,
    required String label,
    String? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.black45),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.black45,
              letterSpacing: 1.0,
            ),
          ),
          const Spacer(),
          if (trailing != null)
            Text(trailing, style: const TextStyle(fontSize: 12, color: Colors.black45)),
        ],
      ),
    );
  }

  Widget _buildMenuGroup(List<_MenuItem> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
              _buildMenuTile(item),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 64,
                  endIndent: 16,
                  color: Colors.black.withOpacity(0.05),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildMenuTile(_MenuItem item) {
    return GestureDetector(
      onTap: item.isToggle ? null : item.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              height: 38,
              width: 38,
              decoration: BoxDecoration(color: item.color, shape: BoxShape.circle),
              child: Icon(item.icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                item.label,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (item.isToggle)
              Switch(
                value: item.toggleValue ?? false,
                onChanged: item.onToggle,
                activeColor: const Color(0xFF6B4EEA),
                activeTrackColor: const Color(0xFF6B4EEA).withOpacity(0.3),
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Colors.black26,
              )
            else
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.black26),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutTile() {
    return GestureDetector(
      onTap: _showLogoutConfirm,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            Container(
              height: 38,
              width: 38,
              decoration: BoxDecoration(color: Colors.red.shade400, shape: BoxShape.circle),
              child: const Icon(Icons.logout_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 14),
            Text(
              'Log out',
              style: TextStyle(
                fontSize: 15,
                color: Colors.red.shade400,
                fontWeight: FontWeight.w600,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              AuthService.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const WelcomeScreens()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Log Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Menu Item Model ────────────────────────────────────────────
class _MenuItem {
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isToggle;
  final bool? toggleValue;
  final ValueChanged<bool>? onToggle;

  const _MenuItem({
    required this.color,
    required this.icon,
    required this.label,
    this.onTap,
    this.isToggle = false,
    this.toggleValue,
    this.onToggle,
  });
}
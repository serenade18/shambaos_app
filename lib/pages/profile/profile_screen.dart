import 'dart:ui';
import 'package:flutter/material.dart';
import '../auth/auth_service.dart';
import '../onboarding/welcome_screens.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  String userName;
  String userEmail;
  String userPhone;
  String username;

  ProfileScreen({
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

  String _getInitials(String name) {
    if (name.isEmpty) return "U";
    final parts = name.trim().split(" ");
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  // Updated Avatar Color to match the Purple theme (e.g., Orange/Yellow)
  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFFF4A03A), // Match the Orange/Yellow avatar from image_5
      const Color(0xFFE57373), // A complementary red/pink
      const Color(0xFF4DB6AC), // A complementary teal
    ];
    return colors[name.hashCode % colors.length];
  }

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Using a Stack to overlap the card on the header
          Stack(
            clipBehavior: Clip.none, 
            alignment: Alignment.center,
            children: [
              _buildHeader(context),
              Positioned(
                bottom: -35, // This pushes half the card below the header line
                left: 0,
                right: 0,
                child: _buildProfileCard(),
              ),
            ],
          ),

          // This spacer provides room for the overlapping card so 
          // the list below doesn't start underneath it.
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

                  // ── GENERAL section ──────────────────────────
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
                      onTap: () {},
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

                  // ── Logout ───────────────────────────────────
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
    
  // ══════════════════════════════════════════════════════════
  //  HEADER (Update: Added LinearGradient to match the Purple image)
  // ══════════════════════════════════════════════════════════
  Widget _buildHeader(BuildContext context) {
      return Container(
        // Increased height to match the immersive look of the reference
        height: 180, 
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            // Adjusted alignment to match the diagonal flow in the image
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2D5A27), // Primary Purple
              Color(0xFF2D5A27), // Lighter Purple/Indigo
            ],
          ),
        ),
        child: Stack(
          children: [
            // Optional: You can add the subtle star/shape watermark here if needed
            SafeArea(
              child: Padding(
                // Increased top padding to push content down from the status bar
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          // Slightly more opaque white for the button background
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back, // Standard arrow matches the reference better
                          size: 22,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Profile',
                      style: TextStyle(
                        fontSize: 24, // Slightly larger font size
                        fontWeight: FontWeight.w600, // Semi-bold for a cleaner look
                        color: Colors.white,
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
  //  PROFILE CARD (Update: Edit button color updated to Purple)
  // ══════════════════════════════════════════════════════════
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
              color: _getAvatarColor(widget.userName),
            ),
            child: Center(
              child: Text(
                _getInitials(widget.userName),
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
                  widget.userName.isEmpty ? 'User' : widget.userName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.userEmail.isEmpty ? 'Farm Administrator' : widget.userEmail,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black.withOpacity(0.5),
                  ),
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
                    name: widget.userName,
                    email: widget.userEmail,
                    phone: widget.userPhone,
                    username: widget.username,
                  ),
                ),
              );

              if (updated != null) {
                setState(() {
                  widget.userName = updated['name'];
                  widget.userEmail = updated['email'];
                  widget.userPhone = updated['phone'];
                  widget.username = updated['username'];
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

  // ══════════════════════════════════════════════════════════
  //  SECTION LABEL
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
            Text(
              trailing,
              style: const TextStyle(fontSize: 12, color: Colors.black45),
            ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  MENU GROUP
  // ══════════════════════════════════════════════════════════
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
                  indent:  Indent_indent_fix,
                  endIndent: Indent_endIndent_fix,
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
              decoration: BoxDecoration(
                color: item.color,
                shape: BoxShape.circle,
              ),
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
                // Updated: Active color for dark mode toggle changed to Purple
                activeColor: const Color(0xFF6B4EEA), 
                activeTrackColor: const Color(0xFF6B4EEA).withOpacity(0.3),
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Colors.black26,
              )
            else
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Colors.black26,
              ),
          ],
        ),
      ),
    );
  }

  // Define Indent Constants (if not already defined)
  double get Indent_indent_fix => 64;
  double get Indent_endIndent_fix => 16;

  // ══════════════════════════════════════════════════════════
  //  LOGOUT TILE
  // ══════════════════════════════════════════════════════════
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
              decoration: BoxDecoration(
                color: Colors.red.shade400,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded,
                  color: Colors.white, size: 18),
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

  // ══════════════════════════════════════════════════════════
  //  LOGIC — all unchanged from original
  // ══════════════════════════════════════════════════════════
  void _showLogoutConfirm() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Log Out',
                style: TextStyle(color: Colors.white)),
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
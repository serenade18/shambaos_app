import 'package:flutter/material.dart';
import '../../services/app_colors.dart';
import 'package:flutter/services.dart';
import '../../services/app_type.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/ledger.dart';
import '../../widgets/ledger_parts.dart';
import '../auth/auth_service.dart';
import '../customers/customer_screen.dart';
import '../home_service.dart';
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
  String? _role; // owner, manager or field_worker in this farm account
  String? _farmName;

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
    _loadFarm();
  }

  /// "Farm owner · Kamau farm": the person's role here and the farm's name.
  Future<void> _loadFarm() async {
    final (orgs, farms) = await (ApiService.get('/me/organisations', requiresAuth: true), HomeService.listFarms()).wait;
    if (!mounted) return;
    String? role;
    if (!orgs.error && orgs.data is Map) {
      final list = (orgs.data['memberships'] as List? ?? []).whereType<Map>().toList();
      final mine = list.where((m) => '${m['organisation_id']}' == ApiService.orgId).firstOrNull ?? list.firstOrNull;
      role = mine?['role']?.toString();
    }
    setState(() {
      _role = role;
      _farmName = farms.isEmpty ? null : '${farms.first['name'] ?? ''}';
    });
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
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  String? get _roleLabel => switch (_role) {
        'owner' => 'Farm owner'.tr,
        'manager' => 'Farm manager'.tr,
        'field_worker' => 'Field worker'.tr,
        _ => null,
      };

  // The design's line icons (Lucide, ISC licence).
  static const _users = '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/>';
  static const _bell = '<path d="M10.268 21a2 2 0 0 0 3.464 0"/><path d="M3.262 15.326A1 1 0 0 0 4 17h16a1 1 0 0 0 .74-1.673C19.41 13.956 18 12.499 18 8A6 6 0 0 0 6 8c0 4.499-1.411 5.956-2.738 7.326"/>';
  static const _globe = '<circle cx="12" cy="12" r="10"/><path d="M12 2a14.5 14.5 0 0 0 0 20 14.5 14.5 0 0 0 0-20"/><path d="M2 12h20"/>';
  static const _fingerprint = '<path d="M12 10a2 2 0 0 0-2 2c0 1.02-.1 2.51-.26 4"/><path d="M14 13.12c0 2.38 0 6.38-1 8.88"/><path d="M17.29 21.02c.12-.6.43-2.3.5-3.02"/><path d="M2 12a10 10 0 0 1 18-6"/><path d="M2 16h.01"/><path d="M21.8 16c.2-2 .131-5.354 0-6"/><path d="M5 19.5C5.5 18 6 15 6 12a6 6 0 0 1 .34-2"/><path d="M8.65 22c.21-.66.45-1.32.57-2"/><path d="M9 6.8a6 6 0 0 1 9 5.2v2"/>';
  static const _moon = '<path d="M12 3a6 6 0 0 0 9 9 9 9 0 1 1-9-9Z"/>';

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    SystemChrome.setSystemUIOverlayStyle(context.overlayStyle);
    Widget rule() => Divider(height: 1, thickness: 1, color: c.divider);

    return Scaffold(
      backgroundColor: c.scaffoldBackground,
      extendBody: true, // the page scrolls under the nav bar
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 20, 16, AppBottomNav.scrollPadding(context)),
          children: [
            Text('Profile'.tr,
                style: TextStyle(fontFamily: AppType.text, fontSize: 24, height: 30 / 24, fontWeight: FontWeight.w500, color: c.textPrimary)),
            const SizedBox(height: 16),
            _identity(c),
            SlGroupLabel('My account'.tr),
            SlLedger(children: [
              SlIconRow(
                icon: _users,
                title: 'Business centre'.tr,
                meta: 'Your customers and what they owe'.tr,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomersScreen())),
              ),
              rule(),
              SlIconRow(
                icon: _bell,
                title: 'Notifications'.tr,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
              ),
              rule(),
              SlIconRow(
                icon: _globe,
                title: 'Language'.tr,
                end: Text(ApiService.languages[ApiService.locale] ?? '', style: AppType.caption.copyWith(color: c.textSecondary)),
                onTap: _showLanguagePicker,
              ),
            ]),
            SlGroupLabel('General'.tr),
            SlLedger(children: [
              if (_biometricAvailable) ...[
                SlIconRow(
                  icon: _fingerprint,
                  title: 'Biometric login'.tr,
                  end: SlSwitch(value: _biometricOn, label: 'Biometric login'.tr, onChanged: _toggleBiometric),
                ),
                rule(),
              ],
              SlIconRow(
                icon: _moon,
                title: 'Dark mode'.tr,
                end: SlSwitch(value: themeNotifier.isDark, label: 'Dark mode'.tr, onChanged: (v) => themeNotifier.toggle(v)),
              ),
            ]),
            const SizedBox(height: 20),
            // The design's danger pill.
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _showLogoutConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.dangerTint,
                  foregroundColor: c.dangerInk,
                  elevation: 0,
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(fontFamily: AppType.text, fontSize: 17, fontWeight: FontWeight.w700),
                ),
                child: Text('Log out'.tr),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The avatar, name, role and farm, and Edit (the design's sl-ent).
  Widget _identity(AppColors c) {
    final line = [_roleLabel, _farmName].whereType<String>().where((s) => s.isNotEmpty).join(' · ');
    return SlCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(color: c.brandSoft, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(_getInitials(_userName),
              style: TextStyle(fontFamily: AppType.text, fontSize: 19, fontWeight: FontWeight.w700, color: c.brandText)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_userName.isEmpty ? 'Your name'.tr : _userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontFamily: AppType.text, fontSize: 15, height: 20 / 15, fontWeight: FontWeight.w700, color: c.textPrimary)),
            const SizedBox(height: 2),
            Text(line.isNotEmpty ? line : (_userPhone.isNotEmpty ? _userPhone : _userEmail),
                maxLines: 2, overflow: TextOverflow.ellipsis, style: AppType.caption.copyWith(color: c.textSecondary)),
          ]),
        ),
        const SizedBox(width: 12),
        OutlinedButton(
          onPressed: _openEdit,
          style: OutlinedButton.styleFrom(
            foregroundColor: c.brandText,
            side: BorderSide(color: c.brandText, width: 1.5),
            shape: const StadiumBorder(),
            minimumSize: const Size(64, 44),
            textStyle: const TextStyle(fontFamily: AppType.text, fontSize: 15, fontWeight: FontWeight.w700),
          ),
          child: Text('Edit'.tr),
        ),
      ]),
    );
  }

  Future<void> _openEdit() async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(name: _userName, email: _userEmail, phone: _userPhone, username: _username),
      ),
    );
    if (updated != null && mounted) {
      setState(() {
        _userName = updated['name'];
        _userEmail = updated['email'];
        _userPhone = updated['phone'];
        _username = updated['username'];
      });
    }
  }

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

import 'package:flutter/material.dart';
import '../../services/app_colors.dart';
import 'package:flutter/services.dart';
import '../../services/app_type.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/ledger.dart';
import '../../widgets/ledger_parts.dart';
import '../auth/auth_service.dart';
import '../farm/my_farm_screen.dart';
import '../home_service.dart';
import 'my_photo.dart';
import 'web_page_screen.dart';
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
        'owner' => 'Farm administrator'.tr,
        'manager' => 'Farm manager'.tr,
        'field_worker' => 'Field worker'.tr,
        _ => null,
      };

  // The design's line icons (Lucide, ISC licence).
  static const _farmIcon = '<path d="M14 9.536V7a4 4 0 0 1 4-4h1.5a.5.5 0 0 1 .5.5V5a4 4 0 0 1-4 4 4 4 0 0 0-4 4c0 2 1 3 1 5a5 5 0 0 1-1 3"/><path d="M4 9a5 5 0 0 1 8 4 5 5 0 0 1-8-4"/><path d="M5 21h14"/>';
  static const _bell = '<path d="M10.268 21a2 2 0 0 0 3.464 0"/><path d="M3.262 15.326A1 1 0 0 0 4 17h16a1 1 0 0 0 .74-1.673C19.41 13.956 18 12.499 18 8A6 6 0 0 0 6 8c0 4.499-1.411 5.956-2.738 7.326"/>';
  static const _globe = '<circle cx="12" cy="12" r="10"/><path d="M12 2a14.5 14.5 0 0 0 0 20 14.5 14.5 0 0 0 0-20"/><path d="M2 12h20"/>';
  static const _fingerprint = '<path d="M12 10a2 2 0 0 0-2 2c0 1.02-.1 2.51-.26 4"/><path d="M14 13.12c0 2.38 0 6.38-1 8.88"/><path d="M17.29 21.02c.12-.6.43-2.3.5-3.02"/><path d="M2 12a10 10 0 0 1 18-6"/><path d="M2 16h.01"/><path d="M21.8 16c.2-2 .131-5.354 0-6"/><path d="M5 19.5C5.5 18 6 15 6 12a6 6 0 0 1 .34-2"/><path d="M8.65 22c.21-.66.45-1.32.57-2"/><path d="M9 6.8a6 6 0 0 1 9 5.2v2"/>';
  static const _wallet = '<path d="M19 7V4a1 1 0 0 0-1-1H5a2 2 0 0 0 0 4h15a1 1 0 0 1 1 1v4h-3a2 2 0 0 0 0 4h3a1 1 0 0 0 1-1v-2a1 1 0 0 0-1-1"/><path d="M3 5v14a2 2 0 0 0 2 2h15a1 1 0 0 0 1-1v-4"/>';
  static const _shield = '<path d="M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z"/>';
  static const _file = '<path d="M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z"/><path d="M14 2v4a2 2 0 0 0 2 2h4"/><path d="M10 9H8"/><path d="M16 13H8"/><path d="M16 17H8"/>';
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
            const SizedBox(height: 12),
            _identity(c),
            SlGroupLabel('My account'.tr),
            SlLedger(children: [
              SlIconRow(
                icon: _farmIcon,
                title: 'My farm'.tr,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyFarmScreen())),
              ),
              rule(),
              SlIconRow(icon: _wallet, title: 'Payment method'.tr, onTap: _showPaymentMethods),
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
              SlIconRow(
                icon: _fingerprint,
                title: 'Biometric login'.tr,
                // Off and greyed on a phone without a fingerprint or face sensor.
                end: SlSwitch(value: _biometricOn, label: 'Biometric login'.tr, onChanged: _biometricAvailable ? _toggleBiometric : null),
              ),
              rule(),
              SlIconRow(
                icon: _moon,
                title: 'Dark mode'.tr,
                end: SlSwitch(value: themeNotifier.isDark, label: 'Dark mode'.tr, onChanged: (v) => themeNotifier.toggle(v)),
              ),
              rule(),
              SlIconRow(icon: _shield, title: 'Privacy policy'.tr, onTap: () => _openPage('Privacy policy'.tr, '$siteUrl/privacy')),
              rule(),
              SlIconRow(icon: _file, title: 'Terms of service'.tr, onTap: () => _openPage('Terms of service'.tr, '$siteUrl/terms')),
            ]),
            const SizedBox(height: 20),
            // The design's danger button: white, with a red rule and red words.
            SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: _showLogoutConfirm,
                style: OutlinedButton.styleFrom(
                  backgroundColor: c.cardBackground,
                  foregroundColor: c.dangerInk,
                  side: BorderSide(color: c.dangerInk, width: 1.5),
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(fontFamily: AppType.text, fontSize: 16, height: 20 / 16, fontWeight: FontWeight.w700),
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
        MyAvatar(initials: _getInitials(_userName), size: 56),
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
          // The design's secondary button.
          style: OutlinedButton.styleFrom(
            backgroundColor: c.cardBackground,
            foregroundColor: c.textPrimary,
            side: BorderSide(color: c.border, width: 1.5),
            shape: const StadiumBorder(),
            minimumSize: const Size(0, 52),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            textStyle: const TextStyle(fontFamily: AppType.text, fontSize: 16, height: 20 / 16, fontWeight: FontWeight.w700),
          ),
          child: Text('Edit'.tr),
        ),
      ]),
    );
  }

  void _openPage(String title, String url) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => WebPageScreen(title: title, url: url)));

  /// The ways a sale can be paid for, as the app records them.
  void _showPaymentMethods() {
    final c = context.appColors;
    const phone = '<rect width="14" height="20" x="5" y="2" rx="2" ry="2"/><path d="M12 18h.01"/>';
    const hash = '<path d="M4 9h16"/><path d="M4 15h16"/><path d="M10 3 8 21"/><path d="M16 3l-2 18"/>';
    const cash = '<rect width="20" height="12" x="2" y="6" rx="2"/><circle cx="12" cy="12" r="2"/><path d="M6 12h.01M18 12h.01"/>';
    const book = '<path d="M4 19.5v-15A2.5 2.5 0 0 1 6.5 2H19a1 1 0 0 1 1 1v18a1 1 0 0 1-1 1H6.5a1 1 0 0 1 0-5H20"/>';
    showModalBottomSheet(
      context: context,
      backgroundColor: c.scaffoldBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Payment method'.tr,
                style: TextStyle(fontFamily: AppType.text, fontSize: 19, height: 24 / 19, fontWeight: FontWeight.w500, color: c.textPrimary)),
            const SizedBox(height: 4),
            Text('How customers can pay you when you record a sale.'.tr, style: AppType.caption.copyWith(color: c.textSecondary)),
            const SizedBox(height: 14),
            SlLedger(children: [
              SlIconRow(icon: phone, title: 'M-Pesa prompt'.tr, meta: 'The customer gets a prompt on their phone to pay'.tr),
              Divider(height: 1, thickness: 1, color: c.divider),
              SlIconRow(icon: hash, title: 'M-Pesa code'.tr, meta: 'You type the code from their M-Pesa message'.tr),
              Divider(height: 1, thickness: 1, color: c.divider),
              SlIconRow(icon: cash, title: 'Cash'.tr),
              Divider(height: 1, thickness: 1, color: c.divider),
              SlIconRow(icon: book, title: 'On credit'.tr, meta: 'They pay later; it shows in what customers owe you'.tr),
            ]),
          ]),
        ),
      ),
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

import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/app_colors.dart';
import '../../services/app_type.dart';
import '../auth/auth_service.dart';
import '../auth/countries.dart';
import '../onboarding/welcome_screens.dart';
import 'edit_profile_screen.dart';
import 'profile_service.dart';
import '../../l10n/tr.dart';

/// A profile is complete with a name, a real email and a phone number.
/// (Accounts made before email was asked for carry an @shambos.com stand-in.)
bool isProfileComplete(Map? user) {
  if (user == null) return false;
  final name = '${user['name'] ?? ''}'.trim();
  final email = '${user['email'] ?? ''}'.trim();
  final phone = '${user['phone'] ?? ''}'.trim();
  return name.isNotEmpty && email.isNotEmpty && !email.endsWith('@shambos.com') && phone.isNotEmpty;
}

bool _open = false;

/// Shows "Complete your profile" over everything until the profile is complete.
/// It can't be dismissed: the only ways out are saving or signing out. True once
/// the profile is complete; false after signing out, or when it is already
/// showing (whoever opened it carries on from there).
Future<bool> ensureProfileComplete(NavigatorState navigator) async {
  if (_open) return false;
  _open = true;
  try {
    final res = await ProfileService.getProfile();
    Map? user;
    if (!res.error && res.data is Map) {
      user = res.data as Map;
      await ApiService.setUser(Map<String, dynamic>.from(user));
    } else {
      user = await ApiService.getUser(); // offline: go by what we have
      if (user == null) return false;
    }
    if (isProfileComplete(user)) return true;
    if (!navigator.mounted) return false;

    final saved = await showModalBottomSheet<bool>(
      context: navigator.context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      useSafeArea: true,
      backgroundColor: navigator.context.appColors.scaffoldBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => PopScope(canPop: false, child: _CompleteProfileSheet(user: user!)),
    );
    return saved == true;
  } finally {
    _open = false;
  }
}

class _CompleteProfileSheet extends StatefulWidget {
  final Map user;
  const _CompleteProfileSheet({required this.user});

  @override
  State<_CompleteProfileSheet> createState() => _CompleteProfileSheetState();
}

class _CompleteProfileSheetState extends State<_CompleteProfileSheet> {
  late final String _savedPhone = '${widget.user['phone'] ?? ''}';
  late Country _country = _savedPhone.isEmpty ? countries.first : splitPhone(_savedPhone).$1;
  late final _name = TextEditingController(text: '${widget.user['name'] ?? ''}'.trim());
  late final _email = TextEditingController(text: _realEmail('${widget.user['email'] ?? ''}'));
  late final _phone = TextEditingController(text: _savedPhone.isEmpty ? '' : splitPhone(_savedPhone).$2);

  bool _saving = false;
  String? _error;
  Map<String, String> _fieldErrors = {};

  static String _realEmail(String email) => email.trim().endsWith('@shambos.com') ? '' : email.trim();

  @override
  void initState() {
    super.initState();
    if (_savedPhone.isEmpty) initialCountry().then((c) { if (mounted) setState(() => _country = c); });
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickCountry() async {
    final picked = await showCountryPicker(context, _country);
    if (picked != null && mounted) setState(() => _country = picked);
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final name = _name.text.trim();
    final email = _email.text.trim();
    final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
    final errors = {
      if (name.isEmpty) 'name': 'Enter your name.'.tr,
      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email) || email.endsWith('@shambos.com'))
        'email': 'Enter a valid email address.'.tr,
      if (digits.length < 6) 'phone': 'Enter your phone number.'.tr,
    };
    if (errors.isNotEmpty) return setState(() { _fieldErrors = errors; _error = null; });

    setState(() { _saving = true; _error = null; _fieldErrors = {}; });
    final res = await ProfileService.updateProfile(
      name: name,
      email: email,
      phone: _country.e164(digits),
      username: '${widget.user['username'] ?? ''}',
    );
    if (!mounted) return;
    if (!res.error && isProfileComplete(res.data is Map ? res.data as Map : null)) {
      Navigator.pop(context, true);
      return;
    }
    final fields = <String, String>{};
    final raw = res.data is Map ? res.data['fields'] : null;
    if (raw is Map) raw.forEach((k, v) => fields['$k'] = v is List && v.isNotEmpty ? '${v.first}' : '$v');
    setState(() {
      _saving = false;
      _fieldErrors = fields;
      _error = fields.isEmpty ? (res.message ?? 'Could not save. Check your connection and try again.'.tr) : null;
    });
  }

  Future<void> _signOut() async {
    final navigator = Navigator.of(context);
    await AuthService.logout();
    navigator.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const WelcomeScreens()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Complete your profile'.tr,
              style: TextStyle(fontFamily: AppType.text, fontSize: 24, height: 30 / 24, fontWeight: FontWeight.w500, color: c.textPrimary)),
          const SizedBox(height: 6),
          Text('Add your name, email and phone number to start using Shamba OS.'.tr,
              style: AppType.body.copyWith(color: c.textSecondary)),
          const SizedBox(height: 20),
          ProfileField(
            label: 'Full name'.tr,
            required: true,
            controller: _name,
            caps: TextCapitalization.words,
            error: _fieldErrors['name'],
          ),
          const SizedBox(height: 18),
          ProfileField(
            label: 'Email'.tr,
            required: true,
            controller: _email,
            keyboard: TextInputType.emailAddress,
            error: _fieldErrors['email'],
          ),
          const SizedBox(height: 18),
          ProfileField(
            label: 'Phone number'.tr,
            required: true,
            controller: _phone,
            prefix: _country.dialLabel,
            onPrefixTap: _pickCountry,
            keyboard: TextInputType.phone,
            mono: true,
            error: _fieldErrors['phone'],
          ),
          const SizedBox(height: 20),
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: c.dangerTint, borderRadius: BorderRadius.circular(16)),
              child: Text(_error!, style: AppType.body.copyWith(color: c.dangerInk)),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: c.shamba,
                foregroundColor: c.onShamba,
                disabledBackgroundColor: c.shamba.withValues(alpha: 0.45),
                disabledForegroundColor: c.onShamba,
                elevation: 0,
                shape: const StadiumBorder(),
                textStyle: const TextStyle(fontFamily: AppType.text, fontSize: 17, fontWeight: FontWeight.w700),
              ),
              child: _saving
                  ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: c.onShamba))
                  : Text('Save and continue'.tr),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _saving ? null : _signOut,
              style: TextButton.styleFrom(minimumSize: const Size(0, 40)),
              child: Text('Log out'.tr,
                  style: TextStyle(fontFamily: AppType.text, fontSize: 14, fontWeight: FontWeight.w700, color: c.textSecondary)),
            ),
          ),
        ]),
      ),
    );
  }
}

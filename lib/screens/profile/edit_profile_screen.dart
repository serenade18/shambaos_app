import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/api_service.dart';
import '../../services/app_colors.dart';
import '../../services/app_type.dart';
import '../../widgets/ledger.dart';
import '../../widgets/ledger_parts.dart';
import '../../widgets/phosphor_icons.dart';
import '../auth/auth_ui.dart';
import '../auth/countries.dart';
import 'my_photo.dart';
import 'profile_service.dart';
import '../../l10n/tr.dart';

/// The design's Edit profile: the profile photo with a camera button, then
/// name, phone, email and the username (which can't change), and Save changes.
/// A new photo is sent as soon as it is chosen (POST /me/photo); the rest on Save
/// (PATCH /me). Closes with the saved {name, email, phone, username}.
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
  late final _name = TextEditingController(text: widget.name);
  late Country _country = splitPhone(widget.phone).$1;
  late final _phone = TextEditingController(text: _local(widget.phone));
  late final _email = TextEditingController(text: widget.email);
  late String _username = widget.username;
  late final _usernameField = TextEditingController(text: widget.username);

  bool _saving = false;
  bool _photoBusy = false;
  String? _error;
  Map<String, String> _fieldErrors = {};

  static const _camera = '<path d="M14.5 4h-5L7 7H4a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V9a2 2 0 0 0-2-2h-3l-2.5-3z"/><circle cx="12" cy="13" r="3"/>';
  static const _image = '<rect width="18" height="18" x="3" y="3" rx="2" ry="2"/><circle cx="9" cy="9" r="2"/><path d="m21 15-3.086-3.086a2 2 0 0 0-2.828 0L6 21"/>';
  static const _trash = '<path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/>';
  static const _lock = '<rect width="18" height="11" x="3" y="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/>';

  @override
  void initState() {
    super.initState();
    MyPhoto.ensure();
    _fetch();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _usernameField.dispose();
    super.dispose();
  }

  /// +254712345678 → 712 345 678, as the field shows it after its country code.
  static String _local(String phone) {
    var digits = splitPhone(phone).$2;
    if (digits.startsWith('0')) digits = digits.substring(1);
    if (digits.length != 9) return digits;
    return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
  }

  Future<void> _pickCountry() async {
    final picked = await showCountryPicker(context, _country);
    if (picked != null && mounted) setState(() => _country = picked);
  }

  Future<void> _fetch() async {
    final res = await ProfileService.getProfile();
    if (res.error || res.data is! Map || !mounted) return;
    final d = res.data as Map;
    setState(() {
      _name.text = '${d['name'] ?? _name.text}';
      final phone = '${d['phone'] ?? ''}';
      if (phone.isNotEmpty) _country = splitPhone(phone).$1;
      _phone.text = _local(phone);
      _email.text = '${d['email'] ?? ''}';
      _username = '${d['username'] ?? _username}';
      _usernameField.text = _username;
    });
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final name = _name.text.trim();
    final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
    if (name.isEmpty) return setState(() => _fieldErrors = {'name': 'Enter your name.'.tr});
    if (digits.isEmpty) return setState(() => _fieldErrors = {'phone': 'Enter your phone number.'.tr});
    setState(() {
      _saving = true;
      _error = null;
      _fieldErrors = {};
    });
    final phone = _country.e164(digits);
    final res = await ProfileService.updateProfile(name: name, email: _email.text.trim(), phone: phone, username: _username);
    if (!mounted) return;
    if (!res.error) {
      final d = res.data is Map ? res.data as Map : const {};
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Your profile is saved.'.tr)));
      Navigator.pop(context, {
        'name': '${d['name'] ?? name}',
        'email': '${d['email'] ?? ''}',
        'phone': '${d['phone'] ?? phone}',
        'username': '${d['username'] ?? _username}',
      });
      return;
    }
    final fields = <String, String>{};
    final raw = res.data is Map ? res.data['fields'] : null;
    if (raw is Map) {
      raw.forEach((k, v) => fields['$k'] = v is List && v.isNotEmpty ? '${v.first}' : '$v');
    }
    setState(() {
      _saving = false;
      _fieldErrors = fields;
      _error = fields.isEmpty ? (res.message ?? 'Could not save. Check your connection and try again.'.tr) : null;
    });
  }

  // ── The photo ──────────────────────────────────────────────
  Future<void> _photoSheet() async {
    final c = context.appColors;
    final has = MyPhoto.bytes.value != null;
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: c.scaffoldBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(
              child: Container(width: 40, height: 5, decoration: BoxDecoration(color: c.divider, borderRadius: BorderRadius.circular(999))),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text('Profile photo'.tr,
                  style: TextStyle(fontFamily: AppType.text, fontSize: 19, height: 24 / 19, fontWeight: FontWeight.w500, color: c.textPrimary)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 2, 4, 10),
              child: Text('JPG or PNG, up to 5 MB. We crop it to a circle.'.tr, style: AppType.caption.copyWith(color: c.textSecondary)),
            ),
            SlLedger(children: [
              SlIconRow(icon: _camera, title: 'Take a photo'.tr, end: const SizedBox.shrink(), onTap: () => Navigator.pop(sheet, 'camera')),
              Divider(height: 1, thickness: 1, color: c.divider),
              SlIconRow(icon: _image, title: 'Choose from gallery'.tr, end: const SizedBox.shrink(), onTap: () => Navigator.pop(sheet, 'gallery')),
              if (has) ...[
                Divider(height: 1, thickness: 1, color: c.divider),
                SlIconRow(
                    icon: _trash, tone: SlTone.danger, title: 'Remove photo'.tr, end: const SizedBox.shrink(), onTap: () => Navigator.pop(sheet, 'remove')),
              ],
            ]),
            const SizedBox(height: 12),
            SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(sheet),
                style: OutlinedButton.styleFrom(
                  backgroundColor: c.cardBackground,
                  foregroundColor: c.textPrimary,
                  side: BorderSide(color: c.border, width: 1.5),
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(fontFamily: AppType.text, fontSize: 16, fontWeight: FontWeight.w700),
                ),
                child: Text('Cancel'.tr),
              ),
            ),
          ]),
        ),
      ),
    );
    if (choice == null || !mounted) return;
    if (choice == 'remove') return _run(MyPhoto.remove, 'Photo removed.'.tr);

    final XFile? picked;
    try {
      picked = await ImagePicker().pickImage(
        source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
    } on PlatformException {
      if (mounted) _say('Allow Shamba OS to use the camera and photos in your phone settings.'.tr);
      return;
    }
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    await _run(() => MyPhoto.upload(bytes, picked!.name.isEmpty ? 'photo.jpg' : picked.name), 'Your new photo is saved.'.tr);
  }

  Future<void> _run(Future<ApiResponse> Function() send, String done) async {
    setState(() => _photoBusy = true);
    final res = await send();
    if (!mounted) return;
    setState(() => _photoBusy = false);
    _say(res.error ? (res.message ?? 'Could not change your photo. Try again.'.tr) : done);
  }

  void _say(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  // ── The page ───────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: c.scaffoldBackground,
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Row(children: [
              Semantics(
                button: true,
                label: 'Back'.tr,
                excludeSemantics: true,
                child: Container(
                  decoration: BoxDecoration(
                    color: c.cardBackground,
                    shape: BoxShape.circle,
                    boxShadow: const [BoxShadow(color: Color(0x1217211A), blurRadius: 24, offset: Offset(0, 8))],
                  ),
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.maybePop(context),
                      child: SizedBox(width: 44, height: 44, child: Icon(PhosphorIconsRegular.arrowLeft, size: 22, color: c.textPrimary)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Edit profile'.tr,
                    style: TextStyle(fontFamily: AppType.text, fontSize: 24, height: 30 / 24, fontWeight: FontWeight.w500, color: c.textPrimary)),
              ),
            ]),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                _photo(c),
                const SizedBox(height: 18),
                ProfileField(
                  label: 'Full name'.tr,
                  required: true,
                  controller: _name,
                  caps: TextCapitalization.words,
                  error: _fieldErrors['name'],
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
                  hint: _country.signsInBySms ? 'You sign in with a code sent to this number'.tr : null,
                  error: _fieldErrors['phone'],
                ),
                const SizedBox(height: 18),
                ProfileField(
                  label: 'Email'.tr,
                  optional: true,
                  controller: _email,
                  keyboard: TextInputType.emailAddress,
                  error: _fieldErrors['email'],
                ),
                if (_username.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  ProfileField(
                    label: 'Username'.tr,
                    controller: _usernameField,
                    readOnly: true,
                    trailing: LineIcon(_lock, size: 18, color: c.textSecondary),
                    hint: "Your username can't be changed".tr,
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 16 + bottom),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
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
                      : Text('Save changes'.tr),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  /// The photo, a camera button on its edge, Change photo and why it helps.
  Widget _photo(AppColors c) {
    final initials = _name.text.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).take(2).map((p) => p[0].toUpperCase()).join();
    return Column(children: [
      const SizedBox(height: 8),
      SizedBox(
        width: 120,
        height: 120,
        child: Stack(clipBehavior: Clip.none, children: [
          Container(
            width: 112,
            height: 112,
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: c.cardBackground, width: 3),
              boxShadow: const [BoxShadow(color: Color(0x1217211A), blurRadius: 24, offset: Offset(0, 8))],
            ),
            child: Stack(fit: StackFit.expand, children: [
              MyAvatar(initials: initials.isEmpty ? 'U' : initials, size: 106),
              if (_photoBusy)
                ClipOval(
                  child: ColoredBox(
                    color: const Color(0x7317211A),
                    child: Center(child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3, color: c.onShamba))),
                  ),
                ),
            ]),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Semantics(
              button: true,
              label: 'Change profile photo'.tr,
              excludeSemantics: true,
              child: Material(
                color: c.shamba,
                shape: CircleBorder(side: BorderSide(color: c.scaffoldBackground, width: 3)),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _photoBusy ? null : _photoSheet,
                  child: SizedBox(width: 44, height: 44, child: Center(child: LineIcon(_camera, size: 20, color: c.onShamba))),
                ),
              ),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 6),
      TextButton(
        onPressed: _photoBusy ? null : _photoSheet,
        style: TextButton.styleFrom(minimumSize: const Size(0, 32)),
        child: Text('Change photo'.tr,
            style: TextStyle(fontFamily: AppType.text, fontSize: 14, fontWeight: FontWeight.w700, color: c.brandText)),
      ),
      Text("A clear photo of your face helps your team know it's you".tr,
          textAlign: TextAlign.center, style: AppType.caption.copyWith(color: c.textSecondary)),
    ]);
  }
}

/// A labelled field as the design draws it (sl-field): the label above, a
/// 56-high box with an optional prefix (the country code, tappable to change
/// it), and a hint or error under it.
class ProfileField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool required;
  final bool optional;
  final bool readOnly;
  final bool mono;
  final String? prefix;
  final VoidCallback? onPrefixTap;
  final Widget? trailing;
  final String? hint;
  final String? error;
  final TextInputType? keyboard;
  final TextCapitalization caps;

  const ProfileField({
    super.key,
    required this.label,
    required this.controller,
    this.required = false,
    this.optional = false,
    this.readOnly = false,
    this.mono = false,
    this.prefix,
    this.onPrefixTap,
    this.trailing,
    this.hint,
    this.error,
    this.keyboard,
    this.caps = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final note = error ?? hint;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text.rich(TextSpan(children: [
        TextSpan(text: label),
        if (required) TextSpan(text: ' *', style: TextStyle(color: c.dangerInk)),
        if (optional) TextSpan(text: ' ${'(optional)'.tr}', style: TextStyle(fontWeight: FontWeight.w400, color: c.textSecondary)),
      ]), style: TextStyle(fontFamily: AppType.text, fontSize: 15, height: 20 / 15, fontWeight: FontWeight.w700, color: c.textPrimary)),
      const SizedBox(height: 6),
      Container(
        height: 56,
        decoration: BoxDecoration(
          color: readOnly ? c.surfaceMuted : c.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: error != null ? c.dangerInk : c.border, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (prefix != null)
            Semantics(
              button: onPrefixTap != null,
              label: onPrefixTap != null ? 'Country code {code}. Change country'.trArgs({'code': prefix}) : null,
              child: GestureDetector(
                onTap: onPrefixTap,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: c.surfaceMuted, border: Border(right: BorderSide(color: c.divider))),
                  child: ExcludeSemantics(
                    child: Text(prefix!, style: TextStyle(fontFamily: AppType.mono, fontSize: 17, fontWeight: FontWeight.w500, color: c.textPrimary)),
                  ),
                ),
              ),
            ),
          Expanded(
            child: Center(
              child: TextField(
                controller: controller,
                readOnly: readOnly,
                keyboardType: keyboard,
                textCapitalization: caps,
                style: mono
                    ? TextStyle(fontFamily: AppType.mono, fontSize: 19, fontWeight: FontWeight.w500, letterSpacing: 0.76, color: c.textPrimary)
                    : TextStyle(fontFamily: AppType.text, fontSize: 17, color: readOnly ? c.textSecondary : c.textPrimary),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14),
                ),
              ),
            ),
          ),
          if (trailing != null) Padding(padding: const EdgeInsets.only(right: 14), child: Center(child: trailing)),
        ]),
      ),
      if (note != null) ...[
        const SizedBox(height: 6),
        Text(note, style: AppType.caption.copyWith(color: error != null ? c.dangerInk : c.textSecondary)),
      ],
    ]);
  }
}

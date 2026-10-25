import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/app_theme.dart';
import 'auth_service.dart';
import 'auth_ui.dart';
import 'countries.dart';
import '../../l10n/tr.dart';

/// Sign-up outside Kenya: name, email, username, phone and password, as on the
/// web portal. The account starts when the link emailed to it is opened; they
/// then sign in with their username or email and password.
class SignUpScreen extends StatefulWidget {
  final Country country;
  const SignUpScreen({super.key, required this.country});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  static const _fields = ['name', 'email', 'username', 'phone', 'password'];

  late Country _country = widget.country;
  final _ctrl = {for (final f in _fields) f: TextEditingController()};
  final _focus = {for (final f in _fields) f: FocusNode()};

  bool _busy = false;
  Map<String, String> _errors = {};
  String? _formError;
  String? _sentTo; // the email the link went to, once signed up

  @override
  void initState() {
    super.initState();
    for (final f in _focus.values) {
      f.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in _ctrl.values) {
      c.dispose();
    }
    for (final f in _focus.values) {
      f.dispose();
    }
    super.dispose();
  }

  String _text(String field) => _ctrl[field]!.text.trim();

  void _clearError(String field) {
    if (_errors.containsKey(field) || _formError != null) {
      setState(() { _errors = {..._errors}..remove(field); _formError = null; });
    }
  }

  Future<void> _pickCountry() async {
    final picked = await showCountryPicker(context, _country);
    if (picked != null && mounted) setState(() => _country = picked);
  }

  Map<String, String> _checkLocally() => {
        if (_text('name').isEmpty) 'name': 'Enter your name.'.tr,
        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_text('email'))) 'email': 'Enter a valid email address.'.tr,
        if (!RegExp(r'^[A-Za-z0-9._]{3,30}$').hasMatch(_text('username'))) 'username': 'Use 3 to 30 letters, numbers, dots or underscores.'.tr,
        if (_text('phone').replaceAll(RegExp(r'\D'), '').length < 6) 'phone': 'Enter your phone number.'.tr,
        if (_ctrl['password']!.text.length < 8) 'password': 'Use at least 8 characters.'.tr,
      };

  Future<void> _submit() async {
    final errors = _checkLocally();
    if (errors.isNotEmpty) {
      setState(() { _errors = errors; _formError = null; });
      _focus[_fields.firstWhere(errors.containsKey)]!.requestFocus();
      return;
    }

    setState(() { _busy = true; _errors = {}; _formError = null; });
    final res = await AuthService.register(
      name: _text('name'),
      email: _text('email'),
      username: _text('username'),
      phone: _country.e164(_text('phone')),
      password: _ctrl['password']!.text,
    );
    if (!mounted) return;
    setState(() => _busy = false);

    if (!res.error) {
      setState(() => _sentTo = res.data is Map ? (res.data['email'] ?? _text('email')).toString() : _text('email'));
      return;
    }
    // Each problem shows under its field; anything else under the button.
    final fields = res.data is Map && res.data['fields'] is Map ? res.data['fields'] as Map : const {};
    setState(() {
      _errors = {
        for (final e in fields.entries)
          if (_fields.contains(e.key) && e.value is List && (e.value as List).isNotEmpty) e.key.toString(): (e.value as List).first.toString(),
      };
      if (_errors.isEmpty) _formError = res.message ?? "Couldn't create your account. Try again.".tr;
    });
  }

  Widget _textField(String field, String label, {
    String? hint,
    String? help,
    TextInputType? keyboard,
    Iterable<String>? autofill,
    TextCapitalization caps = TextCapitalization.none,
  }) =>
      LedgerField(
        label: label,
        focused: _focus[field]!.hasFocus,
        error: _errors[field],
        hint: help,
        input: TextField(
          controller: _ctrl[field],
          focusNode: _focus[field],
          keyboardType: keyboard,
          autofillHints: autofill,
          textCapitalization: caps,
          autocorrect: false,
          textInputAction: TextInputAction.next,
          onChanged: (_) => _clearError(field),
          style: Ledger.input,
          cursorColor: Ledger.shamba,
          decoration: Ledger.bare(hint ?? ''),
        ),
      );

  @override
  Widget build(BuildContext context) =>
      Theme(data: AppTheme.light(), child: Builder(builder: _buildScreen));

  Widget _buildScreen(BuildContext context) => Scaffold(
        backgroundColor: Ledger.paper,
        body: SafeArea(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Align(alignment: Alignment.centerLeft, child: _BackButton(onTap: () => Navigator.pop(context))),
            ),
            Expanded(child: _sentTo != null ? _checkEmail() : _form()),
          ]),
        ),
      );

  Widget _form() => AutofillGroup(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('KARIBU · WELCOME'.tr, style: Ledger.eyebrow),
            const SizedBox(height: 6),
            Text('Create your account'.tr, style: Ledger.title),
            const SizedBox(height: 6),
            Text("We'll email you a link to start your account.".tr, style: Ledger.body),
            const SizedBox(height: 20),

            _textField('name', 'Full name'.tr, autofill: const [AutofillHints.name], caps: TextCapitalization.words),
            const SizedBox(height: 16),
            _textField('email', 'Email'.tr, hint: 'you@example.com', keyboard: TextInputType.emailAddress, autofill: const [AutofillHints.email]),
            const SizedBox(height: 16),
            _textField('username', 'Username'.tr,
                help: 'Use 3 to 30 letters, numbers, dots or underscores.'.tr, autofill: const [AutofillHints.newUsername]),
            const SizedBox(height: 16),
            LedgerField(
              label: 'Phone number'.tr,
              focused: _focus['phone']!.hasFocus,
              error: _errors['phone'],
              prefix: Semantics(
                button: true,
                label: 'Country code {code}. Change country'.trArgs({'code': _country.dialCode}),
                child: GestureDetector(
                  onTap: _pickCountry,
                  behavior: HitTestBehavior.opaque,
                  child: ExcludeSemantics(
                    child: Text(_country.dialLabel, style: Ledger.code.copyWith(fontSize: 17, letterSpacing: 0)),
                  ),
                ),
              ),
              input: TextField(
                controller: _ctrl['phone'],
                focusNode: _focus['phone'],
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumber],
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
                  LengthLimitingTextInputFormatter(18),
                ],
                textInputAction: TextInputAction.next,
                onChanged: (_) => _clearError('phone'),
                style: Ledger.code,
                cursorColor: Ledger.shamba,
                decoration: Ledger.bare('', style: Ledger.code),
              ),
            ),
            const SizedBox(height: 16),
            LedgerField(
              label: 'Password'.tr,
              focused: _focus['password']!.hasFocus,
              error: _errors['password'],
              hint: 'Use at least 8 characters.'.tr,
              input: PasswordInput(
                controller: _ctrl['password']!,
                focusNode: _focus['password']!,
                newPassword: true,
                onChanged: (_) => _clearError('password'),
                onSubmitted: (_) => _submit(),
              ),
            ),
            const SizedBox(height: 20),
            LedgerButton(label: 'Create account'.tr, busy: _busy, onPressed: _submit),
            if (_formError != null) ...[
              const SizedBox(height: 10),
              Text(_formError!, style: Ledger.caption.copyWith(color: Ledger.dangerInk)),
            ],
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(minimumSize: const Size(0, 32), foregroundColor: Ledger.shambaInk),
                child: Text('I already have an account'.tr, style: Ledger.link),
              ),
            ),
          ]),
        ),
      );

  Widget _checkEmail() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(color: Ledger.shambaTint, shape: BoxShape.circle),
              child: const Center(child: LineIcon(LineIcon.mail, size: 30, color: Ledger.shambaInk)),
            ),
          ),
          const SizedBox(height: 20),
          Text('Check your email'.tr, style: Ledger.title),
          const SizedBox(height: 6),
          Text(
            'We sent a link to {email}. Open it to start your account, then sign in here with your username or email and password.'
                .trArgs({'email': _sentTo}),
            style: Ledger.body.copyWith(fontSize: 17, height: 26 / 17),
          ),
          const Spacer(),
          LedgerButton(label: 'Back to sign in'.tr, onPressed: () => Navigator.pop(context, _text('username'))),
        ]),
      );
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'Back'.tr,
        child: Container(
          decoration: const BoxDecoration(color: Ledger.sheet, shape: BoxShape.circle, boxShadow: Ledger.shadowSoft),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: const SizedBox(width: 44, height: 44, child: Center(child: LineIcon(LineIcon.arrowLeft))),
            ),
          ),
        ),
      );
}

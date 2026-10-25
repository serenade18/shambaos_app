import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'auth_ui.dart';
import '../../l10n/tr.dart';

/// Asks for the account's email and has the API email a reset link. The reply
/// is the same whether or not an account uses the email.
Future<void> showForgotPassword(BuildContext context, {String email = ''}) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Ledger.sheet,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Ledger.radiusSheet))),
      builder: (_) => _ForgotPasswordSheet(email: email),
    );

class _ForgotPasswordSheet extends StatefulWidget {
  final String email;
  const _ForgotPasswordSheet({required this.email});

  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  late final _emailCtrl = TextEditingController(text: widget.email.contains('@') ? widget.email : '');
  final _emailFocus = FocusNode();
  bool _busy = false;
  bool _sent = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _emailCtrl.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => _error = 'Enter a valid email address.'.tr);
      return;
    }
    setState(() { _busy = true; _error = null; });
    final res = await AuthService.forgotPassword(email: email);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _sent = !res.error;
      if (res.error) _error = res.message ?? "Couldn't send the link. Try again.".tr;
    });
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
        child: SafeArea(
          top: false,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(
              child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Ledger.rule, borderRadius: BorderRadius.circular(999))),
            ),
            const SizedBox(height: 16),
            Text(_sent ? 'Check your email'.tr : 'Reset your password'.tr, style: Ledger.title.copyWith(fontSize: 19, height: 24 / 19)),
            const SizedBox(height: 6),
            Text(
              _sent
                  ? 'If an account uses {email}, we sent it a link to set a new password.'.trArgs({'email': _emailCtrl.text.trim()})
                  : "Enter your account's email and we'll send you a link to set a new password.".tr,
              style: Ledger.body,
            ),
            const SizedBox(height: 16),
            if (!_sent) ...[
              LedgerField(
                label: 'Email'.tr,
                focused: _emailFocus.hasFocus,
                error: _error,
                input: TextField(
                  controller: _emailCtrl,
                  focusNode: _emailFocus,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  autocorrect: false,
                  onChanged: (_) { if (_error != null) setState(() => _error = null); },
                  onSubmitted: (_) => _send(),
                  style: Ledger.input,
                  cursorColor: Ledger.shamba,
                  decoration: Ledger.bare('you@example.com'),
                ),
              ),
              const SizedBox(height: 16),
              LedgerButton(label: 'Send link'.tr, busy: _busy, onPressed: _send),
            ] else
              LedgerButton(label: 'Done'.tr, onPressed: () => Navigator.pop(context)),
          ]),
        ),
      );
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../screens/auth/auth_ui.dart';
import '../services/app_colors.dart';
import '../services/app_type.dart';
import 'ledger_parts.dart';
import 'phosphor_icons.dart';
import '../l10n/tr.dart';

/// The add forms as the canvas draws them (screens 28 onwards): a round back
/// button over an eyebrow and title, labelled fields (sl-field), and the
/// primary button fixed at the bottom (form-foot).
class SlFormPage extends StatelessWidget {
  final String eyebrow; // "ADD AN ANIMAL"
  final String title; // "Add a dairy cow"
  final List<Widget> children;
  final bool saving;
  final String? error;
  final String saveLabel;
  final VoidCallback? onSave;

  const SlFormPage({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.children,
    required this.saving,
    this.error,
    required this.saveLabel,
    required this.onSave,
  });

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
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(eyebrow, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.eyebrow.copyWith(color: c.textSecondary)),
                  const SizedBox(height: 2),
                  Text(title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: AppType.text, fontSize: 24, height: 30 / 24, fontWeight: FontWeight.w500, color: c.textPrimary)),
                ]),
              ),
            ]),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(height: 18), children[i]]],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 16 + bottom),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: c.dangerTint, borderRadius: BorderRadius.circular(16)),
                  child: Text(error!, style: AppType.body.copyWith(color: c.dangerInk)),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: saving ? null : onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.shamba,
                    foregroundColor: c.onShamba,
                    disabledBackgroundColor: c.shamba.withValues(alpha: 0.45),
                    disabledForegroundColor: c.onShamba,
                    elevation: 0,
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(fontFamily: AppType.text, fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  child: saving
                      ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: c.onShamba))
                      : Text(saveLabel),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// A labelled field (sl-field): the label with * when required or "(optional)",
/// what goes in it, and a hint or error under it.
class SlField extends StatelessWidget {
  final String label;
  final bool required;
  final bool optional;
  final Widget child;
  final String? hint;
  final String? error;
  final Widget? below; // a link under the field: "Add a building"

  const SlField({super.key, required this.label, this.required = false, this.optional = false, required this.child, this.hint, this.error, this.below});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final note = error ?? hint;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text.rich(
        TextSpan(children: [
          TextSpan(text: label),
          if (required) TextSpan(text: ' *', style: TextStyle(color: c.dangerInk)),
          if (optional) TextSpan(text: ' ${'(optional)'.tr}', style: TextStyle(fontWeight: FontWeight.w400, color: c.textSecondary)),
        ]),
        style: TextStyle(fontFamily: AppType.text, fontSize: 15, height: 20 / 15, fontWeight: FontWeight.w700, color: c.textPrimary),
      ),
      const SizedBox(height: 6),
      child,
      if (note != null) ...[
        const SizedBox(height: 6),
        Text(note, style: TextStyle(fontFamily: AppType.text, fontSize: 13, height: 18 / 13, color: error != null ? c.dangerInk : c.textSecondary)),
      ],
      if (below != null) Align(alignment: Alignment.centerLeft, child: below),
    ]);
  }
}

/// The 56-high box of a field (sl-field__box), with its border.
class _Box extends StatelessWidget {
  final Widget child;
  final bool error;
  const _Box({required this.child, this.error = false});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: c.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: error ? c.dangerInk : c.border, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

/// A text box: names in the text face, numbers and tags in the mono face, with a
/// "KSh" prefix or a unit suffix when it has one.
class SlTextBox extends StatelessWidget {
  final TextEditingController controller;
  final String? prefix;
  final String? suffix;
  final String? placeholder;
  final bool mono;
  final bool number;
  final bool error;
  final TextCapitalization caps;

  const SlTextBox({
    super.key,
    required this.controller,
    this.prefix,
    this.suffix,
    this.placeholder,
    this.mono = false,
    this.number = false,
    this.error = false,
    this.caps = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final face = mono || number
        ? TextStyle(fontFamily: AppType.mono, fontSize: 19, fontWeight: FontWeight.w500, letterSpacing: 0.76, color: c.textPrimary)
        : TextStyle(fontFamily: AppType.text, fontSize: 17, color: c.textPrimary);
    Widget side(String text, {required bool left}) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: c.surfaceMuted,
            border: left ? Border(right: BorderSide(color: c.divider)) : Border(left: BorderSide(color: c.divider)),
          ),
          child: Text(text,
              style: left
                  ? TextStyle(fontFamily: AppType.mono, fontSize: 17, fontWeight: FontWeight.w500, color: c.textPrimary)
                  : TextStyle(fontFamily: AppType.text, fontSize: 15, color: c.textSecondary)),
        );
    return _Box(
      error: error,
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (prefix != null) side(prefix!, left: true),
        Expanded(
          child: Center(
            child: TextField(
              controller: controller,
              textCapitalization: caps,
              keyboardType: number ? const TextInputType.numberWithOptions(decimal: true) : null,
              inputFormatters: number ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))] : null,
              style: face,
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: face.copyWith(color: c.textHint),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              ),
            ),
          ),
        ),
        if (suffix != null) side(suffix!, left: false),
      ]),
    );
  }
}

/// A box that opens a chooser: an icon, what is chosen, a chevron (fi-sel).
class SlSelectBox extends StatelessWidget {
  final String icon; // a LineIcon path
  final String text;
  final bool muted; // nothing chosen yet
  final VoidCallback onTap;
  final bool error;
  final Widget? trailing; // beside the chevron: the age as a tag

  const SlSelectBox(
      {super.key, required this.icon, required this.text, this.muted = false, required this.onTap, this.error = false, this.trailing});

  static const calendar = '<path d="M8 2v3"/><path d="M16 2v3"/><rect x="3" y="3" width="18" height="18" rx="2"/><path d="M3 9h18"/>';
  static const building =
      '<path d="M18 21V10a1 1 0 0 0-1-1H7a1 1 0 0 0-1 1v11"/><path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V8a2 2 0 0 1 1.132-1.803l7.95-3.974a2 2 0 0 1 1.837 0l7.948 3.974A2 2 0 0 1 22 8z"/><path d="M6 13h12"/><path d="M6 17h12"/>';

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Semantics(
      button: true,
      child: _Box(
        error: error,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(children: [
                LineIcon(icon, size: 22, color: c.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: AppType.text, fontSize: 17, color: muted ? c.textHint : c.textPrimary)),
                ),
                if (trailing != null) ...[trailing!, const SizedBox(width: 8)],
                LineIcon('<path d="m6 9 6 6 6-6"/>', size: 22, color: c.textSecondary),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// One choice from a few, as the design's chips.
class SlChoices<T> extends StatelessWidget {
  final List<(T, String)> options;
  final T? value;
  final ValueChanged<T> onChanged;
  const SlChoices({super.key, required this.options, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Wrap(spacing: 8, runSpacing: 8, children: [
        for (final (v, text) in options) SlChip(text, selected: v == value, onTap: () => onChanged(v)),
      ]);
}

/// What is being added, with its icon and a Change link (type-head).
class SlTypeHead extends StatelessWidget {
  final Widget icon;
  final String title;
  final String meta;
  final VoidCallback? onChange;
  const SlTypeHead({super.key, required this.icon, required this.title, required this.meta, this.onChange});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return SlCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: c.brandSoft, shape: BoxShape.circle),
          child: Center(child: icon),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontFamily: AppType.text, fontSize: 15, height: 20 / 15, fontWeight: FontWeight.w700, color: c.textPrimary)),
            const SizedBox(height: 2),
            Text(meta, style: TextStyle(fontFamily: AppType.text, fontSize: 13, height: 18 / 13, color: c.textSecondary)),
          ]),
        ),
        if (onChange != null) SlLink('Change'.tr, onChange!),
      ]),
    );
  }
}

/// A quiet link (sl-link): "Add a building", "Change".
class SlLink extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const SlLink(this.text, this.onTap, {super.key});

  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(minimumSize: const Size(0, 32), padding: const EdgeInsets.symmetric(horizontal: 4)),
        child: Text(text,
            style: TextStyle(fontFamily: AppType.text, fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w700, color: context.appColors.brandText)),
      );
}

/// A note in a sheet with an info icon (an sl-alert in a ledger).
class SlInfoNote extends StatelessWidget {
  final String text;
  const SlInfoNote(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return SlCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: c.rainTint, shape: BoxShape.circle),
          child: Center(child: LineIcon('<circle cx="12" cy="12" r="10"/><path d="M12 16v-4"/><path d="M12 8h.01"/>', size: 22, color: c.rainInk)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: TextStyle(fontFamily: AppType.text, fontSize: 14, height: 20 / 14, color: c.textPrimary))),
      ]),
    );
  }
}

/// Picks one of a list from a bottom sheet; null when dismissed.
Future<T?> slPick<T>(BuildContext context, {required String title, required List<(T, String)> options, T? value}) {
  final c = context.appColors;
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: c.cardBackground,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(title, style: TextStyle(fontFamily: AppType.text, fontSize: 19, height: 24 / 19, fontWeight: FontWeight.w500, color: c.textPrimary)),
          const SizedBox(height: 8),
          // A long list (a herd's cows) scrolls inside the sheet.
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(sheet).height * 0.6),
              child: ListView(shrinkWrap: true, children: [
                for (final (v, text) in options)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    title: Text(text, style: TextStyle(fontFamily: AppType.text, fontSize: 16, color: c.textPrimary)),
                    trailing: v == value ? Icon(Icons.check_rounded, color: c.brandText) : null,
                    onTap: () => Navigator.pop(sheet, v),
                  ),
              ]),
            ),
          ),
        ]),
      ),
    ),
  );
}

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
  final bool close; // an X on a filled circle, as screens 29–30, in place of the back arrow
  final String? saveIcon; // a LineIcon path before the Save label
  final double gap; // between children: 18 for fields, 12 for section cards

  const SlFormPage({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.children,
    required this.saving,
    this.error,
    required this.saveLabel,
    required this.onSave,
    this.close = false,
    this.saveIcon,
    this.gap = 18,
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
                label: close ? 'Close'.tr : 'Back'.tr,
                excludeSemantics: true,
                child: Container(
                  decoration: BoxDecoration(
                    color: close ? c.surfaceMuted : c.cardBackground,
                    shape: BoxShape.circle,
                    boxShadow: close ? null : const [BoxShadow(color: Color(0x1217211A), blurRadius: 24, offset: Offset(0, 8))],
                  ),
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.maybePop(context),
                      child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Icon(close ? PhosphorIconsRegular.x : PhosphorIconsRegular.arrowLeft, size: 22, color: c.textPrimary)),
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
              children: [for (var i = 0; i < children.length; i++) ...[if (i > 0) SizedBox(height: gap), children[i]]],
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
                      : Row(mainAxisSize: MainAxisSize.min, children: [
                          if (saveIcon != null) ...[LineIcon(saveIcon!, size: 20, color: c.onShamba), const SizedBox(width: 10)],
                          Flexible(child: Text(saveLabel, overflow: TextOverflow.ellipsis)),
                        ]),
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

// ═══════════════════════════════════════════════════════════
// SECTIONED FORMS (screens 29–30): each group of fields in its own card
// ═══════════════════════════════════════════════════════════

/// A group of fields in a card: an icon and a heading in capitals, a note on the
/// right ("Optional", "Auto-suggested"), then the fields.
class SlSection extends StatelessWidget {
  final String icon; // a LineIcon path
  final String title; // in capitals: "IDENTIFICATION & TAGS"
  final String? note;
  final bool noteGood; // the note in green, as "Auto-suggested"
  final List<Widget> children;
  const SlSection({super.key, required this.icon, required this.title, this.note, this.noteGood = false, required this.children});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return SlCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          LineIcon(icon, size: 18, color: c.brandText),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: AppType.eyebrow.copyWith(color: c.textPrimary))),
          if (note != null)
            Text(note!,
                style: TextStyle(
                    fontFamily: AppType.text,
                    fontSize: 12,
                    height: 16 / 12,
                    fontWeight: noteGood ? FontWeight.w700 : FontWeight.w400,
                    color: noteGood ? c.brandText : c.textSecondary)),
        ]),
        for (final w in children) ...[const SizedBox(height: 14), w],
      ]),
    );
  }
}

/// A filled box inside a section (no border): text, an icon in front, an action at the end.
class SlFilledBox extends StatelessWidget {
  final TextEditingController controller;
  final String? icon;
  final String? prefix; // "KSh"
  final String? placeholder;
  final bool mono;
  final bool number;
  final bool error;
  final TextCapitalization caps;
  final Widget? action; // "Next"
  final double? fontSize;
  const SlFilledBox({
    super.key,
    required this.controller,
    this.icon,
    this.prefix,
    this.placeholder,
    this.mono = false,
    this.number = false,
    this.error = false,
    this.caps = TextCapitalization.none,
    this.action,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final face = mono
        ? TextStyle(fontFamily: AppType.mono, fontSize: fontSize ?? 22, fontWeight: FontWeight.w500, letterSpacing: 1.3, color: c.textPrimary)
        : TextStyle(fontFamily: AppType.text, fontSize: fontSize ?? 17, color: c.textPrimary);
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: EdgeInsets.fromLTRB(14, 0, action == null ? 14 : 8, 0),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: error ? c.dangerInk : Colors.transparent, width: 1.5),
      ),
      child: Row(children: [
        if (icon != null) ...[LineIcon(icon!, size: 20, color: c.textSecondary), const SizedBox(width: 10)],
        if (prefix != null) ...[
          Text(prefix!, style: TextStyle(fontFamily: AppType.mono, fontSize: 17, fontWeight: FontWeight.w500, color: c.textSecondary)),
          const SizedBox(width: 10),
        ],
        Expanded(
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
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        ?action,
      ]),
    );
  }
}

/// A filled box that opens a chooser: an icon, what is chosen, maybe a pill (the age).
class SlFilledSelect extends StatelessWidget {
  final String icon;
  final String text;
  final bool muted;
  final String? pill;
  final VoidCallback onTap;
  final bool error;
  const SlFilledSelect({super.key, required this.icon, required this.text, this.muted = false, this.pill, required this.onTap, this.error = false});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Semantics(
      button: true,
      child: Material(
        color: c.surfaceMuted,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14), side: BorderSide(color: error ? c.dangerInk : Colors.transparent, width: 1.5)),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
            child: Row(children: [
              LineIcon(icon, size: 20, color: c.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: AppType.text, fontSize: 16, color: muted ? c.textHint : c.textPrimary)),
              ),
              if (pill != null)
                Container(
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: c.cardBackground, borderRadius: BorderRadius.circular(999)),
                  child: Text(pill!,
                      style: TextStyle(fontFamily: AppType.text, fontSize: 12, fontWeight: FontWeight.w700, color: c.textPrimary)),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// One of a few, as tiles in a grid: an icon beside the label, or above it ([column]).
/// With [radio], each tile shows a circle, ticked when chosen (breeds).
class SlTiles<T> extends StatelessWidget {
  final List<(T, String, String?)> options; // value, label, icon path
  final T? value;
  final ValueChanged<T> onChanged;
  final int columns;
  final bool column;
  final bool radio;
  const SlTiles(
      {super.key, required this.options, required this.value, required this.onChanged, this.columns = 2, this.column = false, this.radio = false});

  static const _on = '<circle cx="12" cy="12" r="10"/><path d="m9 12 2 2 4-4"/>';
  static const _off = '<circle cx="12" cy="12" r="10"/>';

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    Widget tile((T, String, String?) o) {
      final (v, label, icon) = o;
      final on = v == value;
      final ink = on ? c.brandText : c.textPrimary;
      final mark = radio ? (on ? _on : _off) : icon;
      final text = Text(label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontFamily: AppType.text, fontSize: column ? 13 : 14, height: 18 / 14, fontWeight: FontWeight.w700, color: ink));
      return Semantics(
        button: true,
        selected: on,
        child: Material(
          color: on ? c.brandSoft : c.surfaceMuted,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14), side: BorderSide(color: on ? c.brandText : Colors.transparent, width: 1.5)),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onChanged(v),
            child: Container(
              constraints: BoxConstraints(minHeight: column ? 76 : 52),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              alignment: Alignment.center,
              child: column
                  ? Column(mainAxisSize: MainAxisSize.min, children: [
                      if (mark != null) ...[LineIcon(mark, size: 20, color: ink), const SizedBox(height: 6)],
                      text,
                    ])
                  : Row(mainAxisSize: MainAxisSize.min, children: [
                      if (mark != null) ...[LineIcon(mark, size: 20, color: ink), const SizedBox(width: 8)],
                      Flexible(child: text),
                    ]),
            ),
          ),
        ),
      );
    }

    final rows = <Widget>[];
    for (var i = 0; i < options.length; i += columns) {
      if (i > 0) rows.add(const SizedBox(height: 8));
      rows.add(IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (var j = i; j < i + columns; j++) ...[
            if (j > i) const SizedBox(width: 8),
            Expanded(child: j < options.length ? tile(options[j]) : const SizedBox()),
          ],
        ]),
      ));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
  }
}

/// Small filled chips: one of several, tap again to clear (a stage).
class SlSoftChoices<T> extends StatelessWidget {
  final List<(T, String)> options;
  final T? value;
  final ValueChanged<T?> onChanged;
  const SlSoftChoices({super.key, required this.options, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Wrap(spacing: 8, runSpacing: 8, children: [
      for (final (v, label) in options)
        Semantics(
          button: true,
          selected: v == value,
          child: Material(
            color: v == value ? c.brandSoft : c.surfaceMuted,
            shape: StadiumBorder(side: BorderSide(color: v == value ? c.brandText : Colors.transparent, width: 1.5)),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () => onChanged(v == value ? null : v),
              child: Container(
                constraints: const BoxConstraints(minHeight: 40),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Center(
                  widthFactor: 1,
                  heightFactor: 1,
                  child: Text(label,
                      style: TextStyle(
                          fontFamily: AppType.text, fontSize: 13, fontWeight: FontWeight.w700, color: v == value ? c.brandText : c.textPrimary)),
                ),
              ),
            ),
          ),
        ),
    ]);
  }
}

/// A weight or count stepper: − and + on white keys either side of a big figure the
/// farmer can also type, and presets under it ("280 kg · Heifer").
class SlStepper extends StatelessWidget {
  final TextEditingController controller;
  final String unit;
  final num step;
  final List<(num, String)> presets;
  final VoidCallback onChanged;
  final bool error;
  const SlStepper(
      {super.key, required this.controller, required this.unit, this.step = 1, this.presets = const [], required this.onChanged, this.error = false});

  num get _value => num.tryParse(controller.text.replaceAll(',', '').trim()) ?? 0;

  void _set(num v) {
    final n = v < 0 ? 0 : v;
    controller.text = n == n.roundToDouble() ? n.round().toString() : n.toStringAsFixed(1);
    onChanged();
  }

  static String _fmt(num v) => v == v.roundToDouble() ? v.round().toString() : v.toString();

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    Widget key(String path, String label, VoidCallback tap) => Semantics(
          button: true,
          label: label,
          excludeSemantics: true,
          child: Material(
            color: c.cardBackground,
            borderRadius: BorderRadius.circular(14),
            elevation: 0,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: tap,
              child: SizedBox(width: 56, height: 56, child: Center(child: LineIcon(path, size: 22, color: c.textPrimary))),
            ),
          ),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: c.surfaceMuted,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: error ? c.dangerInk : Colors.transparent, width: 1.5),
        ),
        child: Row(children: [
          key('<path d="M5 12h14"/>', '{n} {unit} less'.trArgs({'n': _fmt(step), 'unit': unit}), () => _set(_value - step)),
          Expanded(
            child: Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
              Flexible(
                child: IntrinsicWidth(
                  child: TextField(
                    controller: controller,
                    textAlign: TextAlign.center,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    onChanged: (_) => onChanged(),
                    style: AppType.figureL.copyWith(fontSize: 30, color: c.textPrimary),
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: AppType.figureL.copyWith(fontSize: 30, color: c.textHint),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(unit, style: AppType.caption.copyWith(color: c.textSecondary)),
            ]),
          ),
          key('<path d="M5 12h14"/><path d="M12 5v14"/>', '{n} {unit} more'.trArgs({'n': _fmt(step), 'unit': unit}), () => _set(_value + step)),
        ]),
      ),
      if (presets.isNotEmpty) ...[
        const SizedBox(height: 10),
        Row(children: [
          Text('Presets'.tr, style: AppType.caption.copyWith(color: c.textSecondary)),
          for (final (v, label) in presets) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Material(
                color: c.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _set(v),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: Column(children: [
                      Text('${_fmt(v)} $unit',
                          style: TextStyle(fontFamily: AppType.text, fontSize: 12, fontWeight: FontWeight.w700, color: c.textPrimary)),
                      Text(label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontFamily: AppType.text, fontSize: 11, color: c.textSecondary)),
                    ]),
                  ),
                ),
              ),
            ),
          ],
        ]),
      ],
    ]);
  }
}

/// How far the form is, in words: shown above Save. Green once it can be saved.
class SlReadyCard extends StatelessWidget {
  final bool ready;
  final String text;
  const SlReadyCard({super.key, required this.ready, required this.text});

  static const _check =
      '<rect width="8" height="4" x="8" y="2" rx="1" ry="1"/><path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2"/><path d="m9 14 2 2 4-4"/>';

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(color: ready ? c.brandSoft : c.surfaceMuted, borderRadius: BorderRadius.circular(24)),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: ready ? c.shamba : c.cardBackground, borderRadius: BorderRadius.circular(14)),
          child: Center(child: LineIcon(_check, size: 22, color: ready ? c.onShamba : c.textSecondary)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(ready ? 'READY TO SAVE'.tr : 'NOT READY YET'.tr, style: AppType.eyebrow.copyWith(fontSize: 11, color: ready ? c.brandText : c.textSecondary)),
            const SizedBox(height: 2),
            Text(text, style: TextStyle(fontFamily: AppType.text, fontSize: 14, height: 20 / 14, color: c.textPrimary)),
          ]),
        ),
      ]),
    );
  }
}

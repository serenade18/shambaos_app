import 'package:flutter/material.dart';

import '../screens/auth/auth_ui.dart';
import '../services/app_colors.dart';
import '../services/app_type.dart';

/// Shamba Ledger pieces as the mobile designs draw them (sl-tag, sl-chip,
/// sl-ent), in theme colours so they work in both themes.

enum SlTone { good, warn, danger, info, neutral }

/// A status pill: a word, and an icon when it helps (sl-tag).
class SlTag extends StatelessWidget {
  final String text;
  final SlTone tone;
  final String? icon; // a LineIcon path

  const SlTag(this.text, {super.key, this.tone = SlTone.neutral, this.icon});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final (bg, fg) = switch (tone) {
      SlTone.good => (c.goodTint, c.goodInk),
      SlTone.warn => (c.warnTint, c.warnInk),
      SlTone.danger => (c.dangerTint, c.dangerInk),
      SlTone.info => (c.rainTint, c.rainInk),
      SlTone.neutral => (c.surfaceMuted, c.textSecondary),
    };
    return Container(
      height: 28,
      padding: EdgeInsets.fromLTRB(icon == null ? 12 : 10, 0, 12, 0),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[LineIcon(icon!, size: 14, strokeWidth: 2.4, color: fg), const SizedBox(width: 5)],
        Text(text, style: TextStyle(fontFamily: AppType.text, fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w700, color: fg)),
      ]),
    );
  }

  static const check = '<path d="M5 12.5l4.5 4.5L19 7.5"/>';
  static const clock = '<circle cx="12" cy="12" r="10"/><path d="M12 6v6l4 2"/>';
}

/// A filter chip (sl-chip): green when on.
class SlChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const SlChip(this.label, {super.key, this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? c.brandSoft : c.cardBackground,
        shape: StadiumBorder(side: BorderSide(color: selected ? c.brandText : c.border, width: 1.5)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 36),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            // Sized to its label, so a chip in a Wrap doesn't fill the line.
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: Text(label,
                style: TextStyle(fontFamily: AppType.text, fontSize: 13, height: 18 / 13, fontWeight: FontWeight.w700, color: selected ? c.brandText : c.textPrimary)),
            ),
          ),
        ),
      ),
    );
  }
}

/// A white card with the design's soft shadow and 24 radius, tappable.
class SlCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  const SlCard({super.key, required this.child, this.onTap, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: c.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x1217211A), blurRadius: 24, offset: Offset(0, 8))],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// One field, herd or flock as a row (sl-ent): an icon in a green well, the
/// name and a line under it, and something on the right.
class SlEntRow extends StatelessWidget {
  final String? icon; // a LineIcon path
  final Widget? leading; // in place of the line icon, e.g. an illustrated icon
  final String title;
  final String? meta;
  final Widget? end;
  final VoidCallback? onTap;

  const SlEntRow({super.key, this.icon, this.leading, required this.title, this.meta, this.end, this.onTap})
      : assert(icon != null || leading != null);

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return SlCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: c.brandSoft, shape: BoxShape.circle),
            child: Center(child: leading ?? LineIcon(icon!, size: 26, color: c.brandText)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: AppType.text, fontSize: 15, height: 20 / 15, fontWeight: FontWeight.w700, color: c.textPrimary)),
              if (meta != null && meta!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(meta!, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.caption.copyWith(color: c.textSecondary)),
              ],
            ]),
          ),
          if (end != null) ...[const SizedBox(width: 12), end!],
        ]),
      ),
    );
  }
}

/// An on/off switch as the design draws it: a 48×28 pill, green when on.
class SlSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String label; // read out by screen readers

  const SlSwitch({super.key, required this.value, required this.onChanged, required this.label});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Semantics(
      toggled: value,
      label: label,
      enabled: onChanged != null,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 48,
          height: 28,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: onChanged == null ? c.border.withValues(alpha: 0.5) : (value ? c.shamba : c.border),
            borderRadius: BorderRadius.circular(999),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 160),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: c.cardBackground,
                shape: BoxShape.circle,
                boxShadow: const [BoxShadow(color: Color(0x4017211A), blurRadius: 3, offset: Offset(0, 1))],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A ledger row with an icon in a round well (the design's row-ico): settings
/// and menu rows. A chevron shows when it opens something and has no [end].
class SlIconRow extends StatelessWidget {
  final String icon; // a LineIcon path
  final SlTone tone; // the well's colour; neutral is the green well
  final String title;
  final String? meta;
  final Widget? end;
  final VoidCallback? onTap;

  const SlIconRow({super.key, required this.icon, this.tone = SlTone.neutral, required this.title, this.meta, this.end, this.onTap});

  static const _chevron = '<path d="m9 18 6-6-6-6"/>';

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final (bg, fg) = switch (tone) {
      SlTone.warn => (c.warnTint, c.warnInk),
      SlTone.danger => (c.dangerTint, c.dangerInk),
      SlTone.info => (c.rainTint, c.rainInk),
      SlTone.good || SlTone.neutral => (c.brandSoft, c.brandText),
    };
    final trailing = end ?? (onTap != null ? LineIcon(_chevron, size: 22, color: c.textSecondary) : null);
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Center(child: LineIcon(icon, size: 20, color: fg)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(title,
                    style: TextStyle(fontFamily: AppType.text, fontSize: 15, height: 20 / 15, fontWeight: FontWeight.w700, color: c.textPrimary)),
                if (meta != null) ...[
                  const SizedBox(height: 2),
                  Text(meta!, style: AppType.caption.copyWith(color: c.textSecondary)),
                ],
              ]),
            ),
            if (trailing != null) ...[const SizedBox(width: 12), trailing],
          ]),
        ),
      ),
    );
  }
}

/// A small capitals label over a group of ledger rows (the design's ledger-label).
class SlGroupLabel extends StatelessWidget {
  final String text;
  const SlGroupLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
        child: Text(text.toUpperCase(), style: AppType.eyebrow.copyWith(color: context.appColors.textSecondary)),
      );
}

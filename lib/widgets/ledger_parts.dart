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
            alignment: Alignment.center,
            child: Text(label,
                style: TextStyle(fontFamily: AppType.text, fontSize: 13, height: 18 / 13, fontWeight: FontWeight.w700, color: selected ? c.brandText : c.textPrimary)),
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
  final String icon; // a LineIcon path
  final String title;
  final String? meta;
  final Widget? end;
  final VoidCallback? onTap;

  const SlEntRow({super.key, required this.icon, required this.title, this.meta, this.end, this.onTap});

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
            child: Center(child: LineIcon(icon, size: 26, color: c.brandText)),
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

/// Line icons for kinds of field (Lucide, ISC licence).
class FieldIcons {
  FieldIcons._();
  static const egg = '<path d="M12 2C8 2 4 8 4 14a8 8 0 0 0 16 0c0-6-4-12-8-12"/>';
  static const paw = '<circle cx="11" cy="4" r="2"/><circle cx="18" cy="8" r="2"/><circle cx="20" cy="16" r="2"/><path d="M9 10a5 5 0 0 1 5 5v3.5a3.5 3.5 0 0 1-6.84 1.045Q6.52 17.48 4.46 16.84A3.5 3.5 0 0 1 5.5 10Z"/>';
  static const fish = '<path d="M6.5 12c.94-3.46 4.94-6 8.5-6 3.56 0 6.06 2.54 7 6-.94 3.47-3.44 6-7 6s-7.56-2.53-8.5-6Z"/><path d="M18 12v.5"/><path d="M16 17.93a9.77 9.77 0 0 1 0-11.86"/><path d="M7 10.67C7 8 5.58 5.97 2.73 5.5c-1 1.5-1 5 .23 6.5-1.24 1.5-1.24 5-.23 6.5C5.58 18.03 7 16 7 13.33"/>';
  static const wheat = '<path d="M2 22 16 8"/><path d="M3.47 12.53 5 11l1.53 1.53a3.5 3.5 0 0 1 0 4.94L5 19l-1.53-1.53a3.5 3.5 0 0 1 0-4.94Z"/><path d="M7.47 8.53 9 7l1.53 1.53a3.5 3.5 0 0 1 0 4.94L9 15l-1.53-1.53a3.5 3.5 0 0 1 0-4.94Z"/><path d="M11.47 4.53 13 3l1.53 1.53a3.5 3.5 0 0 1 0 4.94L13 11l-1.53-1.53a3.5 3.5 0 0 1 0-4.94Z"/><path d="M20 2h2v2a4 4 0 0 1-4 4h-2V6a4 4 0 0 1 4-4Z"/>';
  static const sprout = '<path d="M14 9.536V7a4 4 0 0 1 4-4h1.5a.5.5 0 0 1 .5.5V5a4 4 0 0 1-4 4 4 4 0 0 0-4 4c0 2 1 3 1 5a5 5 0 0 1-1 3"/><path d="M4 9a5 5 0 0 1 8 4 5 5 0 0 1-8-4"/><path d="M5 21h14"/>';
  static const tree = '<path d="M8 19a4 4 0 0 1-2.24-7.32A3.5 3.5 0 0 1 9 6.03V6a3 3 0 1 1 6 0v.04a3.5 3.5 0 0 1 3.24 5.65A4 4 0 0 1 16 19Z"/><path d="M12 19v3"/>';

  /// The icon for what a field keeps or grows.
  static String of(String type, {required bool crop}) => switch (type) {
        'layers' || 'broilers' => egg,
        'fish' => fish,
        'bananas' || 'avocados' => tree,
        'maize' || 'wheat' || 'rice' || 'beans' => wheat,
        _ => crop ? sprout : paw,
      };
}

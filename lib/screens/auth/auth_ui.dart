import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../services/app_type.dart';

/// Shamba Ledger values for the screens before sign-in (splash, welcome, phone,
/// code). They keep the light design in both themes, so the values are fixed
/// here rather than read from the theme.
class Ledger {
  Ledger._();

  static const paper = Color(0xFFEEF3EE);
  static const sheet = Color(0xFFFFFFFF);
  static const sheetSunk = Color(0xFFE4E9DF);
  static const rule = Color(0xFFD3DACD);
  static const ruleStrong = Color(0xFF7F8C7D);
  static const ink = Color(0xFF17211A);
  static const inkMuted = Color(0xFF4C574E);
  static const inkFaint = Color(0xFF637065);
  static const shamba = Color(0xFF355442);
  static const shambaInk = Color(0xFF2F5B40);
  static const shambaTint = Color(0xFFDCE8DD);
  static const maize = Color(0xFFD99A1E);
  static const dangerInk = Color(0xFFA3261B);
  static const focus = Color(0xFF1F5F82);

  static const radiusField = 14.0;
  static const radiusSheet = 28.0;

  static const shadowSoft = [BoxShadow(color: Color(0x1217211A), blurRadius: 24, offset: Offset(0, 8))];
  static const shadowSheet = [BoxShadow(color: Color(0x1A17211A), blurRadius: 24, offset: Offset(0, -6))];

  // Type, as the design draws it: Atkinson for titles and text, Atkinson Mono for numbers typed in.
  static const title = TextStyle(fontFamily: AppType.text, fontSize: 24, height: 30 / 24, fontWeight: FontWeight.w500, color: ink);
  static const body = TextStyle(fontFamily: AppType.text, fontSize: 15, height: 22 / 15, color: inkMuted);
  static const label = TextStyle(fontFamily: AppType.text, fontSize: 15, height: 20 / 15, fontWeight: FontWeight.w700, color: ink);
  static const caption = TextStyle(fontFamily: AppType.text, fontSize: 13, height: 18 / 13, color: inkMuted);
  static const eyebrow = TextStyle(fontFamily: AppType.text, fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w700, letterSpacing: 0.96, color: inkMuted);
  static const link = TextStyle(fontFamily: AppType.text, fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w700, color: shambaInk);
  static const code = TextStyle(fontFamily: AppType.mono, fontSize: 19, height: 24 / 19, fontWeight: FontWeight.w500, letterSpacing: 0.76, color: ink);
}

/// The Shamba OS leaf in a circle.
class LeafLogo extends StatelessWidget {
  final double size;
  final Color circle;
  final Color leaf;
  const LeafLogo({super.key, this.size = 40, this.circle = Ledger.shamba, this.leaf = Colors.white});

  String _hex(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  @override
  Widget build(BuildContext context) => SvgPicture.string(
        '<svg viewBox="0 0 64 64"><circle cx="32" cy="32" r="32" fill="${_hex(circle)}"/>'
        '<g fill="none" stroke="${_hex(leaf)}" stroke-width="2.8" stroke-linecap="round" stroke-linejoin="round">'
        '<path d="M22.3 40.5C16.5 33.5 18.5 24.5 26.5 21C32.5 18.5 38 18.8 43.8 16.8C44.6 25.5 42.5 33 37.5 37.3C33 41 27 42.3 22.3 40.5Z"/>'
        '<path d="M17.6 47.4C19.8 41.5 24.5 36 32.3 32.2"/></g></svg>',
        width: size,
        height: size,
        excludeFromSemantics: true,
      );
}

/// The line icons the design uses (Lucide, ISC licence), drawn as SVG.
class LineIcon extends StatelessWidget {
  final String paths;
  final double size;
  final Color color;
  const LineIcon(this.paths, {super.key, this.size = 24, this.color = Ledger.ink});

  static const arrowLeft = '<path d="m12 19-7-7 7-7"/><path d="M19 12H5"/>';
  static const phone = '<path d="M13.832 16.568a1 1 0 0 0 1.213-.303l.355-.465A2 2 0 0 1 17 15h3a2 2 0 0 1 2 2v3a2 2 0 0 1-2 2A18 18 0 0 1 2 4a2 2 0 0 1 2-2h3a2 2 0 0 1 2 2v3a2 2 0 0 1-.8 1.6l-.468.351a1 1 0 0 0-.292 1.233 14 14 0 0 0 6.392 6.384"/>';
  static const fingerprint = '<path d="M12 10a2 2 0 0 0-2 2c0 1.02-.1 2.51-.26 4"/><path d="M14 13.12c0 2.38 0 6.38-1 8.88"/><path d="M17.29 21.02c.12-.6.43-2.3.5-3.02"/><path d="M2 12a10 10 0 0 1 18-6"/><path d="M2 16h.01"/><path d="M21.8 16c.2-2 .131-5.354 0-6"/><path d="M5 19.5C5.5 18 6 15 6 12a6 6 0 0 1 .34-2"/><path d="M8.65 22c.21-.66.45-1.32.57-2"/><path d="M9 6.8a6 6 0 0 1 9 5.2v2"/>';
  static const chevronDown = '<path d="m6 9 6 6 6-6"/>';
  static const x = '<path d="M18 6 6 18"/><path d="m6 6 12 12"/>';

  @override
  Widget build(BuildContext context) {
    final hex = '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    return SvgPicture.string(
      '<svg viewBox="0 0 24 24" fill="none" stroke="$hex" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">$paths</svg>',
      width: size,
      height: size,
      excludeFromSemantics: true,
    );
  }
}

enum LedgerButtonKind { primary, secondary, light }

/// A pill button: primary (green), secondary (white with a rule) or light
/// (white on a photo).
class LedgerButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final LedgerButtonKind kind;
  final bool large;
  final bool busy;
  final Widget? icon;
  final String? semanticLabel;

  const LedgerButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = LedgerButtonKind.primary,
    this.large = true,
    this.busy = false,
    this.icon,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, fg, side) = switch (kind) {
      LedgerButtonKind.primary => (Ledger.shamba, Colors.white, BorderSide.none),
      LedgerButtonKind.secondary => (Ledger.sheet, Ledger.ink, const BorderSide(color: Ledger.ruleStrong, width: 1.5)),
      LedgerButtonKind.light => (Colors.white, Ledger.ink, BorderSide.none),
    };
    final showLabel = label.isNotEmpty;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: SizedBox(
        height: large ? 56 : 52,
        child: TextButton(
          onPressed: busy ? null : onPressed,
          style: TextButton.styleFrom(
            backgroundColor: bg,
            disabledBackgroundColor: bg.withValues(alpha: 0.45),
            foregroundColor: fg,
            disabledForegroundColor: fg,
            padding: EdgeInsets.symmetric(horizontal: showLabel ? 24 : 0),
            shape: StadiumBorder(side: side),
            textStyle: TextStyle(fontFamily: AppType.text, fontSize: large ? 17 : 16, height: 20 / 16, fontWeight: FontWeight.w700),
          ),
          child: busy
              ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: fg, strokeWidth: 2.5))
              : Row(mainAxisSize: MainAxisSize.min, children: [
                  ?icon,
                  if (icon != null && showLabel) const SizedBox(width: 8),
                  if (showLabel) Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
                ]),
        ),
      ),
    );
  }
}

/// The labelled input box from the design: a 56-high box with a strong rule,
/// an optional sunk prefix (the country code) and a hint or error under it.
class LedgerField extends StatelessWidget {
  final String label;
  final Widget input;
  final Widget? prefix;
  final String? hint;
  final String? error;
  final bool focused;

  const LedgerField({super.key, required this.label, required this.input, this.prefix, this.hint, this.error, this.focused = false});

  @override
  Widget build(BuildContext context) {
    final message = error ?? hint;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(label, style: Ledger.label),
      const SizedBox(height: 6),
      Container(
        height: 56,
        decoration: BoxDecoration(
          color: Ledger.sheet,
          borderRadius: BorderRadius.circular(Ledger.radiusField),
          border: Border.all(color: error != null ? Ledger.dangerInk : Ledger.ruleStrong, width: 1.5),
          // The 3px focus ring.
          boxShadow: focused ? [const BoxShadow(color: Ledger.focus, spreadRadius: 3)] : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (prefix != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: const BoxDecoration(color: Ledger.sheetSunk, border: Border(right: BorderSide(color: Ledger.rule))),
              child: Center(child: prefix),
            ),
          Expanded(child: input),
        ]),
      ),
      if (message != null) ...[
        const SizedBox(height: 6),
        Text(message, style: Ledger.caption.copyWith(color: error != null ? Ledger.dangerInk : Ledger.inkMuted)),
      ],
    ]);
  }
}

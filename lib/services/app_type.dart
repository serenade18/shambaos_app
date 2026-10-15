import 'package:flutter/painting.dart';

/// Shamba Ledger type styles (see shamba-ledger/tokens.json).
///
/// Zilla Slab for figures and titles, Atkinson Hyperlegible Next for everything
/// people read, Atkinson Hyperlegible Mono for codes typed or copied character
/// by character. Styles carry no colour: they take it from the surrounding
/// DefaultTextStyle, or from `.copyWith(color: …)`.
class AppType {
  AppType._();

  static const display = 'ZillaSlab';
  static const text = 'Atkinson';
  static const mono = 'AtkinsonMono';

  static const _tabular = [FontFeature.tabularFigures(), FontFeature.liningFigures()];

  // ── Figures (display) ────────────────────────────────────
  /// The one key figure on a screen.
  static const figureXl = TextStyle(fontFamily: display, fontSize: 40, height: 44 / 40, fontWeight: FontWeight.w600, letterSpacing: -0.4, fontFeatures: _tabular);
  /// Figures in summary tiles and the tally stepper.
  static const figureL = TextStyle(fontFamily: display, fontSize: 28, height: 32 / 28, fontWeight: FontWeight.w600, fontFeatures: _tabular);
  /// An enterprise tile's figure.
  static const figureM = TextStyle(fontFamily: display, fontSize: 20, height: 24 / 20, fontWeight: FontWeight.w600, fontFeatures: _tabular);
  /// Right-hand figure of a ledger row.
  static const figureS = TextStyle(fontFamily: display, fontSize: 17, height: 22 / 17, fontWeight: FontWeight.w600, fontFeatures: _tabular);

  // ── Titles (display) ─────────────────────────────────────
  static const titleL = TextStyle(fontFamily: display, fontSize: 24, height: 30 / 24, fontWeight: FontWeight.w600);
  static const titleM = TextStyle(fontFamily: display, fontSize: 19, height: 24 / 19, fontWeight: FontWeight.w600);

  // ── Text ─────────────────────────────────────────────────
  static const bodyL = TextStyle(fontFamily: text, fontSize: 17, height: 26 / 17, fontWeight: FontWeight.w400);
  static const body = TextStyle(fontFamily: text, fontSize: 15, height: 22 / 15, fontWeight: FontWeight.w400);
  static const label = TextStyle(fontFamily: text, fontSize: 15, height: 20 / 15, fontWeight: FontWeight.w700);
  static const caption = TextStyle(fontFamily: text, fontSize: 13, height: 18 / 13, fontWeight: FontWeight.w400);
  /// Uppercase section stamps. Write the copy in capitals.
  static const eyebrow = TextStyle(fontFamily: text, fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w700, letterSpacing: 0.96);

  // ── Codes (mono) ─────────────────────────────────────────
  static const code = TextStyle(fontFamily: mono, fontSize: 19, height: 24 / 19, fontWeight: FontWeight.w500, letterSpacing: 0.76);
  static const codeS = TextStyle(fontFamily: mono, fontSize: 13, height: 18 / 13, fontWeight: FontWeight.w400, letterSpacing: 0.26);
}

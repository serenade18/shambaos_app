import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shamba Ledger colour tokens (see shamba-ledger/tokens.json).
/// Access anywhere via: context.appColors.cardBackground
///
/// The older field names are kept and mapped onto the tokens:
/// paper → scaffoldBackground, sheet → cardBackground, sheet-sunk → surfaceMuted,
/// rule → divider, rule-strong → border, ink → textPrimary, ink-muted →
/// textSecondary, ink-faint → textHint, shamba-ink → brandText, shamba-tint → brandSoft.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  // ── Surfaces ────────────────────────────────────────────
  final Color scaffoldBackground;  // paper: the page
  final Color cardBackground;      // sheet: ledgers, cards, inputs, nav
  final Color chipBackground;      // sheet
  final Color chipSelected;        // shamba
  final Color surfaceMuted;        // sheet-sunk: inset wells inside a sheet

  // ── Text ────────────────────────────────────────────────
  final Color textPrimary;         // ink
  final Color textSecondary;       // ink-muted: units, metadata
  final Color textHint;            // ink-faint: placeholders, inactive nav (not on surfaceMuted)

  // ── Header / Nav ────────────────────────────────────────
  final Color headerBackground;    // the deep green top bar
  final Color avatarBorder;
  final Color iconOverlay;         // white overlay buttons in header

  // ── Rules ───────────────────────────────────────────────
  final Color divider;             // rule: hairlines between ledger rows
  final Color border;              // rule-strong: control borders, the total's double rule

  // ── Brand ───────────────────────────────────────────────
  final Color shamba;              // logo green fill; light in dark mode, pair with onShamba
  final Color onShamba;
  final Color brandText;           // shamba-ink: green text and icons
  final Color brandSoft;           // shamba-tint: selected chips, icon wells
  final Color maize;               // here and now only: today's marker, the active tab
  final Color onMaize;
  final Color maizeInk;
  final Color seasonRain;          // rainy months on the season strip

  // ── Status (always with a word or icon) ─────────────────
  final Color goodInk;
  final Color goodTint;
  final Color warnInk;
  final Color warnTint;
  final Color dangerInk;
  final Color dangerTint;
  final Color rainInk;             // weather and information
  final Color rainTint;
  final Color focus;               // 3px focus ring

  /// The logo green, the same in both themes. For fills that keep white text on
  /// them in every theme; theme-aware fills use [shamba] with [onShamba].
  static const Color brand = Color(0xFF355442);
  static const Color brandDark = Color(0xFF24392D);

  const AppColors({
    required this.scaffoldBackground,
    required this.cardBackground,
    required this.chipBackground,
    required this.chipSelected,
    required this.surfaceMuted,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.headerBackground,
    required this.avatarBorder,
    required this.iconOverlay,
    required this.divider,
    required this.border,
    required this.shamba,
    required this.onShamba,
    required this.brandText,
    required this.brandSoft,
    required this.maize,
    required this.onMaize,
    required this.maizeInk,
    required this.seasonRain,
    required this.goodInk,
    required this.goodTint,
    required this.warnInk,
    required this.warnTint,
    required this.dangerInk,
    required this.dangerTint,
    required this.rainInk,
    required this.rainTint,
    required this.focus,
  });

  // ── Light ────────────────────────────────────────────────
  static const light = AppColors(
    scaffoldBackground: Color(0xFFEEF1EA),
    cardBackground: Color(0xFFFAFBF7),
    chipBackground: Color(0xFFFAFBF7),
    chipSelected: Color(0xFF355442),
    surfaceMuted: Color(0xFFE4E9DF),
    textPrimary: Color(0xFF17211A),
    textSecondary: Color(0xFF4C574E),
    textHint: Color(0xFF637065),
    headerBackground: Color(0xFF24392D),
    avatarBorder: Color(0x4DFFFFFF),
    iconOverlay: Color(0x1FFFFFFF),
    divider: Color(0xFFD3DACD),
    border: Color(0xFF7F8C7D),
    shamba: Color(0xFF355442),
    onShamba: Color(0xFFFFFFFF),
    brandText: Color(0xFF2F5B40),
    brandSoft: Color(0xFFDCE8DD),
    maize: Color(0xFFD99A1E),
    onMaize: Color(0xFF1F1606),
    maizeInk: Color(0xFF8A5A00),
    seasonRain: Color(0xFFA9CBDD),
    goodInk: Color(0xFF2F5B40),
    goodTint: Color(0xFFDCE8DD),
    warnInk: Color(0xFF9A4A0B),
    warnTint: Color(0xFFF6E3CF),
    dangerInk: Color(0xFFA3261B),
    dangerTint: Color(0xFFF7DEDA),
    rainInk: Color(0xFF1F5F82),
    rainTint: Color(0xFFDCEBF2),
    focus: Color(0xFF1F5F82),
  );

  // ── Dark ─────────────────────────────────────────────────
  static const dark = AppColors(
    scaffoldBackground: Color(0xFF101511),
    cardBackground: Color(0xFF182019),
    chipBackground: Color(0xFF182019),
    chipSelected: Color(0xFF8FC9A0),
    surfaceMuted: Color(0xFF222B23),
    textPrimary: Color(0xFFE8EDE5),
    textSecondary: Color(0xFFA3AFA4),
    textHint: Color(0xFF879386),
    headerBackground: Color(0xFF1F3427),
    avatarBorder: Color(0x4DFFFFFF),
    iconOverlay: Color(0x1FFFFFFF),
    divider: Color(0xFF2F3A31),
    border: Color(0xFF6B786C),
    shamba: Color(0xFF8FC9A0),
    onShamba: Color(0xFF0F1A12),
    brandText: Color(0xFF9ED4AE),
    brandSoft: Color(0xFF1F3427),
    maize: Color(0xFFE8B04A),
    onMaize: Color(0xFF1F1606),
    maizeInk: Color(0xFFF0C060),
    seasonRain: Color(0xFF2D5670),
    goodInk: Color(0xFF9ED4AE),
    goodTint: Color(0xFF1F3427),
    warnInk: Color(0xFFF2A66A),
    warnTint: Color(0xFF3A2614),
    dangerInk: Color(0xFFFF8A7A),
    dangerTint: Color(0xFF3D1C18),
    rainInk: Color(0xFF8CC4E3),
    rainTint: Color(0xFF172A35),
    focus: Color(0xFF8CC4E3),
  );

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      scaffoldBackground: l(scaffoldBackground, other.scaffoldBackground),
      cardBackground: l(cardBackground, other.cardBackground),
      chipBackground: l(chipBackground, other.chipBackground),
      chipSelected: l(chipSelected, other.chipSelected),
      surfaceMuted: l(surfaceMuted, other.surfaceMuted),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textHint: l(textHint, other.textHint),
      headerBackground: l(headerBackground, other.headerBackground),
      avatarBorder: l(avatarBorder, other.avatarBorder),
      iconOverlay: l(iconOverlay, other.iconOverlay),
      divider: l(divider, other.divider),
      border: l(border, other.border),
      shamba: l(shamba, other.shamba),
      onShamba: l(onShamba, other.onShamba),
      brandText: l(brandText, other.brandText),
      brandSoft: l(brandSoft, other.brandSoft),
      maize: l(maize, other.maize),
      onMaize: l(onMaize, other.onMaize),
      maizeInk: l(maizeInk, other.maizeInk),
      seasonRain: l(seasonRain, other.seasonRain),
      goodInk: l(goodInk, other.goodInk),
      goodTint: l(goodTint, other.goodTint),
      warnInk: l(warnInk, other.warnInk),
      warnTint: l(warnTint, other.warnTint),
      dangerInk: l(dangerInk, other.dangerInk),
      dangerTint: l(dangerTint, other.dangerTint),
      rainInk: l(rainInk, other.rainInk),
      rainTint: l(rainTint, other.rainTint),
      focus: l(focus, other.focus),
    );
  }
}

/// Convenience extension — use `context.appColors` anywhere
extension AppColorsX on BuildContext {
  AppColors get appColors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;

  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Status bar icons that stay visible on the current theme's light or dark surfaces.
  SystemUiOverlayStyle get overlayStyle =>
      isDarkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark;
}

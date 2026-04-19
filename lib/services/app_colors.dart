import 'package:flutter/material.dart';

/// Custom color tokens for Shamba OS.
/// Access anywhere via: context.appColors.cardBackground
@immutable
class AppColors extends ThemeExtension<AppColors> {
  // ── Backgrounds ─────────────────────────────────────────
  final Color scaffoldBackground;
  final Color cardBackground;
  final Color chipBackground;
  final Color chipSelected;

  // ── Text ────────────────────────────────────────────────
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;

  // ── Header / Nav ────────────────────────────────────────
  final Color headerBackground;    // the dark green top bar
  final Color avatarBorder;
  final Color iconOverlay;         // white overlay buttons in header

  // ── Dividers & Borders ──────────────────────────────────
  final Color divider;
  final Color border;

  // ── Brand ───────────────────────────────────────────────
  static const Color brand = Color(0xFF109641);
  static const Color brandDark = Color(0xFF2D5A27);

  const AppColors({
    required this.scaffoldBackground,
    required this.cardBackground,
    required this.chipBackground,
    required this.chipSelected,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.headerBackground,
    required this.avatarBorder,
    required this.iconOverlay,
    required this.divider,
    required this.border,
  });

  // ── Light ────────────────────────────────────────────────
  static const light = AppColors(
    scaffoldBackground: Color(0xFFF4F7F2),
    cardBackground: Colors.white,
    chipBackground: Colors.white,
    chipSelected: Color(0xFF3D7A35),
    textPrimary: Color(0xFF1A1A1A),
    textSecondary: Color(0xFF555555),
    textHint: Color(0xFF999999),
    headerBackground: Color(0xFF2D5A27),
    avatarBorder: Color(0x4DFFFFFF),   // white 30%
    iconOverlay: Color(0x1FFFFFFF),    // white 12%
    divider: Color(0xFFEEEEEE),
    border: Color(0xFFE0E0E0),
  );

  // ── Dark ─────────────────────────────────────────────────
  static const dark = AppColors(
    scaffoldBackground: Color(0xFF0F0F0F),
    cardBackground: Color(0xFF1E1E1E),
    chipBackground: Color(0xFF2A2A2A),
    chipSelected: Color(0xFF109641),
    textPrimary: Color(0xFFF1F1F1),
    textSecondary: Color(0xFFAAAAAA),
    textHint: Color(0xFF666666),
    headerBackground: Color(0xFF1A2E18),  // darker green for dark mode
    avatarBorder: Color(0x4DFFFFFF),
    iconOverlay: Color(0x1FFFFFFF),
    divider: Color(0xFF2C2C2C),
    border: Color(0xFF3A3A3A),
  );

  @override
  AppColors copyWith({
    Color? scaffoldBackground,
    Color? cardBackground,
    Color? chipBackground,
    Color? chipSelected,
    Color? textPrimary,
    Color? textSecondary,
    Color? textHint,
    Color? headerBackground,
    Color? avatarBorder,
    Color? iconOverlay,
    Color? divider,
    Color? border,
  }) {
    return AppColors(
      scaffoldBackground: scaffoldBackground ?? this.scaffoldBackground,
      cardBackground: cardBackground ?? this.cardBackground,
      chipBackground: chipBackground ?? this.chipBackground,
      chipSelected: chipSelected ?? this.chipSelected,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textHint: textHint ?? this.textHint,
      headerBackground: headerBackground ?? this.headerBackground,
      avatarBorder: avatarBorder ?? this.avatarBorder,
      iconOverlay: iconOverlay ?? this.iconOverlay,
      divider: divider ?? this.divider,
      border: border ?? this.border,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      scaffoldBackground: Color.lerp(scaffoldBackground, other.scaffoldBackground, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      chipBackground: Color.lerp(chipBackground, other.chipBackground, t)!,
      chipSelected: Color.lerp(chipSelected, other.chipSelected, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textHint: Color.lerp(textHint, other.textHint, t)!,
      headerBackground: Color.lerp(headerBackground, other.headerBackground, t)!,
      avatarBorder: Color.lerp(avatarBorder, other.avatarBorder, t)!,
      iconOverlay: Color.lerp(iconOverlay, other.iconOverlay, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      border: Color.lerp(border, other.border, t)!,
    );
  }
}

/// Convenience extension — use `context.appColors` anywhere
extension AppColorsX on BuildContext {
  AppColors get appColors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;
}
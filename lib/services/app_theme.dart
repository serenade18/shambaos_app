import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_type.dart';

/// Material theme built from the Shamba Ledger tokens, so stock widgets
/// (buttons, fields, chips, switches, sheets, dialogs) follow the system.
class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(AppColors.light, Brightness.light);
  static ThemeData dark() => _build(AppColors.dark, Brightness.dark);

  static const _radiusM = BorderRadius.all(Radius.circular(10));

  static ThemeData _build(AppColors c, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.shamba,
      onPrimary: c.onShamba,
      primaryContainer: c.brandSoft,
      onPrimaryContainer: c.brandText,
      secondary: c.maize,
      onSecondary: c.onMaize,
      tertiary: c.rainInk,
      onTertiary: c.cardBackground,
      error: c.dangerInk,
      onError: c.cardBackground,
      errorContainer: c.dangerTint,
      onErrorContainer: c.dangerInk,
      surface: c.cardBackground,
      onSurface: c.textPrimary,
      onSurfaceVariant: c.textSecondary,
      surfaceContainerLowest: c.cardBackground,
      surfaceContainerLow: c.cardBackground,
      surfaceContainer: c.cardBackground,
      surfaceContainerHigh: c.cardBackground,
      surfaceContainerHighest: c.surfaceMuted,
      outline: c.border,
      outlineVariant: c.divider,
      shadow: Colors.black,
      surfaceTint: Colors.transparent,
    );

    TextStyle ink(TextStyle s) => s.copyWith(color: c.textPrimary);
    TextStyle muted(TextStyle s) => s.copyWith(color: c.textSecondary);

    final textTheme = TextTheme(
      displayLarge: ink(AppType.figureXl),
      displayMedium: ink(AppType.figureL),
      displaySmall: ink(AppType.figureM),
      headlineLarge: ink(AppType.titleL),
      headlineMedium: ink(AppType.titleL),
      headlineSmall: ink(AppType.titleL),
      titleLarge: ink(AppType.titleM),
      titleMedium: ink(AppType.label),
      titleSmall: ink(AppType.label),
      bodyLarge: ink(AppType.bodyL),
      bodyMedium: ink(AppType.body),
      bodySmall: muted(AppType.caption),
      labelLarge: AppType.label.copyWith(fontSize: 16),
      labelMedium: ink(AppType.caption.copyWith(fontWeight: FontWeight.w700)),
      labelSmall: muted(AppType.eyebrow),
    );

    final buttonShape = WidgetStatePropertyAll<OutlinedBorder>(
      const RoundedRectangleBorder(borderRadius: _radiusM),
    );
    const buttonSize = WidgetStatePropertyAll(Size(64, 52));
    const buttonText = WidgetStatePropertyAll(TextStyle(fontFamily: AppType.text, fontSize: 16, fontWeight: FontWeight.w700));
    final focusRing = WidgetStateProperty.resolveWith<BorderSide?>((s) =>
        s.contains(WidgetState.focused) ? BorderSide(color: c.focus, width: 3) : null);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: AppType.text,
      textTheme: textTheme,
      scaffoldBackgroundColor: c.scaffoldBackground,
      canvasColor: c.scaffoldBackground,
      cardColor: c.cardBackground,
      dividerColor: c.divider,
      extensions: [c],
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: c.cardBackground,
        foregroundColor: c.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: ink(AppType.titleM),
        shape: Border(bottom: BorderSide(color: c.divider)),
      ),
      cardTheme: CardThemeData(
        color: c.cardBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: _radiusM, side: BorderSide(color: c.divider)),
      ),
      dividerTheme: DividerThemeData(color: c.divider, thickness: 1, space: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.disabled) ? c.shamba.withValues(alpha: 0.45) : c.shamba),
          foregroundColor: WidgetStatePropertyAll(c.onShamba),
          overlayColor: WidgetStatePropertyAll(c.textPrimary.withValues(alpha: 0.08)),
          elevation: const WidgetStatePropertyAll(0),
          minimumSize: buttonSize,
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 20)),
          shape: buttonShape,
          textStyle: buttonText,
          side: focusRing,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(c.shamba),
          foregroundColor: WidgetStatePropertyAll(c.onShamba),
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: buttonText,
          side: focusRing,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(c.cardBackground),
          foregroundColor: WidgetStatePropertyAll(c.textPrimary),
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: buttonText,
          side: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.focused)
              ? BorderSide(color: c.focus, width: 3)
              : BorderSide(color: c.border, width: 1.5)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(c.brandText),
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.cardBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        labelStyle: muted(AppType.body),
        floatingLabelStyle: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w700),
        hintStyle: AppType.body.copyWith(color: c.textHint),
        helperStyle: muted(AppType.caption),
        errorStyle: AppType.caption.copyWith(color: c.dangerInk),
        border: OutlineInputBorder(borderRadius: _radiusM, borderSide: BorderSide(color: c.border, width: 1.5)),
        enabledBorder: OutlineInputBorder(borderRadius: _radiusM, borderSide: BorderSide(color: c.border, width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: _radiusM, borderSide: BorderSide(color: c.focus, width: 3)),
        errorBorder: OutlineInputBorder(borderRadius: _radiusM, borderSide: BorderSide(color: c.dangerInk, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: _radiusM, borderSide: BorderSide(color: c.dangerInk, width: 3)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.cardBackground,
        selectedColor: c.brandSoft,
        side: BorderSide(color: c.border, width: 1.5),
        shape: const StadiumBorder(),
        labelStyle: AppType.caption.copyWith(fontWeight: FontWeight.w700, color: c.textPrimary),
        secondaryLabelStyle: AppType.caption.copyWith(fontWeight: FontWeight.w700, color: c.brandText),
        showCheckmark: false,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.onShamba : c.cardBackground),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.shamba : c.border),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.shamba, linearTrackColor: c.surfaceMuted),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.cardBackground,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: c.cardBackground,
        elevation: 8,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        showDragHandle: true,
        dragHandleColor: c.border,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.cardBackground,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
        titleTextStyle: ink(AppType.titleM),
        contentTextStyle: ink(AppType.body),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.textPrimary,
        contentTextStyle: AppType.body.copyWith(color: c.scaffoldBackground),
        actionTextColor: c.maize,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: _radiusM),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: c.textSecondary,
        textColor: c.textPrimary,
        titleTextStyle: ink(AppType.label),
        subtitleTextStyle: muted(AppType.caption),
        minVerticalPadding: 12,
      ),
      iconTheme: IconThemeData(color: c.textPrimary, size: 22),
    );
  }
}

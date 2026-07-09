import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand palette.
///
/// Primary #101820 (deep charcoal navy) is the canvas of the dark theme and
/// the ink of the light theme; accent #F2AA4C (amber) is used sparingly for
/// primary actions, highlights and focus.
abstract final class AppColors {
  static const primary = Color(0xFF101820);
  static const accent = Color(0xFFF2AA4C);

  // Dark surfaces — stepped elevations of the primary navy.
  static const darkSurface = Color(0xFF16202B);
  static const darkSurfaceHigh = Color(0xFF1C2836);
  static const darkOutline = Color(0xFF2C3B4C);

  // Light surfaces.
  static const lightBackground = Color(0xFFF7F8FA);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightOutline = Color(0xFFE1E5EA);

  static const success = Color(0xFF4CAF7D);
  static const danger = Color(0xFFE5646E);
}

abstract final class AppTheme {
  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.accent,
      onPrimary: AppColors.primary,
      secondary: AppColors.accent,
      onSecondary: AppColors.primary,
      surface: AppColors.darkSurface,
      onSurface: const Color(0xFFE8EDF2),
      surfaceContainerHighest: AppColors.darkSurfaceHigh,
      surfaceContainerLow: const Color(0xFF131C26),
      outline: AppColors.darkOutline,
      outlineVariant: const Color(0xFF223040),
      error: AppColors.danger,
    );
    return _base(scheme).copyWith(
      scaffoldBackgroundColor: AppColors.primary,
    );
  }

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: const Color(0xFFB97A22), // accent darkened for contrast
      onSecondary: Colors.white,
      surface: AppColors.lightSurface,
      onSurface: AppColors.primary,
      surfaceContainerHighest: const Color(0xFFEFF2F5),
      outline: AppColors.lightOutline,
      outlineVariant: const Color(0xFFEDF0F4),
      error: AppColors.danger,
    );
    return _base(scheme).copyWith(
      scaffoldBackgroundColor: AppColors.lightBackground,
    );
  }

  static ThemeData _base(ColorScheme scheme) {
    final textTheme = GoogleFonts.interTextTheme(
      ThemeData(brightness: scheme.brightness).textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: scheme.brightness,
      textTheme: textTheme.copyWith(
        headlineSmall: textTheme.headlineSmall
            ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.4),
        titleLarge: textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
        titleMedium:
            textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        side: BorderSide(color: scheme.outlineVariant),
        backgroundColor: scheme.surface,
        selectedColor: scheme.primary.withValues(alpha: 0.18),
        labelStyle: textTheme.labelLarge,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.secondary, width: 1.6),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        indicatorColor: scheme.primary.withValues(alpha: 0.16),
        surfaceTintColor: Colors.transparent,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        indicatorColor: scheme.primary.withValues(alpha: 0.16),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
      snackBarTheme:
          const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}

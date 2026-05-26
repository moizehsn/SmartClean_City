import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../../main.dart' show localeNotifier;

/// Central theme for SmartClean City — Urban Organicism design system.
/// Light mode only.
///
/// **Typography strategy:**
///   - French  → Manrope (display) + Plus Jakarta Sans (body)
///   - Arabic  → Tajawal (display) + Cairo (body)   — premium Arabic fonts
///
/// The [light] getter reads the current locale from [localeNotifier]
/// so the entire text theme adapts when the user toggles language.
class AppTheme {
  AppTheme._();

  // ── Helpers — pick font family by locale ────────────────────────────────────
  static bool get _isArabic => localeNotifier.value.languageCode == 'ar';

  static TextStyle _display(
    double size,
    FontWeight weight, {
    double spacing = 0,
    Color? color,
  }) {
    return _isArabic
        ? GoogleFonts.tajawal(
            fontSize: size + 2, // Increased for Arabic readability
            fontWeight: weight,
            letterSpacing: spacing,
            color: color ?? AppColors.onSurface,
          )
        : GoogleFonts.manrope(
            fontSize: size,
            fontWeight: weight,
            letterSpacing: spacing,
            color: color ?? AppColors.onSurface,
          );
  }

  static TextStyle _body(
    double size,
    FontWeight weight, {
    double spacing = 0,
    Color? color,
    double height = 1.0,
  }) {
    return _isArabic
        ? GoogleFonts.cairo(
            fontSize: size + 1.5, // Increased for Arabic readability
            fontWeight: weight,
            letterSpacing: spacing,
            color: color ?? AppColors.onSurface,
            height: height,
          )
        : GoogleFonts.plusJakartaSans(
            fontSize: size,
            fontWeight: weight,
            letterSpacing: spacing,
            color: color ?? AppColors.onSurface,
            height: height,
          );
  }

  static ThemeData get light {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.surfaceContainerLowest,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.onTertiary,
      tertiaryContainer: AppColors.tertiaryContainer,
      onTertiaryContainer: AppColors.surfaceContainerLowest,
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.error,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
      inverseSurface: AppColors.inverseSurface,
      onInverseSurface: AppColors.inverseOnSurface,
      inversePrimary: AppColors.inversePrimary,
      surfaceTint: AppColors.surfaceTint,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,

      // ─── Typography ────────────────────────────────────────────────────────
      textTheme: TextTheme(
        // Display — Manrope / Tajawal
        displayLarge: _display(57, FontWeight.w700, spacing: -1.14),
        displayMedium: _display(45, FontWeight.w700, spacing: -0.9),
        displaySmall: _display(36, FontWeight.w700, spacing: -0.72),
        // Headline — Manrope / Tajawal
        headlineLarge: _display(32, FontWeight.w600, spacing: -0.5),
        headlineMedium: _display(28, FontWeight.w600, spacing: -0.3),
        headlineSmall: _display(24, FontWeight.w600),
        // Title — Plus Jakarta Sans / Cairo
        titleLarge: _body(22, FontWeight.w600),
        titleMedium: _body(16, FontWeight.w600, spacing: 0.15),
        titleSmall: _body(14, FontWeight.w500, spacing: 0.1),
        // Body — Plus Jakarta Sans / Cairo
        bodyLarge: _body(16, FontWeight.w400, spacing: 0.15),
        bodyMedium: _body(14, FontWeight.w400, spacing: 0.25),
        bodySmall: _body(
          12,
          FontWeight.w400,
          spacing: 0.4,
          color: AppColors.onSurfaceVariant,
        ),
        // Label — Plus Jakarta Sans / Cairo
        labelLarge: _body(14, FontWeight.w600, spacing: 0.1),
        labelMedium: _body(
          12,
          FontWeight.w500,
          spacing: 0.5,
          color: AppColors.onSurfaceVariant,
        ),
        labelSmall: _body(
          11,
          FontWeight.w500,
          spacing: 0.5,
          color: AppColors.onSurfaceVariant,
        ),
      ),

      // ─── Input Fields — No-Line Rule ───────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        hintStyle: _body(
          14,
          FontWeight.w400,
          color: AppColors.onSurfaceVariant,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),

      // ─── Elevated Button ───────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          textStyle: _body(16, FontWeight.w600, spacing: 0.1),
          elevation: 0,
        ),
      ),

      // ─── Text Button ──────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: _body(14, FontWeight.w600),
        ),
      ),

      // ─── AppBar ───────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: _display(20, FontWeight.w600),
        iconTheme: const IconThemeData(color: AppColors.onSurface),
      ),

      // ─── Chip ─────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceContainerLow,
        selectedColor: AppColors.primaryFixed,
        labelStyle: _body(13, FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // ─── Card ─────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: EdgeInsets.zero,
      ),

      // ─── Dividers invisible — No-Line Rule ────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: Colors.transparent,
        thickness: 0,
      ),
    );
  }
}

/// ─── Driver Theme ────────────────────────────────────────────────────────────
/// Deep Orange + Navy dark theme exclusively for the Driver shell.
/// Shares the same typography strategy as [AppTheme] for consistency.
class DriverTheme {
  DriverTheme._();

  static bool get _isArabic => localeNotifier.value.languageCode == 'ar';

  static TextStyle _display(
    double size,
    FontWeight weight, {
    double spacing = 0,
    Color? color,
  }) {
    return _isArabic
        ? GoogleFonts.tajawal(
            fontSize: size + 2,
            fontWeight: weight,
            letterSpacing: spacing,
            color: color ?? AppColors.driverOnSurface,
          )
        : GoogleFonts.manrope(
            fontSize: size,
            fontWeight: weight,
            letterSpacing: spacing,
            color: color ?? AppColors.driverOnSurface,
          );
  }

  static TextStyle _body(
    double size,
    FontWeight weight, {
    double spacing = 0,
    Color? color,
    double height = 1.0,
  }) {
    return _isArabic
        ? GoogleFonts.cairo(
            fontSize: size + 1.5,
            fontWeight: weight,
            letterSpacing: spacing,
            color: color ?? AppColors.driverOnSurface,
            height: height,
          )
        : GoogleFonts.plusJakartaSans(
            fontSize: size,
            fontWeight: weight,
            letterSpacing: spacing,
            color: color ?? AppColors.driverOnSurface,
            height: height,
          );
  }

  static ThemeData get light {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.driverPrimary,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFBF360C),
      onPrimaryContainer: Colors.white,
      secondary: AppColors.driverAccent,
      onSecondary: AppColors.driverBackground,
      secondaryContainer: const Color(0xFF3E2800),
      onSecondaryContainer: AppColors.driverAccent,
      tertiary: const Color(0xFF80CBC4),
      onTertiary: AppColors.driverBackground,
      tertiaryContainer: const Color(0xFF00695C),
      onTertiaryContainer: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: const Color(0xFF93000A),
      onErrorContainer: const Color(0xFFFFDAD6),
      surface: AppColors.driverSurface,
      onSurface: AppColors.driverOnSurface,
      onSurfaceVariant: AppColors.driverOnSurfaceVariant,
      outline: const Color(0xFF5A6580),
      outlineVariant: const Color(0xFF2E3D55),
      inverseSurface: AppColors.driverOnSurface,
      onInverseSurface: AppColors.driverBackground,
      inversePrimary: AppColors.driverPrimary,
      surfaceTint: AppColors.driverPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.driverBackground,

      // ─── Typography (same font strategy, driver colours) ──────────────────
      textTheme: TextTheme(
        displayLarge: _display(57, FontWeight.w700, spacing: -1.14),
        displayMedium: _display(45, FontWeight.w700, spacing: -0.9),
        displaySmall: _display(36, FontWeight.w700, spacing: -0.72),
        headlineLarge: _display(32, FontWeight.w600, spacing: -0.5),
        headlineMedium: _display(28, FontWeight.w600, spacing: -0.3),
        headlineSmall: _display(24, FontWeight.w600),
        titleLarge: _body(22, FontWeight.w600),
        titleMedium: _body(16, FontWeight.w600, spacing: 0.15),
        titleSmall: _body(14, FontWeight.w500, spacing: 0.1),
        bodyLarge: _body(16, FontWeight.w400, spacing: 0.15),
        bodyMedium: _body(14, FontWeight.w400, spacing: 0.25),
        bodySmall: _body(
          12,
          FontWeight.w400,
          spacing: 0.4,
          color: AppColors.driverOnSurfaceVariant,
        ),
        labelLarge: _body(14, FontWeight.w600, spacing: 0.1),
        labelMedium: _body(
          12,
          FontWeight.w500,
          spacing: 0.5,
          color: AppColors.driverOnSurfaceVariant,
        ),
        labelSmall: _body(
          11,
          FontWeight.w500,
          spacing: 0.5,
          color: AppColors.driverOnSurfaceVariant,
        ),
      ),

      // ─── Input Fields ──────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.driverSurfaceHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.driverPrimary, width: 2),
        ),
        hintStyle: _body(14, FontWeight.w400, color: AppColors.driverOnSurfaceVariant),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),

      // ─── Elevated Button ───────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.driverPrimary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
          textStyle: _body(16, FontWeight.w600, spacing: 0.1),
          elevation: 0,
        ),
      ),

      // ─── AppBar ───────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.driverBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: _display(20, FontWeight.w600),
        iconTheme: const IconThemeData(color: AppColors.driverOnSurface),
      ),

      // ─── Card ─────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.driverSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: EdgeInsets.zero,
      ),

      // ─── Chip ─────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.driverSurfaceHigh,
        selectedColor: AppColors.driverPrimary.withOpacity(0.3),
        labelStyle: _body(13, FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // ─── Dividers ─────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: Colors.transparent,
        thickness: 0,
      ),
    );
  }
}

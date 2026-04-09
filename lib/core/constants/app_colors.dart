import 'package:flutter/material.dart';

/// Urban Organicism Design System — Color Tokens
/// Extracted from Stitch "SmartClean City Signup UI" project
class AppColors {
  AppColors._();

  // ─── Primary (Botanical Green) ───────────────────────────────────────────
  static const Color primary = Color(0xFF00450D);
  static const Color primaryContainer = Color(0xFF1C5E21);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryFixed = Color(0xFFADF4A5);
  static const Color primaryFixedDim = Color(0xFF92D78C);
  static const Color inversePrimary = Color(0xFF92D78C);

  // ─── Secondary ───────────────────────────────────────────────────────────
  static const Color secondary = Color(0xFF526350);
  static const Color secondaryContainer = Color(0xFFD2E5CD);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF101F10);

  // ─── Tertiary (Teal) ─────────────────────────────────────────────────────
  static const Color tertiary = Color(0xFF104146);
  static const Color tertiaryContainer = Color(0xFF2B585E);
  static const Color onTertiary = Color(0xFFFFFFFF);

  // ─── Background & Surfaces ───────────────────────────────────────────────
  static const Color background = Color(0xFFF6FAF6);
  static const Color surface = Color(0xFFF6FAF6);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF1F5F1);
  static const Color surfaceContainer = Color(0xFFEBEFEB);
  static const Color surfaceContainerHigh = Color(0xFFE5E9E5);
  static const Color surfaceContainerHighest = Color(0xFFDFE3E0);
  static const Color surfaceDim = Color(0xFFD7DBD7);
  static const Color surfaceTint = Color(0xFF2B6B2D);
  static const Color inverseSurface = Color(0xFF2D312F);
  static const Color inverseOnSurface = Color(0xFFEEF2EE);

  // ─── On colors ───────────────────────────────────────────────────────────
  static const Color onSurface = Color(0xFF181D1A);
  static const Color onSurfaceVariant = Color(0xFF41493E);
  static const Color onBackground = Color(0xFF181D1A);

  // ─── Outline ─────────────────────────────────────────────────────────────
  static const Color outline = Color(0xFF717A6D);
  static const Color outlineVariant = Color(0xFFC0C9BB);

  // ─── Error ───────────────────────────────────────────────────────────────
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);

  // ─── Status Colors (for report chips) ────────────────────────────────────
  static const Color statusPendingAi = Color(0xFF795548);
  static const Color statusPendingAdmin = Color(0xFFE65100);
  static const Color statusAssigned = Color(0xFF1565C0);
  static const Color statusInProgress = Color(0xFF6A1B9A);
  static const Color statusCompleted = Color(0xFF00450D);
  static const Color statusRejected = Color(0xFFBA1A1A);

  // ─── Gradients ───────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryContainer],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primary, primaryContainer],
  );

  // ─── Botanical Shadow helper ──────────────────────────────────────────────
  /// Use this as the single elevation shadow across the app
  static List<BoxShadow> get botanicalShadow => [
        BoxShadow(
          color: const Color(0xFF002204).withOpacity(0.08),
          blurRadius: 40,
          offset: const Offset(0, 12),
        ),
      ];
}

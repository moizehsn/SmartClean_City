import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_localizations.dart';

class ConfidentialiteScreen extends StatelessWidget {
  const ConfidentialiteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l.t('confidentialite'),
          style: (l.isArabic ? GoogleFonts.tajawal() : GoogleFonts.manrope()).copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.onSurface),
      ),
      body: Center(
        child: Text(
          l.isArabic ? 'قريباً...' : 'Bientôt disponible...',
          style: (l.isArabic ? GoogleFonts.cairo() : GoogleFonts.plusJakartaSans()).copyWith(
            fontSize: 18,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

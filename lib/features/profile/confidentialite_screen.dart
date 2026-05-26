import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_localizations.dart';

class ConfidentialiteScreen extends StatelessWidget {
  const ConfidentialiteScreen({super.key, this.isDriver = false});

  final bool isDriver;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    // Dynamic Fonts based on Language
    TextStyle dFont(double s, FontWeight w, {Color? c}) =>
        l.isArabic
            ? GoogleFonts.tajawal(fontSize: s, fontWeight: w, color: c ?? AppColors.onSurface)
            : GoogleFonts.manrope(fontSize: s, fontWeight: w, color: c ?? AppColors.onSurface);

    TextStyle bFont(double s, FontWeight w, {Color? c, double? h}) =>
        l.isArabic
            ? GoogleFonts.cairo(fontSize: s, fontWeight: w, color: c ?? AppColors.onSurface, height: h)
            : GoogleFonts.plusJakartaSans(fontSize: s, fontWeight: w, color: c ?? AppColors.onSurface, height: h);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l.t('confidentialite'),
          style: dFont(18, FontWeight.bold, c: AppColors.onSurface),
        ),
        centerTitle: true,
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.onSurface),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Shield Icon ─────────────────────────────────
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    color: AppColors.primary,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Title ──────────────────────────────────────────────
              Center(
                child: Text(
                  l.t('confidentialite_titre'),
                  style: dFont(22, FontWeight.w700, c: AppColors.primary),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),

              // ── Introduction ───────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppColors.botanicalShadow,
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                ),
                child: Text(
                  l.t('confidentialite_intro'),
                  style: bFont(14, FontWeight.w500, c: AppColors.onSurfaceVariant, h: 1.5),
                  textAlign: TextAlign.justify,
                ),
              ),
              const SizedBox(height: 24),

              // ── Section 1: GPS ─────────────────────────────────────
              _buildSectionCard(
                title: l.t('confidentialite_gps_titre'),
                description: l.t('confidentialite_gps_desc'),
                icon: Icons.location_on_rounded,
                color: AppColors.statusAssigned,
                dFont: dFont,
                bFont: bFont,
              ),
              const SizedBox(height: 16),

              // ── Section 2: Camera ──────────────────────────────────
              _buildSectionCard(
                title: l.t('confidentialite_camera_titre'),
                description: l.t('confidentialite_camera_desc'),
                icon: Icons.camera_alt_rounded,
                color: AppColors.statusInProgress,
                dFont: dFont,
                bFont: bFont,
              ),
              const SizedBox(height: 16),

              // ── Section 3: Data Sharing ────────────────────────────
              _buildSectionCard(
                title: l.t('confidentialite_partage_titre'),
                description: l.t('confidentialite_partage_desc'),
                icon: Icons.gpp_good_rounded,
                color: AppColors.primary,
                dFont: dFont,
                bFont: bFont,
              ),
              const SizedBox(height: 16),

              // ── Section 4: Conduct & Charte (Role-Specific) ────────
              _buildSectionCard(
                title: l.t('confidentialite_charte_titre'),
                description: isDriver
                    ? l.t('confidentialite_charte_chauffeur')
                    : l.t('confidentialite_charte_citoyen'),
                icon: Icons.gavel_rounded,
                color: isDriver ? AppColors.driverPrimary : AppColors.error,
                dFont: dFont,
                bFont: bFont,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required TextStyle Function(double, FontWeight, {Color? c}) dFont,
    required TextStyle Function(double, FontWeight, {Color? c, double? h}) bFont,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.botanicalShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: dFont(16, FontWeight.w700, c: AppColors.onSurface),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: bFont(13, FontWeight.w400, c: AppColors.onSurfaceVariant, h: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

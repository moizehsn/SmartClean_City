import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_localizations.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isAr = l.isArabic;

    // Dynamic Fonts based on Language
    TextStyle dFont(double s, FontWeight w, {Color? c}) =>
        isAr
            ? GoogleFonts.tajawal(fontSize: s, fontWeight: w, color: c ?? AppColors.onSurface)
            : GoogleFonts.manrope(fontSize: s, fontWeight: w, color: c ?? AppColors.onSurface);

    TextStyle bFont(double s, FontWeight w, {Color? c, double? h}) =>
        isAr
            ? GoogleFonts.cairo(fontSize: s, fontWeight: w, color: c ?? AppColors.onSurface, height: h)
            : GoogleFonts.plusJakartaSans(fontSize: s, fontWeight: w, color: c ?? AppColors.onSurface, height: h);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isAr ? 'حول التطبيق' : 'À propos',
          style: dFont(18, FontWeight.bold, c: AppColors.onSurface),
        ),
        centerTitle: true,
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.onSurface),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Centered Logo ──────────────────────────────────────
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.eco_rounded,
                    color: AppColors.primary,
                    size: 64,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── App Name & Version ─────────────────────────────────
              Center(
                child: Text(
                  'SmartClean City',
                  style: dFont(26, FontWeight.w800, c: AppColors.primary),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  'Version 1.0.0',
                  style: bFont(13, FontWeight.w500, c: AppColors.onSurfaceVariant),
                ),
              ),
              const SizedBox(height: 24),
              
              const Divider(thickness: 1, color: AppColors.outlineVariant),
              const SizedBox(height: 24),

              // ── Graduation Project Section ──────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppColors.botanicalShadow,
                ),
                child: Column(
                  children: [
                    Text(
                      isAr ? 'مشروع التخرج' : "Projet de Fin d'Études",
                      style: dFont(18, FontWeight.w700, c: AppColors.primary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isAr 
                          ? 'نظام ذكي للنظافة الحضرية وجمع البلاغات' 
                          : 'Système intelligent de gestion de la propreté urbaine et collecte de signalements',
                      style: bFont(13, FontWeight.w500, c: AppColors.onSurfaceVariant, h: 1.4),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Development Team Section ───────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppColors.botanicalShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      isAr ? 'فريق التطوير' : 'Équipe de Développement',
                      style: dFont(16, FontWeight.w700, c: AppColors.onSurface),
                    ),
                    const SizedBox(height: 14),
                    _buildNameRow(name: 'Mohamed Dib', role: isAr ? 'مطور' : 'Développeur', bFont: bFont),
                    const SizedBox(height: 10),
                    _buildNameRow(name: 'Abdelmoize Hassani', role: isAr ? 'مطور' : 'Développeur', bFont: bFont),
                    const SizedBox(height: 10),
                    _buildNameRow(name: 'Haitham Saidi', role: isAr ? 'مطور' : 'Développeur', bFont: bFont),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Supervision Section ────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppColors.botanicalShadow,
                ),
                child: Column(
                  children: [
                    Text(
                      isAr ? 'تحت إشراف' : 'Encadré par',
                      style: dFont(16, FontWeight.w700, c: AppColors.onSurface),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Dr. Mohamed El Amine Ameur',
                      style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Footer ─────────────────────────────────────────────
              Center(
                child: Text(
                  'Année Universitaire 2025 / 2026',
                  style: bFont(12, FontWeight.w500, c: AppColors.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  'Université Amar Telidji de Laghouat',
                  style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameRow({
    required String name,
    required String role,
    required TextStyle Function(double, FontWeight, {Color? c, double? h}) bFont,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          name,
          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            role,
            style: bFont(11, FontWeight.w600, c: AppColors.primary),
          ),
        ),
      ],
    );
  }
}

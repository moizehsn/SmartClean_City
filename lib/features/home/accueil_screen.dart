import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/mock/mock_data.dart';
import '../../shared/widgets/glass_container.dart';
import '../../shared/widgets/report_status_chip.dart';
import '../reports/detail_signalement_screen.dart';

/// Home tab — body only, no Scaffold with bottom nav or FAB.
/// The Scaffold, bottom nav, and FAB are all owned by MainShell.
class AccueilScreen extends StatelessWidget {
  const AccueilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // ── Green gradient header background ────────────────────────
        Container(
          height: size.height * 0.30,
          decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        ),

        SafeArea(
          child: CustomScrollView(
            slivers: [
              // ── Greeting header ──────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bonjour,',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 14, color: Colors.white70),
                          ),
                          Text(
                            MockUser.nom,
                            style: GoogleFonts.manrope(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.notifications_outlined,
                            color: Colors.white, size: 22),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Stats glass card ─────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: GlassContainer(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Aperçu en temps réel',
                          style: GoogleFonts.manrope(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _StatBox(
                              label: 'En cours',
                              value: '3',
                              color: AppColors.statusInProgress,
                            ),
                            const SizedBox(width: 12),
                            _StatBox(
                              label: 'Acceptés',
                              value: '${MockUser.acceptes}',
                              color: AppColors.statusAssigned,
                            ),
                            const SizedBox(width: 12),
                            _StatBox(
                              label: 'Résolus',
                              value: '${MockUser.resolus}',
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Recent reports title ─────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Signalements récents',
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                          letterSpacing: -0.3,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'Voir tout',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Report cards ─────────────────────────────────────
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final r = kMockReports[i];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                      child: _ReportCard(
                        report: r,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DetailSignalementScreen(report: r),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: kMockReports.take(3).length,
                ),
              ),

              // Bottom padding for floating nav bar
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.manrope(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report, required this.onTap});
  final MockReport report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.botanicalShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryFixed.withOpacity(0.4),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.titre,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${report.adresse} • ${report.dateHeure}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ReportStatusChip(status: report.statut),
          ],
        ),
      ),
    );
  }
}

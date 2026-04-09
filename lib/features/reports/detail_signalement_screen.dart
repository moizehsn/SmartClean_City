import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/mock/mock_data.dart';
import '../../shared/widgets/glass_container.dart';
import '../../shared/widgets/report_status_chip.dart';

class DetailSignalementScreen extends StatelessWidget {
  const DetailSignalementScreen({super.key, required this.report});
  final MockReport report;

  static const _timelineSteps = [
    ('Signalement reçu', 'Le 24 Oct, 09:12', true),
    ('Vérification IA', 'Analyse terminée à 09:14', true),
    ("Assigné à l'équipe", 'Équipe Verte Nord en route', true),
    ('Nettoyage effectué', 'Attente confirmation visuelle', false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(report.id,
            style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface)),
        leading: const BackButton(color: AppColors.onSurface),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + status
            Text(report.titre,
                style: GoogleFonts.manrope(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                    letterSpacing: -0.3)),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 14, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(report.adresse,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, color: AppColors.onSurfaceVariant)),
                const SizedBox(width: 12),
                ReportStatusChip(status: report.statut),
              ],
            ),
            const SizedBox(height: 24),

            // Mock image placeholder
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_outlined,
                        size: 48, color: AppColors.onSurfaceVariant),
                    const SizedBox(height: 8),
                    Text('Photo du signalement',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Timeline
            _SectionLabel(label: 'Suivi de l\'intervention'),
            const SizedBox(height: 12),
            GlassContainer(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: List.generate(_timelineSteps.length, (i) {
                  final (title, sub, done) = _timelineSteps[i];
                  final isLast = i == _timelineSteps.length - 1;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: done
                                  ? AppColors.primary
                                  : AppColors.surfaceContainerHigh,
                            ),
                            child: Icon(
                              done
                                  ? Icons.check_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              size: 16,
                              color:
                                  done ? Colors.white : AppColors.onSurfaceVariant,
                            ),
                          ),
                          if (!isLast)
                            Container(
                              width: 2,
                              height: 40,
                              color: done
                                  ? AppColors.primaryFixed
                                  : AppColors.surfaceContainerHigh,
                            ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title,
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: done
                                          ? AppColors.onSurface
                                          : AppColors.onSurfaceVariant)),
                              const SizedBox(height: 2),
                              Text(sub,
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: AppColors.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
            const SizedBox(height: 20),

            // Location
            _SectionLabel(label: 'Localisation'),
            const SizedBox(height: 12),
            _InfoCard(children: [
              _InfoRow(icon: Icons.location_city_rounded, text: report.adresse),
              _InfoRow(icon: Icons.map_outlined, text: report.ville),
            ]),
            const SizedBox(height: 20),

            // Waste type
            _SectionLabel(label: 'Type de déchet'),
            const SizedBox(height: 12),
            _InfoCard(children: [
              _InfoRow(
                  icon: Icons.delete_outline_rounded, text: report.typeDechet),
            ]),
            const SizedBox(height: 20),

            // AI analysis
            _SectionLabel(label: 'Analyse IA'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryFixed.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.psychology_outlined,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(report.aiAnalyse,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: AppColors.onSurface,
                            height: 1.5)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface));
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.botanicalShadow,
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14, color: AppColors.onSurface)),
          ),
        ],
      ),
    );
  }
}

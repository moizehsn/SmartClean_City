import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/mock/mock_data.dart';
import '../../shared/widgets/report_status_chip.dart';
import 'detail_signalement_screen.dart';
import 'nouveau_signalement_screen.dart';

class MesSignalementsScreen extends StatefulWidget {
  const MesSignalementsScreen({super.key});

  @override
  State<MesSignalementsScreen> createState() => _MesSignalementsScreenState();
}

class _MesSignalementsScreenState extends State<MesSignalementsScreen> {
  int _filterIndex = 0;
  final _filters = ['Tous', 'En cours', 'Terminés', 'Rejetés'];

  List<MockReport> get _filtered {
    switch (_filterIndex) {
      case 1:
        return kMockReports
            .where((r) =>
                r.statut == ReportStatus.inProgress ||
                r.statut == ReportStatus.assigned ||
                r.statut == ReportStatus.pendingAdmin)
            .toList();
      case 2:
        return kMockReports
            .where((r) => r.statut == ReportStatus.completed)
            .toList();
      case 3:
        return kMockReports
            .where((r) => r.statut == ReportStatus.rejected)
            .toList();
      default:
        return kMockReports;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Mes Signalements',
            style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const NouveauSignalementScreen()),
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          // Filter chips
          SizedBox(
            height: 48,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              itemBuilder: (_, i) {
                final active = i == _filterIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _filterIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.primary
                            : AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(_filters[i],
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: active
                                  ? Colors.white
                                  : AppColors.onSurfaceVariant)),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // List
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Text('Aucun signalement.',
                        style: GoogleFonts.plusJakartaSans(
                            color: AppColors.onSurfaceVariant)))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final r = _filtered[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _SignalementCard(
                          report: r,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  DetailSignalementScreen(report: r),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SignalementCard extends StatelessWidget {
  const _SignalementCard({required this.report, required this.onTap});
  final MockReport report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.botanicalShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 6,
            color: report.statut.foregroundColor,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(report.titre,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface)),
                    ),
                    ReportStatusChip(status: report.statut),
                  ],
                ),
                const SizedBox(height: 5),
                Text(report.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(report.adresse,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant)),
                    const Spacer(),
                    GestureDetector(
                      onTap: onTap,
                      child: Row(
                        children: [
                          Text('Voir détails',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary)),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_rounded,
                              size: 14, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

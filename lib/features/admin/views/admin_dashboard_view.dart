import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../core/constants/app_colors.dart';

/// Admin Dashboard — KPI overview + recent reports table
class AdminDashboardView extends StatelessWidget {
  const AdminDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('signalements')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, sigSnap) {
        final allDocs = sigSnap.data?.docs ?? [];
        final total = allDocs.length;
        final enAttente =
            allDocs.where((d) => (d.data() as Map)['statut'] == 'en attente').length;
        final enCours =
            allDocs.where((d) => (d.data() as Map)['statut'] == 'en cours').length;
        final enVerification =
            allDocs.where((d) => (d.data() as Map)['statut'] == 'en vérification').length;
        final termines =
            allDocs.where((d) => (d.data() as Map)['statut'] == 'terminé').length;
        final recent = allDocs.take(8).toList();

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('citoyens').snapshots(),
          builder: (context, usersSnap) {
            final allUsers = usersSnap.data?.docs ?? [];
            final citoyens =
                allUsers.where((d) => (d.data() as Map)['role'] == 'citoyen').length;
            final chauffeurs =
                allUsers.where((d) => (d.data() as Map)['role'] == 'chauffeur').length;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title ────────────────────────────────────────
                  Text(
                    isAr ? 'نظرة عامة' : 'Vue d\'ensemble',
                    style: GoogleFonts.manrope(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isAr ? 'متابعة فورية لنظافة المدينة' : 'Suivi en temps réel de la propreté urbaine',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── KPI Row 1: Report stats ──────────────────────
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _KpiCard(
                        label: isAr ? 'إجمالي البلاغات' : 'Total Signalements',
                        value: '$total',
                        icon: Icons.assignment_rounded,
                        color: AppColors.primary,
                      ),
                      _KpiCard(
                        label: isAr ? 'قيد الانتظار' : 'En Attente',
                        value: '$enAttente',
                        icon: Icons.hourglass_empty_rounded,
                        color: AppColors.statusPendingAdmin,
                      ),
                      _KpiCard(
                        label: isAr ? 'قيد المعالجة' : 'En Cours',
                        value: '$enCours',
                        icon: Icons.loop_rounded,
                        color: AppColors.statusInProgress,
                      ),
                      _KpiCard(
                        label: isAr ? 'قيد المراجعة' : 'En Vérification',
                        value: '$enVerification',
                        icon: Icons.pending_outlined,
                        color: AppColors.statusVerification,
                      ),
                      _KpiCard(
                        label: isAr ? 'منتهية' : 'Terminés',
                        value: '$termines',
                        icon: Icons.check_circle_outline_rounded,
                        color: AppColors.statusCompleted,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── KPI Row 2: Users ────────────────────────────
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _KpiCard(
                        label: isAr ? 'المواطنون المسجلون' : 'Citoyens Inscrits',
                        value: '$citoyens',
                        icon: Icons.people_rounded,
                        color: AppColors.statusAssigned,
                      ),
                      _KpiCard(
                        label: isAr ? 'السائقون النشطون' : 'Chauffeurs Actifs',
                        value: '$chauffeurs',
                        icon: Icons.local_shipping_rounded,
                        color: AppColors.tertiary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // ── Visual Analytics (fl_chart) ──────────────────
                  Text(
                    isAr ? 'تحليل البلاغات' : 'Analyse des Signalements',
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    height: 250,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppColors.botanicalShadow,
                    ),
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: (total > 0 ? total.toDouble() : 10) * 1.2,
                        barTouchData: BarTouchData(enabled: false),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (double value, TitleMeta meta) {
                                final style = GoogleFonts.plusJakartaSans(
                                  color: AppColors.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                );
                                String text;
                                switch (value.toInt()) {
                                  case 0:
                                    text = isAr ? 'انتظار' : 'Attente';
                                    break;
                                  case 1:
                                    text = isAr ? 'جاري' : 'En cours';
                                    break;
                                  case 2:
                                    text = isAr ? 'مراجعة' : 'Vérif.';
                                    break;
                                  case 3:
                                    text = isAr ? 'منتهي' : 'Terminés';
                                    break;
                                  default:
                                    text = '';
                                    break;
                                }
                                return SideTitleWidget(
                                  meta: meta,
                                  space: 8,
                                  child: Text(text, style: style),
                                );
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: const FlGridData(show: false),
                        barGroups: [
                          BarChartGroupData(
                            x: 0,
                            barRods: [
                              BarChartRodData(
                                toY: enAttente.toDouble(),
                                color: AppColors.statusPendingAdmin,
                                width: 28,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ],
                          ),
                          BarChartGroupData(
                            x: 1,
                            barRods: [
                              BarChartRodData(
                                toY: enCours.toDouble(),
                                color: AppColors.statusInProgress,
                                width: 28,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ],
                          ),
                          BarChartGroupData(
                            x: 2,
                            barRods: [
                              BarChartRodData(
                                toY: enVerification.toDouble(),
                                color: AppColors.statusVerification,
                                width: 28,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ],
                          ),
                          BarChartGroupData(
                            x: 3,
                            barRods: [
                              BarChartRodData(
                                toY: termines.toDouble(),
                                color: AppColors.statusCompleted,
                                width: 28,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Recent Reports ──────────────────────────────
                  Text(
                    isAr ? 'آخر البلاغات' : 'Signalements Récents',
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppColors.botanicalShadow,
                    ),
                    child: sigSnap.connectionState == ConnectionState.waiting
                        ? const Padding(
                            padding: EdgeInsets.all(40),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            ),
                          )
                        : recent.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(40),
                                child: Center(
                                  child: Text(
                                    isAr ? 'لا توجد بلاغات' : 'Aucun signalement',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(
                                    AppColors.surfaceContainerLow,
                                  ),
                                  columnSpacing: 28,
                                  columns: [
                                    DataColumn(
                                      label: Text('ID', style: _headerStyle()),
                                    ),
                                    DataColumn(
                                      label: Text(isAr ? 'العنوان' : 'Adresse', style: _headerStyle()),
                                    ),
                                    DataColumn(
                                      label: Text(isAr ? 'الحالة' : 'Statut', style: _headerStyle()),
                                    ),
                                    DataColumn(
                                      label: Text(isAr ? 'التاريخ' : 'Date', style: _headerStyle()),
                                    ),
                                  ],
                                  rows: recent.map((doc) {
                                    final d =
                                        doc.data() as Map<String, dynamic>;
                                    final statut =
                                        d['statut'] as String? ?? 'en attente';
                                    final addr =
                                        d['adresse_lisible'] as String? ?? '';
                                    final ts =
                                        (d['timestamp'] as Timestamp?)
                                            ?.toDate();
                                    return DataRow(cells: [
                                      DataCell(Text(
                                        d['id_court'] ?? '#????',
                                        style: GoogleFonts.manrope(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          color: AppColors.primary,
                                        ),
                                      )),
                                      DataCell(Text(
                                        addr.length > 45
                                            ? '${addr.substring(0, 45)}…'
                                            : addr,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          color: AppColors.onSurface,
                                        ),
                                      )),
                                      DataCell(_StatusBadge(statut: statut, isAr: isAr)),
                                      DataCell(Text(
                                        ts != null
                                            ? DateFormat('dd/MM/yyyy – HH:mm')
                                                .format(ts)
                                            : '—',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                      )),
                                    ]);
                                  }).toList(),
                                ),
                              ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static TextStyle _headerStyle() => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.onSurfaceVariant,
      );
}

// ── KPI Card ──────────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label, value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.botanicalShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.manrope(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
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

// ── Status Badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.statut, this.isAr = false});
  final String statut;
  final bool isAr;

  Color get _color {
    switch (statut) {
      case 'en attente':
        return AppColors.statusPendingAdmin;
      case 'en cours':
        return AppColors.statusInProgress;
      case 'en vérification':
        return AppColors.statusVerification;
      case 'terminé':
        return AppColors.statusCompleted;
      case 'rejeté':
        return AppColors.statusRejected;
      default:
        return AppColors.onSurfaceVariant;
    }
  }

  String get _label {
    switch (statut) {
      case 'en attente':
        return isAr ? 'انتظار' : 'En attente';
      case 'en cours':
        return isAr ? 'جاري' : 'En cours';
      case 'en vérification':
        return isAr ? 'مراجعة' : 'Vérification';
      case 'terminé':
        return isAr ? 'منتهي' : 'Terminé';
      case 'rejeté':
        return isAr ? 'مرفوض' : 'Rejeté';
      default:
        return statut;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        _label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _color,
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/firestore/signalement_model.dart';
import '../../shared/mock/mock_data.dart';
import '../../shared/widgets/glass_container.dart';
import '../reports/detail_signalement_screen.dart';

/// Home tab — body only, no Scaffold with bottom nav or FAB.
/// The Scaffold, bottom nav, and FAB are all owned by MainShell.
class AccueilScreen extends StatelessWidget {
  const AccueilScreen({super.key});

  // ── Firestore query: all my reports, newest first ──────────────────────────
  Stream<List<Signalement>> get _myReportsStream {
    return FirebaseFirestore.instance
        .collection('signalements')
        .where('citoyen_id', isEqualTo: 'user_mock')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Signalement.fromFirestore).toList());
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // ── Green gradient header background ────────────────────────────────
        Container(
          height: size.height * 0.30,
          decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        ),

        SafeArea(
          child: StreamBuilder<List<Signalement>>(
            stream: _myReportsStream,
            builder: (context, snapshot) {
              // derive counts for stats section
              final List<Signalement> reports = snapshot.data ?? [];
              final int enCours =
                  reports.where((r) => r.statut == 'en cours').length;
              final int acceptes =
                  reports.where((r) => r.statut == 'en attente').length;
              final int resolus =
                  reports.where((r) => r.statut == 'terminé').length;
              final recent = reports.take(3).toList();

              return CustomScrollView(
                slivers: [
                  // ── Greeting header ────────────────────────────────────────
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

                  // ── Stats glass card ───────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                      child: GlassContainer(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Aperçu en temps réel',
                                  style: GoogleFonts.manrope(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                                const Spacer(),
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting)
                                  const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _StatBox(
                                  label: 'En cours',
                                  value: '$enCours',
                                  color: AppColors.statusInProgress, // Purple
                                ),
                                const SizedBox(width: 12),
                                _StatBox(
                                  label: 'Acceptés',
                                  value: '$acceptes',
                                  color: AppColors.statusAssigned, // Blue
                                ),
                                const SizedBox(width: 12),
                                _StatBox(
                                  label: 'Résolus',
                                  value: '$resolus',
                                  color: AppColors.primary, // Green
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Recent reports title ───────────────────────────────────
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

                  // ── Report cards / empty / loading ─────────────────────────
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      reports.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary),
                        ),
                      ),
                    )
                  else if (snapshot.hasError)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                        child: _ErrorCard(error: snapshot.error),
                      ),
                    )
                  else if (recent.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                        child: _EmptyState(
                          icon: Icons.inbox_rounded,
                          message:
                              'Aucun signalement pour l\'instant.\nAppuyez sur + pour en créer un.',
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                          final s = recent[i];
                          return Padding(
                            padding:
                                const EdgeInsets.fromLTRB(24, 0, 24, 12),
                            child: _ReportCard(
                              signalement: s,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      SignalementDetailScreen(signalement: s),
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: recent.length,
                      ),
                    ),

                  // Bottom padding for floating nav bar
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              );
            },
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
  const _ReportCard({required this.signalement, required this.onTap});
  final Signalement signalement;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Try to decode the thumbnail for a small preview
    Widget leadingWidget;
    if (signalement.photoBase64.isNotEmpty) {
      try {
        final bytes = base64Decode(signalement.photoBase64);
        leadingWidget = ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.memory(bytes, width: 44, height: 44, fit: BoxFit.cover),
        );
      } catch (_) {
        leadingWidget = _trashIcon();
      }
    } else {
      leadingWidget = _trashIcon();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(25),
          boxShadow: AppColors.botanicalShadow,
        ),
        child: Row(
          children: [
            leadingWidget,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    signalement.titre,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${signalement.adresseLisible} • ${signalement.relativeTime}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FirestoreStatusBadge(signalement: signalement),
          ],
        ),
      ),
    );
  }

  Widget _trashIcon() => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.primaryFixed.withOpacity(0.4),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppColors.primary, size: 22),
      );
}

// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(25),
        boxShadow: AppColors.botanicalShadow,
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppColors.onSurfaceVariant,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Debug error card — shows the raw Firestore error string as SelectableText
/// so the Firebase Console index URL can be long-pressed and copied directly.
class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.error});
  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0), // amber-50
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFB300), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFE65100), size: 20),
              const SizedBox(width: 8),
              Text(
                'Erreur Firestore — copiez le lien ci-dessous',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFE65100),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SelectableText(
            error?.toString() ?? 'Erreur inconnue',
            style: GoogleFonts.robotoMono(
              fontSize: 11,
              color: const Color(0xFF3E2723),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

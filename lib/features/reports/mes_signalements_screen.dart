import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/firestore/signalement_model.dart';
import 'detail_signalement_screen.dart';
import 'nouveau_signalement_screen.dart';

class MesSignalementsScreen extends StatefulWidget {
  const MesSignalementsScreen({super.key});

  @override
  State<MesSignalementsScreen> createState() => _MesSignalementsScreenState();
}

class _MesSignalementsScreenState extends State<MesSignalementsScreen> {
  int _filterIndex = 0;

  // ── Filter pills ──────────────────────────────────────────────────────────
  static const _filters = ['Tous', 'En cours', 'Terminés', 'Rejetés'];

  // Maps pill index → Firestore statut value (null = Tous = no filter)
  static const _statutMap = <int, String?>{
    0: null,
    1: 'en cours',
    2: 'terminé',
    3: 'rejeté',
  };

  // ── Live query ────────────────────────────────────────────────────────────
  Stream<List<Signalement>> get _stream {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('signalements')
        .where('citoyen_id', isEqualTo: 'user_mock')
        .orderBy('timestamp', descending: true);

    final statut = _statutMap[_filterIndex];
    if (statut != null) {
      query = query.where('statut', isEqualTo: statut);
    }

    return query.snapshots().map(
          (snap) => snap.docs.map(Signalement.fromFirestore).toList(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Mes Signalements',
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
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
          // ── Filter pills ─────────────────────────────────────────────────
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
                      child: Text(
                        _filters[i],
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: active
                              ? Colors.white
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // ── Live list ────────────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<Signalement>>(
              stream: _stream,
              builder: (context, snapshot) {
                // Loading
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                // Error — show full Firestore error so the index URL can be copied
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: _FirestoreErrorCard(error: snapshot.error),
                    ),
                  );
                }

                final reports = snapshot.data ?? [];

                // Empty state
                if (reports.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inbox_rounded,
                            size: 56,
                            color: AppColors.onSurfaceVariant.withOpacity(0.4),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Aucun signalement',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _filterIndex == 0
                                ? 'Appuyez sur + pour créer votre premier signalement.'
                                : 'Aucun signalement dans cette catégorie.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: AppColors.onSurfaceVariant,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // List
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
                  itemCount: reports.length,
                  itemBuilder: (_, i) {
                    final s = reports[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SignalementCard(
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SignalementCard extends StatelessWidget {
  const _SignalementCard({required this.signalement, required this.onTap});
  final Signalement signalement;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(25),
        boxShadow: AppColors.botanicalShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Coloured top border matching status ──────────────────────────
          Container(
            height: 5,
            color: signalement.borderColor,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        signalement.idCourt,
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    FirestoreStatusBadge(signalement: signalement),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  signalement.titre,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rapport citoyen automatique',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                // Footer
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        signalement.adresseLisible,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onTap,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Voir détails',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
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

// ─────────────────────────────────────────────────────────────────────────────

/// Debug error card — shows the raw Firestore error string as SelectableText
/// so the Firebase Console index URL can be long-pressed and copied directly.
class _FirestoreErrorCard extends StatelessWidget {
  const _FirestoreErrorCard({required this.error});
  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
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
              Expanded(
                child: Text(
                  'Erreur Firestore — copiez le lien ci-dessous',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFE65100),
                  ),
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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/glass_container.dart';

/// Driver dashboard — greeting header + 3 interactive filter stat cards +
/// a real-time mission list that re-filters when a stat card is tapped.
class DriverDashboard extends StatefulWidget {
  const DriverDashboard({
    super.key,
    required this.onNavigateToMap,
    required this.focusTarget,
  });

  final VoidCallback onNavigateToMap;
  final ValueNotifier<LatLng?> focusTarget;

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  /// Active filter used by the bottom mission list.
  String _currentFilter = 'en attente';

  // ── Filter metadata ────────────────────────────────────────────────────────
  static const _filters = [
    (statut: 'en attente', label: 'Nouveaux',  color: AppColors.statusPendingAdmin),
    (statut: 'en cours',   label: 'En cours',  color: AppColors.statusInProgress),
    (statut: 'terminé',    label: 'Terminés',  color: AppColors.statusCompleted),
  ];

  // ── Helpers ────────────────────────────────────────────────────────────────

  String get _sectionTitle {
    switch (_currentFilter) {
      case 'en cours':  return 'Missions en cours';
      case 'terminé':   return 'Missions terminées';
      default:          return 'Missions en attente';
    }
  }

  Color get _sectionColor {
    switch (_currentFilter) {
      case 'en cours': return AppColors.statusInProgress;
      case 'terminé':  return AppColors.statusCompleted;
      default:         return AppColors.statusPendingAdmin;
    }
  }

  bool get _listIsTappable => _currentFilter == 'en attente';

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // ── Green gradient header background ──────────────────────────────
        Container(
          height: size.height * 0.30,
          decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        ),

        SafeArea(
          child: CustomScrollView(
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
                          Text('Bonjour,',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14, color: Colors.white70)),
                          Text(
                            'Chauffeur',
                            style: GoogleFonts.manrope(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      // Vehicle badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(38),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: Colors.white.withAlpha(64), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_shipping_rounded,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Camion Benne',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Interactive stat filter cards ──────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: GlassContainer(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Aperçu des missions',
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(18),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Filtres actifs',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: _filters.map((f) {
                            final isSelected = _currentFilter == f.statut;
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                    right: f == _filters.last ? 0 : 10),
                                child: _FilterStatCard(
                                  label:       f.label,
                                  statut:      f.statut,
                                  color:       f.color,
                                  isSelected:  isSelected,
                                  onTap: () => setState(
                                      () => _currentFilter = f.statut),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Section title (updates with filter) ────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
                  child: Row(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Text(
                          _sectionTitle,
                          key: ValueKey(_sectionTitle),
                          style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      if (_listIsTappable) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _sectionColor.withAlpha(30),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Appuyez pour localiser',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: _sectionColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ── Filtered mission list ──────────────────────────────────
              SliverToBoxAdapter(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('signalements')
                      .where('statut', isEqualTo: _currentFilter)
                      .orderBy('timestamp', descending: true)
                      .limit(10)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 2.5,
                          ),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                        child: _FirestoreErrorCard(error: snapshot.error),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.inbox_outlined,
                                  size: 52,
                                  color: _sectionColor.withAlpha(76)),
                              const SizedBox(height: 12),
                              Text(
                                'Aucune mission "$_sectionTitle"',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  color: AppColors.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final docs = snapshot.data!.docs;
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: docs.length,
                      itemBuilder: (ctx, i) {
                        final data =
                            docs[i].data() as Map<String, dynamic>;
                        final double? lat =
                            (data['latitude'] as num?)?.toDouble();
                        final double? lng =
                            (data['longitude'] as num?)?.toDouble();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _MissionCard(
                            adresse: data['adresse_lisible'] ??
                                'Adresse inconnue',
                            timestamp: data['timestamp'] as Timestamp?,
                            statut:    _currentFilter,
                            lat:       lat,
                            lng:       lng,
                            // Only 'en attente' cards fly to map
                            onTap: (_listIsTappable &&
                                    lat != null &&
                                    lng != null)
                                ? () {
                                    widget.focusTarget.value =
                                        LatLng(lat, lng);
                                    widget.onNavigateToMap();
                                  }
                                : null,
                          ),
                        );
                      },
                    );
                  },
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

// ─── Interactive filter stat card ─────────────────────────────────────────────
class _FilterStatCard extends StatelessWidget {
  const _FilterStatCard({
    required this.label,
    required this.statut,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final String    label;
  final String    statut;
  final Color     color;
  final bool      isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('signalements')
          .where('statut', isEqualTo: statut)
          .snapshots(),
      builder: (context, snapshot) {
        final count     = snapshot.hasData ? snapshot.data!.docs.length : 0;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: isSelected
                ? color.withAlpha(28)
                : color.withAlpha(15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color:      color.withAlpha(40),
                      blurRadius: 10,
                      offset:     const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Material(
            color:        Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap:        onTap,
              splashColor:  color.withAlpha(30),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  children: [
                    isLoading
                        ? SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                                color: color, strokeWidth: 2),
                          )
                        : Text(
                            '$count',
                            style: GoogleFonts.manrope(
                              fontSize:   22,
                              fontWeight: FontWeight.w700,
                              color:      color,
                            ),
                          ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize:   11,
                        color: isSelected
                            ? color
                            : AppColors.onSurfaceVariant,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(height: 4),
                      Container(
                        width: 20, height: 3,
                        decoration: BoxDecoration(
                          color:        color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Mission Card (tappable when filter = 'en attente') ───────────────────────
class _MissionCard extends StatelessWidget {
  const _MissionCard({
    required this.adresse,
    required this.timestamp,
    required this.statut,
    required this.lat,
    required this.lng,
    required this.onTap,
  });

  final String     adresse;
  final Timestamp? timestamp;
  final String     statut;
  final double?    lat;
  final double?    lng;
  final VoidCallback? onTap;

  Color get _statusColor {
    switch (statut) {
      case 'en cours': return AppColors.statusInProgress;
      case 'terminé':  return AppColors.statusCompleted;
      default:         return AppColors.statusPendingAdmin;
    }
  }

  String get _statusLabel {
    switch (statut) {
      case 'en cours': return 'En cours';
      case 'terminé':  return 'Terminé';
      default:         return 'En attente';
    }
  }

  String _formatTime() {
    if (timestamp == null) return '';
    final dt   = timestamp!.toDate();
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours   < 24) return 'Il y a ${diff.inHours}h';
    return 'Il y a ${diff.inDays}j';
  }

  @override
  Widget build(BuildContext context) {
    final bool tappable = onTap != null;
    return Material(
      color:        Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap:        onTap,
        child: Ink(
          decoration: BoxDecoration(
            color:        AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            boxShadow:    AppColors.botanicalShadow,
            border: tappable
                ? Border.all(
                    color: AppColors.primary.withAlpha(20), width: 1)
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color:        _statusColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.location_on_outlined,
                      color: _statusColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        adresse,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize:   14,
                          fontWeight: FontWeight.w600,
                          color:      AppColors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _formatTime(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color:    AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Right badge: location icon (tappable) or status chip
                tappable
                    ? Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color:        AppColors.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.my_location_rounded,
                            color: AppColors.primary, size: 16),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color:        _statusColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          _statusLabel,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize:   11,
                            fontWeight: FontWeight.w600,
                            color:      _statusColor,
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Debug error card ─────────────────────────────────────────────────────────
class _FirestoreErrorCard extends StatelessWidget {
  const _FirestoreErrorCard({required this.error});
  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        const Color(0xFFFFF3E0),
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
                    fontSize:   13,
                    fontWeight: FontWeight.w700,
                    color:      const Color(0xFFE65100),
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
              color:    const Color(0xFF3E2723),
              height:   1.6,
            ),
          ),
        ],
      ),
    );
  }
}

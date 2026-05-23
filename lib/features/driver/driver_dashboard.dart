import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../shared/widgets/glass_container.dart';
import 'mission_detail_screen.dart';

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
  String _currentFilter = 'en attente';

  // ── Filter metadata — labels filled from context in build ─────────────────
  List<({String statut, String label, Color color})> _filters(
    AppLocalizations l,
  ) => [
    (
      statut: 'en attente',
      label: l.t('nouveaux'),
      color: AppColors.statusPendingAdmin,
    ),
    (
      statut: 'en cours',
      label: l.t('en_cours'),
      color: AppColors.statusInProgress,
    ),
    (
      statut: 'terminé',
      label: l.t('termines'),
      color: AppColors.statusCompleted,
    ),
  ];

  String _sectionTitle(AppLocalizations l) {
    switch (_currentFilter) {
      case 'en cours':
        return l.t('missions_en_cours');
      case 'terminé':
        return l.t('missions_terminees');
      default:
        return l.t('missions_en_attente');
    }
  }

  Color get _sectionColor {
    switch (_currentFilter) {
      case 'en cours':
        return AppColors.statusInProgress;
      case 'terminé':
        return AppColors.statusCompleted;
      default:
        return AppColors.statusPendingAdmin;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final l = AppLocalizations.of(context);
    final filters = _filters(l);

    return Stack(
      children: [
        Container(
          height: size.height * 0.30,
          decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        ),

        SafeArea(
          child: CustomScrollView(
            slivers: [
              // ── Greeting header ──────────────────────────────────────
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
                            l.t('bonjour'),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            l.t('chauffeur'),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(38),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withAlpha(64),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.local_shipping_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Interactive stat filter cards ────────────────────────
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
                              l.t('apercu_missions'),
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(18),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                l.t('filtres_actifs'),
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
                          children: filters.map((f) {
                            final isSelected = _currentFilter == f.statut;
                            final isLast = f == filters.last;
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsetsDirectional.only(
                                  end: isLast ? 0 : 10,
                                ),
                                child: _FilterStatCard(
                                  label: f.label,
                                  statut: f.statut,
                                  color: f.color,
                                  isSelected: isSelected,
                                  onTap: () =>
                                      setState(() => _currentFilter = f.statut),
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

              // ── Section title ────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
                  child: Row(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Text(
                          _sectionTitle(l),
                          key: ValueKey(_sectionTitle(l)),
                          style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      if (_currentFilter == 'en attente') ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _sectionColor.withAlpha(30),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Voir les détails',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: _sectionColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ] else if (_currentFilter == 'en cours') ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _sectionColor.withAlpha(30),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            l.t('appuyer_localiser'),
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

              // ── Filtered mission list ────────────────────────────────
              SliverToBoxAdapter(
                child: StreamBuilder<QuerySnapshot>(
                  stream: () {
                    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
                    Query<Map<String, dynamic>> q = FirebaseFirestore.instance
                        .collection('signalements')
                        .where('statut', isEqualTo: _currentFilter);
                    // Nouveaux tab: all pending reports city-wide.
                    // En cours / Terminé: only this driver's missions.
                    if (_currentFilter != 'en attente') {
                      q = q.where('chauffeur_id', isEqualTo: uid);
                    }
                    return q.snapshots();
                  }(),
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
                        child: _FirestoreErrorCard(error: snapshot.error, l: l),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 52,
                                color: _sectionColor.withAlpha(76),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Aucune mission « ${_sectionTitle(l)} »',
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

                    final docs = snapshot.data!.docs.toList()
                      ..sort((a, b) {
                        final ta = (a.data() as Map)['timestamp'] as Timestamp?;
                        final tb = (b.data() as Map)['timestamp'] as Timestamp?;
                        if (ta == null && tb == null) return 0;
                        if (ta == null) return 1;
                        if (tb == null) return -1;
                        return tb.compareTo(ta);
                      });
                    final limited = docs.take(10).toList();
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: limited.length,
                      itemBuilder: (ctx, i) {
                        final data = limited[i].data() as Map<String, dynamic>;
                        final double? lat = (data['latitude'] as num?)
                            ?.toDouble();
                        final double? lng = (data['longitude'] as num?)
                            ?.toDouble();

                        final docId = limited[i].id;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _MissionCard(
                            adresse:
                                data['adresse_lisible'] ?? 'Adresse inconnue',
                            timestamp: data['timestamp'] as Timestamp?,
                            statut: _currentFilter,
                            lat: lat,
                            lng: lng,
                            l: l,
                            onTap: () {
                              if (_currentFilter == 'en attente') {
                                // Navigate to detail with accept button.
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => MissionDetailScreen(
                                      docId: docId,
                                      data: data,
                                    ),
                                  ),
                                );
                              } else if (_currentFilter == 'en cours' &&
                                  lat != null && lng != null) {
                                // Focus map on active mission.
                                widget.focusTarget.value = LatLng(lat, lng);
                                widget.onNavigateToMap();
                              }
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

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

  final String label;
  final String statut;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: () {
        final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
        Query<Map<String, dynamic>> q = FirebaseFirestore.instance
            .collection('signalements')
            .where('statut', isEqualTo: statut);
        if (statut != 'en attente') {
          q = q.where('chauffeur_id', isEqualTo: uid);
        }
        return q.snapshots();
      }(),
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: isSelected ? color.withAlpha(28) : color.withAlpha(15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withAlpha(40),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              splashColor: color.withAlpha(30),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  children: [
                    isLoading
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: color,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            '$count',
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
                        color: isSelected ? color : AppColors.onSurfaceVariant,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(height: 4),
                      Container(
                        width: 20,
                        height: 3,
                        decoration: BoxDecoration(
                          color: color,
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

// ─── Mission Card ─────────────────────────────────────────────────────────────
class _MissionCard extends StatelessWidget {
  const _MissionCard({
    required this.adresse,
    required this.timestamp,
    required this.statut,
    required this.lat,
    required this.lng,
    required this.l,
    required this.onTap,
  });

  final String adresse;
  final Timestamp? timestamp;
  final String statut;
  final double? lat;
  final double? lng;
  final AppLocalizations l;
  final VoidCallback? onTap;

  Color get _statusColor {
    switch (statut) {
      case 'en cours':
        return AppColors.statusInProgress;
      case 'terminé':
        return AppColors.statusCompleted;
      default:
        return AppColors.statusPendingAdmin;
    }
  }

  String get _statusLabel {
    switch (statut) {
      case 'en cours':
        return l.t('statut_en_cours');
      case 'terminé':
        return l.t('statut_termine');
      default:
        return l.t('statut_en_attente');
    }
  }

  /// Absolute formatted timestamp using intl.
  String _formatTime() {
    if (timestamp == null) return '';
    final dt = timestamp!.toDate();
    return DateFormat('dd/MM/yyyy – HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final bool tappable = onTap != null;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppColors.botanicalShadow,
            border: tappable
                ? Border.all(color: AppColors.primary.withAlpha(20), width: 1)
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _statusColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.location_on_outlined,
                    color: _statusColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        adresse,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_formatTime().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                size: 11,
                                color: AppColors.onSurfaceVariant,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                _formatTime(),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                tappable
                    ? Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.my_location_rounded,
                          color: AppColors.primary,
                          size: 16,
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          _statusLabel,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _statusColor,
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
  const _FirestoreErrorCard({required this.error, required this.l});
  final Object? error;
  final AppLocalizations l;

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
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFE65100),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l.t('erreur_firestore'),
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
            error?.toString() ?? l.t('erreur_inconnue'),
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

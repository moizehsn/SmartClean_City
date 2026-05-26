import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/services/geocoding_service.dart';
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

  late final Stream<QuerySnapshot> _nouveauxStream;
  late final Stream<QuerySnapshot> _enCoursStream;
  late final Stream<QuerySnapshot> _enVerificationStream;
  late final Stream<QuerySnapshot> _terminesStream;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final firestore = FirebaseFirestore.instance.collection('signalements');
    
    _nouveauxStream = firestore.where('statut', isEqualTo: 'en attente').snapshots();
    _enCoursStream = firestore.where('statut', isEqualTo: 'en cours').where('chauffeur_id', isEqualTo: uid).snapshots();
    _enVerificationStream = firestore.where('statut', isEqualTo: 'en vérification').where('chauffeur_id', isEqualTo: uid).snapshots();
    _terminesStream = firestore.where('statut', isEqualTo: 'terminé').where('chauffeur_id', isEqualTo: uid).snapshots();
  }

  Stream<QuerySnapshot> get _activeStream {
    switch (_currentFilter) {
      case 'en cours':
        return _enCoursStream;
      case 'en vérification':
        return _enVerificationStream;
      case 'terminé':
        return _terminesStream;
      default:
        return _nouveauxStream;
    }
  }

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
      statut: 'en vérification',
      label: l.t('statut_en_verification'),
      color: AppColors.statusVerification,
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
      case 'en vérification':
        return l.t('statut_en_verification');
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
      case 'en vérification':
        return AppColors.statusVerification;
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
          decoration: const BoxDecoration(gradient: AppColors.driverHeroGradient),
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
                                  stream: f.statut == 'en attente'
                                      ? _nouveauxStream
                                      : f.statut == 'en cours'
                                          ? _enCoursStream
                                          : f.statut == 'en vérification'
                                              ? _enVerificationStream
                                              : _terminesStream,
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
                  stream: _activeStream,
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
                            lat: lat,
                            lng: lng,
                            timestamp: data['timestamp'] as Timestamp?,
                            statut: _currentFilter,
                            l: l,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => MissionDetailScreen(
                                    docId: docId,
                                    data: data,
                                  ),
                                ),
                              );
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
    required this.stream,
  });

  final String label;
  final String statut;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  final Stream<QuerySnapshot> stream;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: isSelected ? color : AppColors.onSurfaceVariant,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
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
/// IMPORTANT: This must be a StatefulWidget so that the geocoding [Future]
/// is created once in [initState] and is NOT recreated on every parent rebuild.
/// If it were a StatelessWidget, the FutureBuilder would restart on every
/// rebuild, making it flash "Chargement..." perpetually.
class _MissionCard extends StatefulWidget {
  const _MissionCard({
    required this.adresse,
    required this.lat,
    required this.lng,
    required this.timestamp,
    required this.statut,
    required this.l,
    required this.onTap,
  });

  final String adresse;
  final double? lat;
  final double? lng;
  final Timestamp? timestamp;
  final String statut;
  final AppLocalizations l;
  final VoidCallback? onTap;

  @override
  State<_MissionCard> createState() => _MissionCardState();
}

class _MissionCardState extends State<_MissionCard> {
  /// Stored once so FutureBuilder never re-triggers on rebuild.
  Future<String>? _geocodeFuture;

  @override
  void initState() {
    super.initState();
    if (widget.lat != null && widget.lng != null) {
      _geocodeFuture = GeocodingService.getNeighborhood(widget.lat!, widget.lng!);
    }
  }

  Color get _statusColor {
    switch (widget.statut) {
      case 'en cours':
        return AppColors.statusInProgress;
      case 'terminé':
        return AppColors.statusCompleted;
      default:
        return AppColors.statusPendingAdmin;
    }
  }

  String get _statusLabel {
    switch (widget.statut) {
      case 'en cours':
        return widget.l.t('statut_en_cours');
      case 'terminé':
        return widget.l.t('statut_termine');
      default:
        return widget.l.t('statut_en_attente');
    }
  }

  String _formatTime() {
    if (widget.timestamp == null) return '';
    final dt = widget.timestamp!.toDate();
    return DateFormat('dd/MM/yyyy – HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final bool tappable = widget.onTap != null;
    final primary = Theme.of(context).colorScheme.primary;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: widget.onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.driverSurface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppColors.driverShadow,
            border: tappable
                ? Border.all(color: primary.withAlpha(30), width: 1)
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Neighbourhood via Geocoding ───────────────────────────────────
                // Shows: spinner while loading, geocoded name on success,
                // or the raw adresse_lisible as a muted fallback.
                if (_geocodeFuture != null)
                  FutureBuilder<String>(
                    future: _geocodeFuture,
                    builder: (context, snap) {
                      // Loading state — show a small inline spinner
                      if (snap.connectionState == ConnectionState.waiting) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: primary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Chargement...',
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  color: AppColors.driverOnSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Error / no data — show raw address as grey italic
                      if (snap.hasError || !snap.hasData) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            widget.adresse,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: AppColors.driverOnSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }

                      // Success — show ONLY the geocoded name, bold + accented
                      final name = snap.data!;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Icon(Icons.place_rounded, size: 13, color: primary),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                name,
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: primary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _statusColor.withAlpha(30),
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
                            widget.adresse,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.driverOnSurfaceVariant,
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
                                    color: AppColors.driverOnSurfaceVariant,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    _formatTime(),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: AppColors.driverOnSurfaceVariant,
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
                              color: primary.withAlpha(25),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.my_location_rounded,
                              color: primary,
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

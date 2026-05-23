import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/constants/app_colors.dart';

/// Admin — Carte Intelligente: live map of active reports
class AdminCarteView extends StatefulWidget {
  const AdminCarteView({super.key});

  @override
  State<AdminCarteView> createState() => _AdminCarteViewState();
}

class _AdminCarteViewState extends State<AdminCarteView> {
  GoogleMapController? _mapController;

  // Laghouat city centre
  static const _initialPosition = LatLng(33.8000, 2.8833);
  static const _zoomLevel = 13.0;

  final Set<Marker> _markers = {};
  bool _isLoading = true;
  Object? _error;

  late final StreamSubscription<QuerySnapshot> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = FirebaseFirestore.instance
        .collection('signalements')
        .where('statut', whereIn: ['en attente', 'en cours'])
        .snapshots()
        .listen(
          (snapshot) {
            final newMarkers = <Marker>{};
            for (final doc in snapshot.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final lat = (data['latitude'] as num?)?.toDouble();
              final lng = (data['longitude'] as num?)?.toDouble();
              final statut = data['statut'] as String? ?? 'en attente';
              if (lat == null || lng == null) continue;
              newMarkers.add(
                Marker(
                  markerId: MarkerId(doc.id),
                  position: LatLng(lat, lng),
                  icon: statut == 'en cours'
                      ? BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueViolet,
                        )
                      : BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueOrange,
                        ),
                  onTap: () => _showReportDialog(data, doc.id),
                ),
              );
            }
            if (mounted) {
              setState(() {
                _markers
                  ..clear()
                  ..addAll(newMarkers);
                _isLoading = false;
              });
            }
          },
          onError: (err) {
            if (mounted) setState(() { _error = err; _isLoading = false; });
          },
        );
  }

  @override
  void dispose() {
    _subscription.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // ── Status badge helpers ────────────────────────────────────────────────────
  Color _statusColor(String statut) {
    switch (statut) {
      case 'en attente':
        return AppColors.statusPendingAdmin;
      case 'en cours':
        return AppColors.statusInProgress;
      case 'terminé':
        return AppColors.statusCompleted;
      default:
        return AppColors.onSurfaceVariant;
    }
  }

  String _statusLabel(String statut) {
    switch (statut) {
      case 'en attente':
        return 'En attente';
      case 'en cours':
        return 'En cours';
      default:
        return statut;
    }
  }

  // ── Marker detail dialog ────────────────────────────────────────────────────
  void _showReportDialog(Map<String, dynamic> data, String docId) {
    final addr = data['adresse_lisible'] as String? ?? 'Adresse inconnue';
    final statut = data['statut'] as String? ?? 'en attente';
    final idCourt = data['id_court'] as String? ?? '#????';
    final photoBase64 = data['photo_base64'] as String?;
    final color = _statusColor(statut);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.surfaceContainerLowest,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header row ──────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        idCourt,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        _statusLabel(statut),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Address ─────────────────────────────────────────────
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        addr,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Photo thumbnail ─────────────────────────────────────
                if (photoBase64 != null && photoBase64.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(
                      base64Decode(photoBase64),
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 180,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 40,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),

                if (photoBase64 == null || photoBase64.isEmpty)
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.photo_camera_outlined,
                        size: 40,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),

                // ── Action buttons ──────────────────────────────────────
                Row(
                  children: [
                    if (statut == 'en attente') ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            FirebaseFirestore.instance
                                .collection('signalements')
                                .doc(docId)
                                .update({'statut': 'en cours'});
                            Navigator.of(ctx).pop();
                          },
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: Text(
                            'Accepter',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.onSurfaceVariant,
                          side: BorderSide(
                            color: AppColors.outlineVariant.withOpacity(0.5),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Fermer',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                          ),
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Header bar ────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          child: Row(
            children: [
              Text(
                'Carte Intelligente',
                style: GoogleFonts.manrope(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.statusPendingAdmin.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.statusPendingAdmin,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'En attente',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.statusPendingAdmin,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.statusInProgress.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.statusInProgress,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'En cours',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.statusInProgress,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'Temps réel',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.green.shade400,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),

        // ── Map ───────────────────────────────────────────────────────────
        Expanded(
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth,
                        minHeight: constraints.maxHeight,
                      ),
                      child: Stack(
                        children: [
                          // ── Google Map (stable key — never unmounts on web) ──
                          GoogleMap(
                            key: const ValueKey('admin-map'),
                            initialCameraPosition: const CameraPosition(
                              target: _initialPosition,
                              zoom: _zoomLevel,
                            ),
                            markers: _markers,
                            myLocationEnabled: false,
                            zoomControlsEnabled: true,
                            mapToolbarEnabled: false,
                            onMapCreated: (c) => _mapController = c,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // ── Loading overlay ──
              if (_isLoading)
                Container(
                  color: AppColors.surfaceContainerLow,
                  child: const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
              // ── Error overlay (red box with exact exception) ──
              if (_error != null)
                Container(
                  color: const Color(0xFF2D0000),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
                          const SizedBox(height: 16),
                          Text(
                            'Erreur de chargement de la carte',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.redAccent,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SelectableText(
                            '$_error',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.robotoMono(
                              fontSize: 12,
                              color: Colors.red.shade200,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

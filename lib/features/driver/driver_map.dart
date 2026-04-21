import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/primary_button.dart';
import 'mission_detail_screen.dart';

/// Driver map view — shows pending reports as markers on Google Maps.
class DriverMap extends StatefulWidget {
  const DriverMap({super.key});

  @override
  State<DriverMap> createState() => _DriverMapState();
}

class _DriverMapState extends State<DriverMap> {
  GoogleMapController? _mapController;

  // ── Laghouat region constraints ─────────────────────────────────────────
  static const _initialPosition = LatLng(33.8000, 2.8833);
  static const _zoomLevel = 13.0;

  static final _laghouatBounds = LatLngBounds(
    southwest: const LatLng(33.7200, 2.7800),
    northeast: const LatLng(33.8800, 2.9800),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Carte des missions',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('signalements')
            .where('statut', isEqualTo: 'en attente')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2.5,
              ),
            );
          }

          final Set<Marker> markers = {};

          if (snapshot.hasData) {
            for (final doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final lat = data['latitude'] as double?;
              final lng = data['longitude'] as double?;
              if (lat == null || lng == null) continue;

              markers.add(
                Marker(
                  markerId: MarkerId(doc.id),
                  position: LatLng(lat, lng),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueGreen),
                  onTap: () => _showMissionBottomSheet(context, doc.id, data),
                ),
              );
            }
          }

          return GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _initialPosition,
              zoom: _zoomLevel,
            ),
            cameraTargetBounds: CameraTargetBounds(_laghouatBounds),
            minMaxZoomPreference: const MinMaxZoomPreference(11.0, 18.0),
            markers: markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (controller) => _mapController = controller,
          );
        },
      ),
    );
  }

  void _showMissionBottomSheet(
      BuildContext context, String docId, Map<String, dynamic> data) {
    final String adresse = data['adresse_lisible'] ?? 'Adresse inconnue';
    final String? photoBase64 = data['photo_base64'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.55,
          ),
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Handle bar ──────────────────────────────────
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppColors.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // ── Title ───────────────────────────────────────
                Text(
                  'Nouveau signalement',
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 16),

                // ── Address ─────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.location_on_rounded,
                            color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          adresse,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── "Before" photo ──────────────────────────────
                if (photoBase64 != null && photoBase64.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.memory(
                      base64Decode(photoBase64),
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 180,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Icon(Icons.broken_image_outlined,
                              color: AppColors.onSurfaceVariant, size: 40),
                        ),
                      ),
                    ),
                  ),
                if (photoBase64 != null && photoBase64.isNotEmpty)
                  const SizedBox(height: 20),

                // ── Accept button ───────────────────────────────
                PrimaryButton(
                  label: 'Accepter la mission',
                  icon: Icons.check_circle_outline_rounded,
                  onPressed: () async {
                    // Update status in Firestore
                    await FirebaseFirestore.instance
                        .collection('signalements')
                        .doc(docId)
                        .update({
                      'statut': 'en cours',
                      'chauffeur_id': 'chauffeur_mock',
                    });

                    if (ctx.mounted) Navigator.of(ctx).pop();

                    // Navigate to mission detail
                    if (context.mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MissionDetailScreen(
                            docId: docId,
                            data: data,
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

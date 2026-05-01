import 'dart:convert';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/primary_button.dart';
import 'mission_active_screen.dart';

/// Driver map view — shows 'en attente' (red) and 'en cours' (purple) markers.
/// Accepts [focusTarget] from [DriverMainScreen] and animates the camera
/// whenever a new LatLng is written to it (e.g. from dashboard card tap).
class DriverMap extends StatefulWidget {
  const DriverMap({super.key, required this.focusTarget});

  final ValueNotifier<LatLng?> focusTarget;

  @override
  State<DriverMap> createState() => _DriverMapState();
}

class _DriverMapState extends State<DriverMap> {
  GoogleMapController? _mapController;

  /// Pre-built marker icons keyed by status colour.
  BitmapDescriptor? _iconPending;   // red  — 'en attente'
  BitmapDescriptor? _iconInProgress; // purple — 'en cours'

  static const _initialPosition = LatLng(33.8000, 2.8833);
  static const _zoomLevel = 13.0;

  static final _laghouatBounds = LatLngBounds(
    southwest: const LatLng(33.7200, 2.7800),
    northeast: const LatLng(33.8800, 2.9800),
  );

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    widget.focusTarget.addListener(_onFocusChanged);
    _loadMarkerIcons();
  }

  @override
  void dispose() {
    widget.focusTarget.removeListener(_onFocusChanged);
    _mapController?.dispose();
    super.dispose();
  }

  // ── Focus listener ───────────────────────────────────────────────────────────

  void _onFocusChanged() {
    final target = widget.focusTarget.value;
    if (target != null) {
      _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(target, 16.0));
    }
  }

  // ── Marker loading ───────────────────────────────────────────────────────────

  Future<void> _loadMarkerIcons() async {
    final pending    = await _buildPinMarker(const Color(0xFFD32F2F));
    final inProgress = await _buildPinMarker(const Color(0xFF6A1B9A));
    if (mounted) {
      setState(() {
        _iconPending    = pending;
        _iconInProgress = inProgress;
      });
    }
  }

  // ── Custom marker builder ────────────────────────────────────────────────────

  /// Draws a crisp map-pin at HIGH internal resolution (120 × 160 logical px)
  /// then exports the bitmap with `imagePixelRatio: 3.0` so Google Maps
  /// renders it at a compact ~40 × 53 pt physical size on screen.
  ///
  /// Pin anatomy (logical px):
  ///   • Circle  : center (60, 60), radius 60
  ///   • Triangle: shoulders ~y 100, sharp tip at (60, 160)
  ///   • White stroke 4 px, trash icon 64 px
  ///
  /// [Marker] anchor MUST be `Offset(0.5, 1.0)`.
  static Future<BitmapDescriptor> _buildPinMarker(Color pinColor) async {
    // ── Canvas dimensions (logical px drawn at 1:1) ────────────────────
    const double W  = 120.0; // total width
    const double H  = 160.0; // total height
    const double cx = W / 2; // 60 — horizontal centre
    const double r  = W / 2; // 60 — circle radius (fills width)
    const double cy = r;     // 60 — circle centre y

    // Physical output size → matches the drawing bounds exactly.
    // imagePixelRatio: 3.0 tells Google Maps that each 3 physical pixels
    // equal 1 logical point → renders at W/3 × H/3 ≈ 40 × 53 pt.
    const double dpr = 3.0;
    const int outW   = 120; // W.toInt()
    const int outH   = 160; // H.toInt()

    final recorder = ui.PictureRecorder();
    final canvas   = Canvas(recorder);

    // ── Build pin silhouette (circle ∪ triangle) ─────────────────────
    final circlePath = Path()
      ..addOval(Rect.fromCircle(center: const Offset(cx, cy), radius: r));

    const double shoulderY  = cy + r * 0.75; // ~105
    const double halfBase   = r * 0.50;       // 30
    const double tipY       = H;              // 160
    final trianglePath = Path()
      ..moveTo(cx - halfBase, shoulderY)
      ..lineTo(cx, tipY)
      ..lineTo(cx + halfBase, shoulderY)
      ..close();

    final pinPath = Path.combine(
        PathOperation.union, circlePath, trianglePath);

    // ── 1. Drop shadow (soft, behind everything) ──────────────────────
    canvas.drawPath(
      pinPath.shift(const Offset(0, 3)),
      Paint()
        ..color      = Colors.black.withAlpha(50)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // ── 2. White border stroke ────────────────────────────────────────
    canvas.drawPath(
      pinPath,
      Paint()
        ..color       = Colors.white
        ..style       = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..strokeJoin  = StrokeJoin.round,
    );

    // ── 3. Colour fill ────────────────────────────────────────────────
    canvas.drawPath(
      pinPath,
      Paint()
        ..color = pinColor
        ..style = PaintingStyle.fill,
    );

    // ── 4. Inner highlight circle (subtle depth) ──────────────────────
    canvas.drawCircle(
      const Offset(cx, cy),
      r - 10,
      Paint()
        ..color = Colors.white.withAlpha(20)
        ..style = PaintingStyle.fill,
    );

    // ── 5. White trash icon centred in the circle ─────────────────────
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.delete_outline.codePoint),
        style: TextStyle(
          fontSize:   64,
          color:      Colors.white,
          fontFamily: Icons.delete_outline.fontFamily,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));

    // ── Rasterise ─────────────────────────────────────────────────────
    final picture  = recorder.endRecording();
    final img      = await picture.toImage(outW, outH);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    // imagePixelRatio: 3.0 → Maps renders 120/3 × 160/3 = 40 × 53 pt.
    return BitmapDescriptor.bytes(
      byteData!.buffer.asUint8List(),
      imagePixelRatio: dpr,
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

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
        // Show both pending AND in-progress missions on the map.
        stream: FirebaseFirestore.instance
            .collection('signalements')
            .where('statut', whereIn: ['en attente', 'en cours'])
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              _iconPending == null) {
            return const Center(
              child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2.5),
            );
          }

          final Set<Marker> markers = {};

          if (snapshot.hasData) {
            for (final doc in snapshot.data!.docs) {
              final data   = doc.data() as Map<String, dynamic>;
              final lat    = (data['latitude']  as num?)?.toDouble();
              final lng    = (data['longitude'] as num?)?.toDouble();
              final statut = data['statut'] as String? ?? 'en attente';
              if (lat == null || lng == null) continue;

              // Choose icon by status; fall back to a coloured default pin.
              final icon = statut == 'en cours'
                  ? (_iconInProgress ??
                      BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueViolet))
                  : (_iconPending ??
                      BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueRed));

              markers.add(
                Marker(
                  markerId: MarkerId(doc.id),
                  position: LatLng(lat, lng),
                  icon:     icon,
                  // Pin tip (bottom-centre of bitmap) → exact coordinate.
                  anchor: const Offset(0.5, 1.0),
                  onTap: () =>
                      _showMissionBottomSheet(context, doc.id, data),
                ),
              );
            }
          }

          return GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _initialPosition,
              zoom:   _zoomLevel,
            ),
            cameraTargetBounds:    CameraTargetBounds(_laghouatBounds),
            minMaxZoomPreference:  const MinMaxZoomPreference(11.0, 18.0),
            markers:               markers,
            myLocationEnabled:     true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled:   false,
            mapToolbarEnabled:     false,
            onMapCreated: (controller) {
              _mapController = controller;
              final pending  = widget.focusTarget.value;
              if (pending != null) {
                controller.animateCamera(
                    CameraUpdate.newLatLngZoom(pending, 16.0));
              }
            },
          );
        },
      ),
    );
  }

  // ── Bottom Sheet ─────────────────────────────────────────────────────────────

  void _showMissionBottomSheet(
      BuildContext context, String docId, Map<String, dynamic> data) {
    final String  adresse    = data['adresse_lisible'] ?? 'Adresse inconnue';
    final String? photoBase64 = data['photo_base64'];
    final String  statut     = data['statut'] as String? ?? 'en attente';
    final bool    isPending   = statut == 'en attente';

    // Colour theme for the sheet matches the marker colour.
    final Color accentColor = isPending
        ? const Color(0xFFD32F2F)
        : AppColors.statusInProgress;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.65,
          ),
          decoration: const BoxDecoration(
            color:        AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color:        AppColors.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Title row — colour reflects status
                Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color:        accentColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.delete_outline,
                          color: accentColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isPending ? 'Nouveau signalement' : 'Mission en cours',
                        style: GoogleFonts.manrope(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color:       AppColors.onSurface,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    // Status chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color:        accentColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isPending ? 'En attente' : 'En cours',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize:   11,
                          fontWeight: FontWeight.w600,
                          color:      accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Address
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color:        AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color:        AppColors.primary.withAlpha(25),
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
                            fontSize:   14,
                            fontWeight: FontWeight.w500,
                            color:      AppColors.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // "Before" photo
                if (photoBase64 != null && photoBase64.isNotEmpty) ...[
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
                          color:        AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Icon(Icons.broken_image_outlined,
                              color: AppColors.onSurfaceVariant, size: 40),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // CTA button — behaviour differs by status
                if (isPending)
                  // ── NEW mission: accept + open execution screen ──────
                  PrimaryButton(
                    label: 'Accepter la mission',
                    icon:  Icons.check_circle_outline_rounded,
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('signalements')
                          .doc(docId)
                          .update({
                        'statut':       'en cours',
                        'chauffeur_id': 'chauffeur_mock',
                      });
                      if (ctx.mounted) Navigator.of(ctx).pop();
                      if (context.mounted) {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => MissionActiveScreen(
                              docId: docId, data: data),
                        ));
                      }
                    },
                  )
                else
                  // ── IN-PROGRESS mission: go straight to execution ────
                  PrimaryButton(
                    label: 'Continuer la mission',
                    icon:  Icons.arrow_forward_rounded,
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) =>
                            MissionActiveScreen(docId: docId, data: data),
                      ));
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

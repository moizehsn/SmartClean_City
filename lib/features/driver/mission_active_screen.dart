import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/primary_button.dart';

/// Unified single-screen mission execution flow.
/// Replaces the old MissionDetailScreen → MissionValidationScreen chain.
///
/// On entry the caller has already set [statut] to 'en cours' in Firestore.
/// On "Clôturer" this screen writes [statut: 'terminé'], [photo_apres_base64],
/// and [timestamp_fin] before popping back to the dashboard.
class MissionActiveScreen extends StatefulWidget {
  const MissionActiveScreen({
    super.key,
    required this.docId,
    required this.data,
  });

  final String docId;
  final Map<String, dynamic> data;

  @override
  State<MissionActiveScreen> createState() => _MissionActiveScreenState();
}

class _MissionActiveScreenState extends State<MissionActiveScreen> {
  XFile? _afterImage;
  bool _isCapturing = false;
  bool _isSubmitting = false;

  bool get _canClose =>
      _afterImage != null && !_isSubmitting && !_isCapturing;

  // ── Camera ────────────────────────────────────────────────────────────────

  Future<void> _captureAfterPhoto() async {
    try {
      setState(() => _isCapturing = true);
      final image = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 25,
        maxWidth: 1080,
      );
      if (image == null) {
        setState(() => _isCapturing = false);
        return;
      }
      setState(() {
        _afterImage = image;
        _isCapturing = false;
      });
    } catch (e) {
      setState(() => _isCapturing = false);
      if (mounted) _snack('Erreur caméra : ${e.toString()}', isError: true);
    }
  }

  // ── Navigation (url_launcher) ─────────────────────────────────────────────

  Future<void> _launchNavigation() async {
    final lat = (widget.data['latitude'] as num?)?.toDouble();
    final lng = (widget.data['longitude'] as num?)?.toDouble();
    if (lat == null || lng == null) {
      _snack('Coordonnées GPS non disponibles', isError: true);
      return;
    }
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _snack("Impossible d'ouvrir Google Maps", isError: true);
    }
  }

  // ── Finalise mission ──────────────────────────────────────────────────────

  Future<void> _cloturerMission() async {
    if (!_canClose) return;
    setState(() => _isSubmitting = true);
    try {
      final bytes = await File(_afterImage!.path).readAsBytes();
      await FirebaseFirestore.instance
          .collection('signalements')
          .doc(widget.docId)
          .update({
        'statut': 'terminé',
        'photo_apres_base64': base64Encode(bytes),
        'timestamp_fin': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        _snack('Mission clôturée avec succès !', isError: false);
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) _snack('Erreur : ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _snack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: GoogleFonts.plusJakartaSans(color: Colors.white)),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final adresse =
        widget.data['adresse_lisible'] as String? ?? 'Adresse inconnue';
    final photoAvant = widget.data['photo_base64'] as String?;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(
          'Mission en cours',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.loop_rounded,
                    color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Text(
                  'En cours',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section: "Avant" photo ──────────────────────────────────
            _SectionHeader(
                icon: Icons.camera_alt_outlined,
                label: 'Photo du signalement (Avant)'),
            const SizedBox(height: 12),
            _AvantPhotoWidget(photoBase64: photoAvant),
            const SizedBox(height: 24),

            // ── Section: Address + Itinéraire ───────────────────────────
            _SectionHeader(
                icon: Icons.location_on_rounded, label: 'Localisation'),
            const SizedBox(height: 12),
            _AddressCard(adresse: adresse),
            const SizedBox(height: 14),
            _ItineraireButton(onTap: _launchNavigation),
            const SizedBox(height: 28),

            // ── Section: "Après" photo capture ─────────────────────────
            _SectionHeader(
                icon: Icons.photo_camera_outlined,
                label: 'Photo après nettoyage'),
            const SizedBox(height: 8),
            Text(
              'Obligatoire pour clôturer la mission',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            _ApresPhotoZone(
              afterImage: _afterImage,
              isCapturing: _isCapturing,
              isSubmitting: _isSubmitting,
              onCapture: _captureAfterPhoto,
            ),
            const SizedBox(height: 12),

            // Info note
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryFixed.withOpacity(0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.primary, size: 17),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'La photo « Après » sera envoyée comme preuve de nettoyage et consultable par le citoyen.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppColors.onSurface,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── CTA: Clôturer ───────────────────────────────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _canClose
                  ? PrimaryButton(
                      key: const ValueKey('active'),
                      label: 'Clôturer la mission',
                      icon: Icons.verified_rounded,
                      onPressed: _cloturerMission,
                      isLoading: _isSubmitting,
                    )
                  : _DisabledCloseButton(key: const ValueKey('disabled')),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Small helpers ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
      ],
    );
  }
}

// ── "Avant" photo ─────────────────────────────────────────────────────────────
class _AvantPhotoWidget extends StatelessWidget {
  const _AvantPhotoWidget({this.photoBase64});
  final String? photoBase64;

  @override
  Widget build(BuildContext context) {
    if (photoBase64 != null && photoBase64!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.memory(
          base64Decode(photoBase64!),
          width: double.infinity,
          height: 220,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _photoPlaceholder(),
        ),
      );
    }
    return _photoPlaceholder();
  }

  Widget _photoPlaceholder() {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported_outlined,
              size: 48,
              color: AppColors.onSurfaceVariant.withOpacity(0.4)),
          const SizedBox(height: 8),
          Text(
            'Photo non disponible',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 13, color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ── Address card ──────────────────────────────────────────────────────────────
class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.adresse});
  final String adresse;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.botanicalShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.location_on_rounded,
                color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Adresse',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  adresse,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Itinéraire button ─────────────────────────────────────────────────────────
class _ItineraireButton extends StatelessWidget {
  const _ItineraireButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(100),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: SizedBox(
            height: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.navigation_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Itinéraire',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.20),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Google Maps',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
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

// ── Dashed "Après" capture zone ───────────────────────────────────────────────
class _ApresPhotoZone extends StatelessWidget {
  const _ApresPhotoZone({
    required this.afterImage,
    required this.isCapturing,
    required this.isSubmitting,
    required this.onCapture,
  });

  final XFile? afterImage;
  final bool isCapturing;
  final bool isSubmitting;
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    if (afterImage != null) {
      // Photo captured — show preview with re-take overlay
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Image.file(
              File(afterImage!.path),
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
            ),
            // Success banner
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 12, horizontal: 16),
                color: AppColors.primary,
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '✓ Photo « Après » capturée',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    if (!isSubmitting)
                      GestureDetector(
                        onTap: onCapture,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.20),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.camera_alt_outlined,
                                  color: Colors.white, size: 13),
                              const SizedBox(width: 4),
                              Text(
                                'Reprendre',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // No photo yet — dashed container prompt
    return GestureDetector(
      onTap: isCapturing ? null : onCapture,
      child: CustomPaint(
        painter: _DashedBorderPainter(
            color: AppColors.primary.withOpacity(0.40)),
        child: Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.primaryFixed.withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
          ),
          child: isCapturing
              ? const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primary, strokeWidth: 2.5))
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primaryFixed.withOpacity(0.30),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt_outlined,
                          color: AppColors.primary, size: 30),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Appuyez pour prendre la photo',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'après le nettoyage',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Dashed border painter ─────────────────────────────────────────────────────
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const double dashWidth = 8;
    const double dashSpace = 5;
    const double radius = 20;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
          RRect.fromLTRBR(0, 0, size.width, size.height, const Radius.circular(radius)));

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(
            metric.extractPath(distance, distance + dashWidth), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Disabled CTA ──────────────────────────────────────────────────────────────
class _DisabledCloseButton extends StatelessWidget {
  const _DisabledCloseButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_rounded,
                  color: AppColors.onSurfaceVariant.withOpacity(0.4),
                  size: 20),
              const SizedBox(width: 8),
              Text(
                'Clôturer la mission',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurfaceVariant.withOpacity(0.4),
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Photo « Après » requise pour clôturer',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: AppColors.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

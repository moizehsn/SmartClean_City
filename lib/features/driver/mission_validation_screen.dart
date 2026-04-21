import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/primary_button.dart';

/// Screen 2 of mission flow — capture "After" photo and validate mission.
class MissionValidationScreen extends StatefulWidget {
  const MissionValidationScreen({super.key, required this.docId});

  final String docId;

  @override
  State<MissionValidationScreen> createState() =>
      _MissionValidationScreenState();
}

class _MissionValidationScreenState extends State<MissionValidationScreen> {
  XFile? _afterImage;
  bool _isCapturing = false;
  bool _isSubmitting = false;

  bool get _canValidate =>
      _afterImage != null && !_isSubmitting && !_isCapturing;

  // ── Capture after photo ──────────────────────────────────────────────────
  Future<void> _prendrePhotoApres() async {
    try {
      setState(() => _isCapturing = true);
      final picker = ImagePicker();
      final image = await picker.pickImage(
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
      if (mounted) {
        _showSnackBar('Erreur caméra : ${e.toString()}', isError: true);
      }
    }
  }

  // ── Validate mission ─────────────────────────────────────────────────────
  Future<void> _validerMission() async {
    if (!_canValidate) return;

    setState(() => _isSubmitting = true);

    try {
      // Encode after photo
      final bytes = await File(_afterImage!.path).readAsBytes();
      final afterBase64 = base64Encode(bytes);

      // Update Firestore document
      await FirebaseFirestore.instance
          .collection('signalements')
          .doc(widget.docId)
          .update({
        'statut': 'terminé',
        'photo_apres_base64': afterBase64,
        'timestamp_fin': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _showSnackBar('Mission terminée avec succès !', isError: false);
        // Pop back to DriverMainScreen
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Erreur : ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(color: Colors.white),
        ),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
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
          'Validation de mission',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        leading: const BackButton(color: AppColors.onSurface),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Step label ──────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '1',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Prenez une photo après nettoyage',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Camera zone (After photo) ──────────────────────────
            if (_afterImage != null)
              Column(
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20)),
                        child: Image.file(
                          File(_afterImage!.path),
                          width: double.infinity,
                          height: 240,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: GestureDetector(
                          onTap: _isSubmitting ? null : _prendrePhotoApres,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.45),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.camera_alt_outlined,
                                    color: Colors.white, size: 14),
                                const SizedBox(width: 5),
                                Text(
                                  'Reprendre',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      borderRadius:
                          BorderRadius.vertical(bottom: Radius.circular(20)),
                    ),
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
                      ],
                    ),
                  ),
                ],
              )
            else
              GestureDetector(
                onTap: _isCapturing ? null : _prendrePhotoApres,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.outlineVariant.withOpacity(0.4),
                        width: 2),
                  ),
                  child: _isCapturing
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: AppColors.primaryFixed.withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt_outlined,
                                  color: AppColors.primary, size: 28),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Appuyez pour prendre la photo',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.onSurfaceVariant,
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
            const SizedBox(height: 20),

            // ── Info note ──────────────────────────────────────────
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

            // ── Validate button ────────────────────────────────────
            _canValidate
                ? PrimaryButton(
                    label: 'Valider la mission',
                    onPressed: _validerMission,
                    isLoading: _isSubmitting,
                    icon: Icons.verified_rounded,
                  )
                : Column(
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
                                color:
                                    AppColors.onSurfaceVariant.withOpacity(0.4),
                                size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Valider la mission',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color:
                                    AppColors.onSurfaceVariant.withOpacity(0.4),
                                letterSpacing: 0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Photo « Après » requise',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}

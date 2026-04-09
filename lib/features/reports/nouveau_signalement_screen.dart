import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/primary_button.dart';

class NouveauSignalementScreen extends StatefulWidget {
  const NouveauSignalementScreen({super.key});

  @override
  State<NouveauSignalementScreen> createState() =>
      _NouveauSignalementScreenState();
}

class _NouveauSignalementScreenState extends State<NouveauSignalementScreen> {
  XFile? _image;
  bool _isLoading = false;

  // ── Open camera ────────────────────────────────────────────────────────────
  Future<void> _prendrePhoto() async {
    try {
      setState(() => _isLoading = true);
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1080,
      );
      // User cancelled — do nothing
      if (image == null) {
        setState(() => _isLoading = false);
        return;
      }
      setState(() {
        _image = image;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur caméra : ${e.toString()}",
                style: GoogleFonts.plusJakartaSans()),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  // ── Submit ─────────────────────────────────────────────────────────────────
  void _soumettre() {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Veuillez d'abord prendre une photo.",
              style: GoogleFonts.plusJakartaSans()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    // Mock submit — no backend yet
    debugPrint('✅ Signalement soumis : ${_image!.path}');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Nouveau Signalement',
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
            // ── Camera area ──────────────────────────────────────────────
            _CameraZone(
              image: _image,
              isLoading: _isLoading,
              onTapCamera: _prendrePhoto,
            ),
            const SizedBox(height: 20),

            // ── Location card ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppColors.botanicalShadow,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryFixed.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.my_location_rounded,
                        color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Position détectée automatiquement',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppColors.onSurfaceVariant),
                        ),
                        Text(
                          'Quartier El Atteuf, Laghouat',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.check_rounded,
                      color: AppColors.primary, size: 18),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Info note ────────────────────────────────────────────────
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
                      'Aucune description requise — photo + localisation suffisent.',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppColors.onSurface,
                          height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Submit button ────────────────────────────────────────────
            PrimaryButton(
              label: 'Soumettre le signalement',
              onPressed: _soumettre,
              icon: Icons.send_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Camera Zone Widget ────────────────────────────────────────────────────────
class _CameraZone extends StatelessWidget {
  const _CameraZone({
    required this.image,
    required this.isLoading,
    required this.onTapCamera,
  });

  final XFile? image;
  final bool isLoading;
  final VoidCallback onTapCamera;

  @override
  Widget build(BuildContext context) {
    // ── Success state ──────────────────────────────────────────────────
    if (image != null) {
      return Column(
        children: [
          // Image with "Change" overlay button
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20)),
                child: Image.file(
                  File(image!.path),
                  width: double.infinity,
                  height: 240,
                  fit: BoxFit.cover,
                ),
              ),
              // ── "Changer" overlay button ─────────────────────────
              Positioned(
                bottom: 10,
                right: 10,
                child: GestureDetector(
                  onTap: onTapCamera,
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
                          'Changer',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Green validation bar ──────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                  '✓ Déchet détecté — Signalement valide',
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
      );
    }

    // ── Empty state ────────────────────────────────────────────────────
    return GestureDetector(
      onTap: isLoading ? null : onTapCamera,
      child: Container(
        height: 240,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppColors.outlineVariant.withOpacity(0.4), width: 2),
        ),
        child: isLoading
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
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primaryFixed.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_outlined,
                        color: AppColors.primary, size: 30),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Appuyez pour prendre une photo',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'des déchets à signaler',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

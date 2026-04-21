import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/primary_button.dart';

// ─── Location state enum ──────────────────────────────────────────────────────
enum _LocationState { idle, loading, success, error }

class NouveauSignalementScreen extends StatefulWidget {
  const NouveauSignalementScreen({super.key});

  @override
  State<NouveauSignalementScreen> createState() =>
      _NouveauSignalementScreenState();
}

class _NouveauSignalementScreenState extends State<NouveauSignalementScreen> {
  // ── Photo state ──────────────────────────────────────────────────────────
  XFile? _image;
  bool _isCapturing = false;

  // ── Location state ───────────────────────────────────────────────────────
  _LocationState _locationState = _LocationState.idle;
  Position? _position;
  String? _readableAddress;

  // ── Submission state ─────────────────────────────────────────────────────
  bool _isSubmitting = false;

  // ── Derived: both conditions met? ────────────────────────────────────────
  bool get _canSubmit =>
      _image != null &&
      _locationState == _LocationState.success &&
      !_isSubmitting &&
      !_isCapturing;

  // =========================================================================
  // 1. IMAGE — capture + compress (imageQuality: 25)
  // =========================================================================
  Future<void> _prendrePhoto() async {
    try {
      setState(() => _isCapturing = true);
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.camera,
        // CRITICAL: 25% quality keeps the Base64 well under Firestore's 1 MB limit
        imageQuality: 25,
        maxWidth: 1080,
      );
      if (image == null) {
        setState(() => _isCapturing = false);
        return;
      }
      setState(() {
        _image = image;
        _isCapturing = false;
      });
    } catch (e) {
      setState(() => _isCapturing = false);
      if (mounted) {
        _showSnackBar('Erreur caméra : ${e.toString()}', isError: true);
      }
    }
  }

  Future<String> _encodeToBase64(File file) async {
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  // =========================================================================
  // 2. LOCATION — real GPS + geocoding
  // =========================================================================
  Future<void> _detecterPosition() async {
    setState(() => _locationState = _LocationState.loading);

    try {
      // ── a. Check / request service ───────────────────────────────────────
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception(
            'Le service de localisation est désactivé sur cet appareil.');
      }

      // ── b. Check / request permission ───────────────────────────────────
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permission de localisation refusée.');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception(
            'Permission de localisation définitivement refusée. Activez-la dans les paramètres.');
      }

      // ── c. Get position ──────────────────────────────────────────────────
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      // ── d. Reverse-geocode to readable address ───────────────────────────
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String address = 'Position détectée';
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = <String>[
          if (p.street != null && p.street!.isNotEmpty) p.street!,
          if (p.locality != null && p.locality!.isNotEmpty) p.locality!,
          if (p.administrativeArea != null &&
              p.administrativeArea!.isNotEmpty)
            p.administrativeArea!,
        ];
        if (parts.isNotEmpty) address = parts.join(', ');
      }

      setState(() {
        _position = position;
        _readableAddress = address;
        _locationState = _LocationState.success;
      });
    } catch (e) {
      setState(() => _locationState = _LocationState.error);
      if (mounted) {
        _showSnackBar('Erreur GPS : ${e.toString()}', isError: true);
      }
    }
  }

  // =========================================================================
  // 3. SUBMISSION — encode + send to Firestore
  // =========================================================================
  Future<void> _soumettre() async {
    if (!_canSubmit) return;

    setState(() => _isSubmitting = true);

    try {
      // a. Encode image to Base64
      final String base64String = await _encodeToBase64(File(_image!.path));

      // b. Build and send Firestore document
      await FirebaseFirestore.instance.collection('signalements').add({
        'description': 'Rapport citoyen',
        'latitude': _position!.latitude,
        'longitude': _position!.longitude,
        'adresse_lisible': _readableAddress!,
        'photo_base64': base64String,
        'statut': 'en attente',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // c. Success
      if (mounted) {
        _showSnackBar('Signalement envoyé avec succès !', isError: false);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Erreur lors de l\'envoi : ${e.toString()}',
            isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // =========================================================================
  // Helpers
  // =========================================================================
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

  // =========================================================================
  // BUILD
  // =========================================================================
  @override
  Widget build(BuildContext context) {
    final bool isBusy = _isCapturing || _isSubmitting;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
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
            // ── Step label ────────────────────────────────────────────────
            _StepLabel(number: '1', label: 'Prenez une photo'),
            const SizedBox(height: 10),

            // ── Camera zone ───────────────────────────────────────────────
            _CameraZone(
              image: _image,
              isLoading: _isCapturing,
              onTap: isBusy ? null : _prendrePhoto,
            ),
            const SizedBox(height: 24),

            // ── Step label ────────────────────────────────────────────────
            _StepLabel(number: '2', label: 'Détectez votre position'),
            const SizedBox(height: 10),

            // ── Location zone ─────────────────────────────────────────────
            _LocationZone(
              state: _locationState,
              address: _readableAddress,
              onTap: (isBusy || _locationState == _LocationState.loading)
                  ? null
                  : _detecterPosition,
            ),
            const SizedBox(height: 12),

            // ── Info note ─────────────────────────────────────────────────
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
                      'Photo + localisation suffisent — aucune description requise.',
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

            // ── Submit button (strict validation) ─────────────────────────
            _canSubmit
                ? PrimaryButton(
                    label: 'Soumettre le signalement',
                    onPressed: _soumettre,
                    isLoading: _isSubmitting,
                    icon: Icons.send_rounded,
                  )
                : _DisabledSubmitButton(
                    hasPhoto: _image != null,
                    hasLocation: _locationState == _LocationState.success,
                  ),
          ],
        ),
      ),
    );
  }
}

// ─── Step label ───────────────────────────────────────────────────────────────
class _StepLabel extends StatelessWidget {
  const _StepLabel({required this.number, required this.label});
  final String number;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
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
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
      ],
    );
  }
}

// ─── Camera Zone ──────────────────────────────────────────────────────────────
class _CameraZone extends StatelessWidget {
  const _CameraZone({
    required this.image,
    required this.isLoading,
    required this.onTap,
  });

  final XFile? image;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // ── Success: show captured image ───────────────────────────────────────
    if (image != null) {
      return Column(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.file(
                  File(image!.path),
                  width: double.infinity,
                  height: 240,
                  fit: BoxFit.cover,
                ),
              ),
              // "Retake" overlay
              Positioned(
                bottom: 10,
                right: 10,
                child: GestureDetector(
                  onTap: onTap,
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
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Green validation bar
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                  '✓ Photo capturée — Signalement valide',
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

    // ── Empty / loading state ──────────────────────────────────────────────
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: 200,
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

// ─── Location Zone ────────────────────────────────────────────────────────────
/// Matches the _CameraZone design: same background, same rounded corners,
/// same 200px height for idle/loading, compact on success.
class _LocationZone extends StatelessWidget {
  const _LocationZone({
    required this.state,
    required this.address,
    required this.onTap,
  });

  final _LocationState state;
  final String? address;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // ── Success state ──────────────────────────────────────────────────────
    if (state == _LocationState.success) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: AppColors.primary.withOpacity(0.4), width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle,
                  color: AppColors.primary, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Position détectée',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    address ?? '',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            // Allow re-detection
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.refresh_rounded,
                    color: AppColors.primary, size: 18),
              ),
            ),
          ],
        ),
      );
    }

    // ── Idle / loading / error state: large tappable container ────────────
    return GestureDetector(
      onTap: (state == _LocationState.loading) ? null : onTap,
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: state == _LocationState.error
                ? AppColors.error.withOpacity(0.5)
                : AppColors.outlineVariant.withOpacity(0.4),
            width: 2,
          ),
        ),
        child: state == _LocationState.loading
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
                      color: state == _LocationState.error
                          ? AppColors.error.withOpacity(0.1)
                          : AppColors.primaryFixed.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      state == _LocationState.error
                          ? Icons.location_off_outlined
                          : Icons.location_on_outlined,
                      color: state == _LocationState.error
                          ? AppColors.error
                          : AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    state == _LocationState.error
                        ? 'Échec — Appuyez pour réessayer'
                        : 'Appuyez pour détecter votre position',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: state == _LocationState.error
                          ? AppColors.error
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─── Disabled Submit Button ───────────────────────────────────────────────────
class _DisabledSubmitButton extends StatelessWidget {
  const _DisabledSubmitButton({
    required this.hasPhoto,
    required this.hasLocation,
  });

  final bool hasPhoto;
  final bool hasLocation;

  String get _hint {
    if (!hasPhoto && !hasLocation) return 'Photo et position requises';
    if (!hasPhoto) return 'Photo requise';
    return 'Position GPS requise';
  }

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
              Icon(Icons.send_rounded,
                  color: AppColors.onSurfaceVariant.withOpacity(0.4),
                  size: 20),
              const SizedBox(width: 8),
              Text(
                'Soumettre le signalement',
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
        // Contextual hint showing what's still missing
        Text(
          _hint,
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

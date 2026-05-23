import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/services/ai_vision_service.dart';
import '../../core/services/geo_utils.dart';
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

  // ── Validation phase for overlay UI ──────────────────────────────────────
  /// null = idle, 'gps' = checking duplicates, 'ai' = AI analysis, 'uploading'
  String? _validationPhase;

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
        final l = AppLocalizations.of(context);
        _showSnackBar(
          '${l.t('erreur_inconnue')} : ${e.toString()}',
          isError: true,
        );
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
        if (!mounted) return;
        final shouldOpen = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.location_off_rounded, color: Color(0xFFE65100)),
                SizedBox(width: 10),
                Text('GPS désactivé'),
              ],
            ),
            content: const Text(
              'Veuillez activer le GPS pour continuer.\nLe service de localisation est nécessaire pour géolocaliser votre signalement.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00450D),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Ouvrir les paramètres'),
              ),
            ],
          ),
        );
        if (shouldOpen == true) {
          await Geolocator.openLocationSettings();
        }
        setState(() => _locationState = _LocationState.idle);
        return;
      }

      // ── b. Check / request permission ───────────────────────────────────
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          final l = AppLocalizations.of(context);
          throw Exception(l.t('permission_refusee'));
        }
      }
      if (permission == LocationPermission.deniedForever) {
        final l = AppLocalizations.of(context);
        throw Exception(l.t('permission_definitivement'));
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
          if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty)
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
        final l = AppLocalizations.of(context);
        _showSnackBar(
          '${l.t('erreur_inconnue')} : ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  // =========================================================================
  // 3. SUBMISSION — GPS check → AI validation → Firestore
  // =========================================================================
  Future<void> _soumettre() async {
    if (!_canSubmit) return;
    final l = AppLocalizations.of(context);

    setState(() {
      _isSubmitting = true;
      _validationPhase = 'gps';
    });

    try {
      // ── Phase 1: GPS Duplicate Prevention ──────────────────────────────
      final isDuplicate = await GeoUtils.isDuplicateLocation(
        _position!.latitude,
        _position!.longitude,
      );
      if (!mounted) return;
      if (isDuplicate) {
        setState(() { _isSubmitting = false; _validationPhase = null; });
        _showRejectionDialog(
          icon: Icons.location_on_rounded,
          color: const Color(0xFFE65100),
          title: l.t('doublon_titre'),
          message: l.t('doublon_message'),
          buttonLabel: l.t('compris'),
        );
        return;
      }

      // ── Phase 2: AI Image Validation ───────────────────────────────────
      setState(() => _validationPhase = 'ai');
      final imageBytes = await File(_image!.path).readAsBytes();
      final isGarbage = await AiVisionService.validateGarbageImage(imageBytes);
      if (!mounted) return;
      if (!isGarbage) {
        setState(() { _isSubmitting = false; _validationPhase = null; });
        _showRejectionDialog(
          icon: Icons.camera_alt_rounded,
          color: AppColors.error,
          title: l.t('ia_rejet_citoyen_titre'),
          message: l.t('ia_rejet_citoyen_message'),
          buttonLabel: l.t('reessayer'),
        );
        return;
      }

      // ── Phase 3: Upload to Firestore ───────────────────────────────────
      setState(() => _validationPhase = 'uploading');
      final String base64String = base64Encode(imageBytes);
      final idCourt = '#${1000 + Random().nextInt(9000)}';
      await FirebaseFirestore.instance.collection('signalements').add({
        'citoyen_id': FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
        'id_court': idCourt,
        'description': 'Rapport citoyen',
        'latitude': _position!.latitude,
        'longitude': _position!.longitude,
        'adresse_lisible': _readableAddress!,
        'photo_base64': base64String,
        'statut': 'en attente',
        'chauffeur_id': '', // Empty = unassigned; visible in all drivers' "Nouveaux" tab.
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _showSnackBar('✓', isError: false);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          '${l.t('erreur_inconnue')} : ${e.toString()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() { _isSubmitting = false; _validationPhase = null; });
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

  void _showRejectionDialog({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
    required String buttonLabel,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.surfaceContainerLowest,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                message,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    buttonLabel,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // BUILD
  // =========================================================================
  @override
  Widget build(BuildContext context) {
    final bool isBusy = _isCapturing || _isSubmitting;
    final l = AppLocalizations.of(context);

    // ── Phase label for overlay ──────────────────────────────────────────
    String _phaseLabel() {
      switch (_validationPhase) {
        case 'gps':       return l.t('verification_gps');
        case 'ai':        return l.t('analyse_ia_cours');
        case 'uploading': return l.t('envoi_signalement');
        default:          return '';
      }
    }

    IconData _phaseIcon() {
      switch (_validationPhase) {
        case 'gps':       return Icons.satellite_alt_rounded;
        case 'ai':        return Icons.psychology_rounded;
        case 'uploading': return Icons.cloud_upload_rounded;
        default:          return Icons.hourglass_empty;
      }
    }

    return Stack(
      children: [
    Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          l.t('nouveau_signalement'),
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
            _StepLabel(number: '1', label: l.t('prenez_une_photo')),
            const SizedBox(height: 10),

            // ── Camera zone ───────────────────────────────────────────────
            _CameraZone(
              image: _image,
              isLoading: _isCapturing,
              onTap: isBusy ? null : _prendrePhoto,
              l: l,
            ),
            const SizedBox(height: 24),

            // ── Step label ────────────────────────────────────────────────
            _StepLabel(number: '2', label: l.t('detectez_position')),
            const SizedBox(height: 10),

            // ── Location zone ─────────────────────────────────────────────
            _LocationZone(
              state: _locationState,
              address: _readableAddress,
              onTap: (isBusy || _locationState == _LocationState.loading)
                  ? null
                  : _detecterPosition,
              l: l,
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
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.primary,
                    size: 17,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l.t('photo_plus_localisation'),
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

            // ── Submit button (strict validation) ─────────────────────────
            _canSubmit
                ? PrimaryButton(
                    label: l.t('soumettre_signalement'),
                    onPressed: _soumettre,
                    isLoading: _isSubmitting,
                    icon: Icons.send_rounded,
                  )
                : _DisabledSubmitButton(
                    hasPhoto: _image != null,
                    hasLocation: _locationState == _LocationState.success,
                    l: l,
                  ),
          ],
        ),
      ),
    ),

    // ── Validation overlay ────────────────────────────────────────────
    if (_validationPhase != null)
      Positioned.fill(
        child: Container(
          color: Colors.black.withOpacity(0.55),
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 48),
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 28),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(28),
                boxShadow: AppColors.botanicalShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.8, end: 1.2),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeInOut,
                    builder: (context, scale, child) {
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _phaseIcon(),
                        color: AppColors.primary,
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _phaseLabel(),
                      key: ValueKey(_validationPhase),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ], // Stack children
    ); // Stack
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
    required this.l,
  });

  final XFile? image;
  final bool isLoading;
  final VoidCallback? onTap;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    // ── Success: show captured image ───────────────────────────────────────
    if (image != null) {
      return Column(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
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
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.camera_alt_outlined,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          l.t('reprendre'),
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
          // Green validation bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  l.t('photo_capturee_valide'),
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
            color: AppColors.outlineVariant.withOpacity(0.4),
            width: 2,
          ),
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
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l.t('appuyez_pour_photo'),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.t('des_dechets'),
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
    required this.l,
  });

  final _LocationState state;
  final String? address;
  final VoidCallback? onTap;
  final AppLocalizations l;

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
          border: Border.all(
            color: AppColors.primary.withOpacity(0.4),
            width: 2,
          ),
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
              child: const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.t('position_detectee'),
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
                child: const Icon(
                  Icons.refresh_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
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
                        ? l.t('echec_reessayer')
                        : l.t('appuyez_pour_position'),
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
    required this.l,
  });

  final bool hasPhoto;
  final bool hasLocation;
  final AppLocalizations l;

  String get _hint {
    if (!hasPhoto && !hasLocation) return l.t('photo_et_position_requises');
    if (!hasPhoto) return l.t('photo_requise');
    return l.t('position_requise');
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
              Icon(
                Icons.send_rounded,
                color: AppColors.onSurfaceVariant.withOpacity(0.4),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                l.t('soumettre_signalement'),
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

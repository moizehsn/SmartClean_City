import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../shared/widgets/primary_button.dart';

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
  /// null = idle, 'uploading' = Firestore write
  String? _validationPhase;
  bool get _canClose => _afterImage != null && !_isSubmitting && !_isCapturing;

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
      if (mounted)
        _snack(
          '${AppLocalizations.of(context).t('erreur_camera')} : $e',
          isError: true,
        );
    }
  }

  Future<void> _launchNavigation() async {
    final l = AppLocalizations.of(context);
    final lat = (widget.data['latitude'] as num?)?.toDouble();
    final lng = (widget.data['longitude'] as num?)?.toDouble();
    if (lat == null || lng == null) {
      _snack(l.t('coordonnees_non_dispo'), isError: true);
      return;
    }
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _snack(l.t('impossible_google_maps'), isError: true);
    }
  }

  Future<void> _cloturerMission() async {
    if (!_canClose) return;
    final l = AppLocalizations.of(context);

    setState(() {
      _isSubmitting = true;
      _validationPhase = 'uploading';
    });

    try {
      // ── Encode after photo ──────────────────────────────────────────────────
      final bytes = await File(_afterImage!.path).readAsBytes();
      final afterBase64 = base64Encode(bytes);

      // ── Upload to Firestore — status becomes 'en vérification' (Admin QA) ──
      await FirebaseFirestore.instance
          .collection('signalements')
          .doc(widget.docId)
          .update({
            'statut': 'en vérification',
            'photo_apres_base64': afterBase64,
            'timestamp_fin': FieldValue.serverTimestamp(),
          });

      // NOTE: Citizen points are now awarded by the Admin upon approval.
      if (mounted) {
        _snack(l.t('mission_cloturee_succes'), isError: false);
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) _snack('Erreur : $e', isError: true);
    } finally {
      if (mounted) setState(() { _isSubmitting = false; _validationPhase = null; });
    }
  }

  void _snack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
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

  TextStyle _dFont(double s, FontWeight w, {Color? c}) =>
      AppLocalizations.of(context).isArabic
      ? GoogleFonts.tajawal(
          fontSize: s,
          fontWeight: w,
          color: c ?? AppColors.onSurface,
        )
      : GoogleFonts.manrope(
          fontSize: s,
          fontWeight: w,
          color: c ?? AppColors.onSurface,
        );

  TextStyle _bFont(double s, FontWeight w, {Color? c, double? h}) =>
      AppLocalizations.of(context).isArabic
      ? GoogleFonts.cairo(
          fontSize: s,
          fontWeight: w,
          color: c ?? AppColors.onSurface,
          height: h,
        )
      : GoogleFonts.plusJakartaSans(
          fontSize: s,
          fontWeight: w,
          color: c ?? AppColors.onSurface,
          height: h,
        );


  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final adresse =
        widget.data['adresse_lisible'] as String? ?? l.t('adresse_inconnue');
    final photoAvant = widget.data['photo_base64'] as String?;

    // ── Phase label helpers ──────────────────────────────────────────────
    String phaseLabel() {
      switch (_validationPhase) {
        case 'uploading': return l.t('envoi_validation');
        default:          return '';
      }
    }
    IconData phaseIcon() {
      switch (_validationPhase) {
        case 'uploading': return Icons.cloud_upload_rounded;
        default:          return Icons.hourglass_empty;
      }
    }

    return Stack(
      children: [
    Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(
          l.t('mission_en_cours'),
          style: _dFont(18, FontWeight.w700, c: Colors.white),
        ),
        actions: [
          Container(
            margin: const EdgeInsetsDirectional.only(end: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.loop_rounded, color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Text(
                  l.t('statut_en_cours'),
                  style: _bFont(12, FontWeight.w600, c: Colors.white),
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
            _header(Icons.camera_alt_outlined, l.t('photo_signalement_avant')),
            const SizedBox(height: 12),
            _avantPhoto(photoAvant, l),
            const SizedBox(height: 24),
            _header(Icons.location_on_rounded, l.t('localisation')),
            const SizedBox(height: 12),
            _addressCard(adresse, l),
            const SizedBox(height: 14),
            _itineraireBtn(l),
            const SizedBox(height: 28),
            _header(Icons.photo_camera_outlined, l.t('photo_apres_nettoyage')),
            const SizedBox(height: 8),
            Text(
              l.t('obligatoire_cloturer'),
              style: _bFont(12, FontWeight.w400, c: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            _apresZone(l),
            const SizedBox(height: 12),
            _infoNote(l),
            const SizedBox(height: 32),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _canClose
                  ? PrimaryButton(
                      key: const ValueKey('active'),
                      label: l.t('cloturer_mission'),
                      icon: Icons.verified_rounded,
                      onPressed: _cloturerMission,
                      isLoading: _isSubmitting,
                    )
                  : _disabledBtn(l),
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
                      child: Icon(phaseIcon(), color: AppColors.primary, size: 30),
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
                      phaseLabel(),
                      key: ValueKey(_validationPhase),
                      style: _bFont(15, FontWeight.w600),
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

  Widget _header(IconData icon, String label) => Row(
    children: [
      Icon(icon, size: 18, color: AppColors.primary),
      const SizedBox(width: 8),
      Text(label, style: _dFont(15, FontWeight.w700)),
    ],
  );

  Widget _avantPhoto(String? b64, AppLocalizations l) {
    if (b64 != null && b64.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.memory(
          base64Decode(b64),
          width: double.infinity,
          height: 220,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _photoPlaceholder(l),
        ),
      );
    }
    return _photoPlaceholder(l);
  }

  Widget _photoPlaceholder(AppLocalizations l) => Container(
    width: double.infinity,
    height: 220,
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.image_not_supported_outlined,
          size: 48,
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
        ),
        const SizedBox(height: 8),
        Text(
          l.t('photo_non_disponible'),
          style: _bFont(13, FontWeight.w400, c: AppColors.onSurfaceVariant),
        ),
      ],
    ),
  );

  Widget _addressCard(String adresse, AppLocalizations l) => Container(
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
            color: AppColors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.location_on_rounded,
            color: AppColors.primary,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.t('adresse'),
                style: _bFont(
                  11,
                  FontWeight.w500,
                  c: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 3),
              Text(adresse, style: _bFont(14, FontWeight.w600)),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _itineraireBtn(AppLocalizations l) => Material(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(100),
    child: InkWell(
      borderRadius: BorderRadius.circular(100),
      onTap: _launchNavigation,
      child: Ink(
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
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
              const Icon(
                Icons.navigation_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                l.t('itineraire'),
                style: _bFont(16, FontWeight.w700, c: Colors.white),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Google Maps',
                  style: _bFont(11, FontWeight.w500, c: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _apresZone(AppLocalizations l) {
    if (_afterImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Image.file(
              File(_afterImage!.path),
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                color: AppColors.primary,
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l.t('photo_apres_capturee'),
                      style: _bFont(13, FontWeight.w600, c: Colors.white),
                    ),
                    const Spacer(),
                    if (!_isSubmitting)
                      GestureDetector(
                        onTap: _captureAfterPhoto,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.camera_alt_outlined,
                                color: Colors.white,
                                size: 13,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                l.t('reprendre'),
                                style: _bFont(
                                  11,
                                  FontWeight.w500,
                                  c: Colors.white,
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
    return GestureDetector(
      onTap: _isCapturing ? null : _captureAfterPhoto,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: AppColors.primary.withValues(alpha: 0.40),
        ),
        child: Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.primaryFixed.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
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
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primaryFixed.withValues(alpha: 0.30),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_outlined,
                        color: AppColors.primary,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      l.t('appuyer_prendre_photo'),
                      style: _bFont(14, FontWeight.w600, c: AppColors.primary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l.t('apres_nettoyage'),
                      style: _bFont(
                        13,
                        FontWeight.w400,
                        c: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _infoNote(AppLocalizations l) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.primaryFixed.withValues(alpha: 0.14),
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
            l.t('photo_apres_preuve'),
            style: _bFont(13, FontWeight.w400, c: AppColors.onSurface, h: 1.5),
          ),
        ),
      ],
    ),
  );

  Widget _disabledBtn(AppLocalizations l) => Column(
    key: const ValueKey('disabled'),
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
              Icons.verified_rounded,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              l.t('cloturer_mission'),
              style: _bFont(
                16,
                FontWeight.w600,
                c: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Text(
        l.t('photo_apres_requise'),
        style: _bFont(12, FontWeight.w400, c: AppColors.onSurfaceVariant),
        textAlign: TextAlign.center,
      ),
    ],
  );
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    const double dashWidth = 8, dashSpace = 5, radius = 20;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..addRRect(
        RRect.fromLTRBR(
          0,
          0,
          size.width,
          size.height,
          const Radius.circular(radius),
        ),
      );
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

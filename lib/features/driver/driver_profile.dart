import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../main.dart' show toggleLocale, localeNotifier;
import '../auth/connexion_screen.dart';
import '../profile/confidentialite_screen.dart';
import '../profile/about_app_screen.dart';

/// Driver profile — mirrors ProfilCitoyenScreen layout with
/// mission count instead of score/points.
/// Now includes the language toggle tile and full i18n.
class DriverProfile extends StatefulWidget {
  const DriverProfile({super.key});

  @override
  State<DriverProfile> createState() => _DriverProfileState();
}

class _DriverProfileState extends State<DriverProfile> {
  String? _nom;
  String? _camionType;
  String? _matricule;
  bool _headerLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('citoyens')
          .doc(uid)
          .get();
      if (mounted && doc.exists) {
        final data = doc.data()!;
        setState(() {
          _nom = data['nom'] as String?;
          _camionType = data['camion_type'] as String?;
          _matricule = data['matricule'] as String?;
          _headerLoading = false;
        });
      } else if (mounted) {
        setState(() => _headerLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _headerLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    // Choose font families based on locale.
    TextStyle displayFont(double size, FontWeight weight, {Color? color}) =>
        l.isArabic
        ? GoogleFonts.tajawal(
            fontSize: size,
            fontWeight: weight,
            color: color ?? AppColors.onSurface,
          )
        : GoogleFonts.manrope(
            fontSize: size,
            fontWeight: weight,
            color: color ?? AppColors.onSurface,
          );

    TextStyle bodyFont(
      double size,
      FontWeight weight, {
      Color? color,
      double? height,
    }) => l.isArabic
        ? GoogleFonts.cairo(
            fontSize: size,
            fontWeight: weight,
            color: color ?? AppColors.onSurface,
            height: height,
          )
        : GoogleFonts.plusJakartaSans(
            fontSize: size,
            fontWeight: weight,
            color: color ?? AppColors.onSurface,
            height: height,
          );

    final initial = (_nom ?? 'Chauffeur').isNotEmpty
        ? (_nom![0].toUpperCase())
        : 'C';
    final vehicleStr = _camionType != null || _matricule != null
        ? '${_camionType ?? ''}${_camionType != null && _matricule != null ? ' — ' : ''}${_matricule ?? ''}'
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Green header with avatar ──────────────────────────
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                24,
                MediaQuery.of(context).padding.top + 60,
                24,
                32,
              ),
              decoration: const BoxDecoration(
                gradient: AppColors.driverHeroGradient,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(32),
                ),
              ),
              child: _headerLoading
                  ? const SizedBox(
                      height: 140,
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    )
                  : Column(
                children: [
                  // Avatar
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.20),
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: displayFont(
                          28,
                          FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _nom ?? l.t('chauffeur'),
                    style: displayFont(
                      22,
                      FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  if (vehicleStr != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _camionType ?? '',
                      style: bodyFont(13, FontWeight.w400, color: Colors.white70),
                    ),
                  ],
                  if (vehicleStr != null) ...[
                    const SizedBox(height: 16),
                    // Vehicle badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.local_shipping_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            vehicleStr,
                            style: displayFont(
                              14,
                              FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Missions Accomplies card ─────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.t('performance'),
                    style: displayFont(
                      18,
                      FontWeight.w700,
                    ).copyWith(letterSpacing: -0.3),
                  ),
                  const SizedBox(height: 14),

                  // Large mission count card
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('signalements')
                        .where('statut', isEqualTo: 'terminé')
                        .where('chauffeur_id', isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? '')
                        .snapshots(),
                    builder: (context, snapshot) {
                      final count = snapshot.hasData
                          ? snapshot.data!.docs.length
                          : 0;
                      final isLoading =
                          snapshot.connectionState == ConnectionState.waiting;

                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.driverSurface,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: AppColors.driverShadow,
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.driverPrimary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_circle_outline_rounded,
                                size: 32,
                                color: AppColors.driverPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: AppColors.primary,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(
                                    '$count',
                                    style: displayFont(
                                      48,
                                      FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                            const SizedBox(height: 4),
                            Text(
                              l.t('missions_accomplies'),
                              style: bodyFont(16, FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l.t('total_traites'),
                              style: bodyFont(
                                13,
                                FontWeight.w400,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 14),

                  // Quick stats row
                  Row(
                    children: [
                      _QuickStat(
                        label: l.t('en_cours'),
                        statutFilter: 'en cours',
                        icon: Icons.loop_rounded,
                        color: AppColors.statusInProgress,
                        l: l,
                      ),
                      const SizedBox(width: 12),
                      _QuickStat(
                        label: l.t('statut_en_attente'),
                        statutFilter: 'en attente',
                        icon: Icons.hourglass_empty_rounded,
                        color: AppColors.statusPendingAdmin,
                        l: l,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Account actions ──────────────────────────────────
                  Text(
                    l.t('compte'),
                    style: displayFont(
                      18,
                      FontWeight.w700,
                    ).copyWith(letterSpacing: -0.3),
                  ),
                  const SizedBox(height: 12),
                  _ActionTile(
                    icon: Icons.person_outline_rounded,
                    label: l.t('modifier_profil'),
                    l: l,
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Bientôt disponible',
                          style: GoogleFonts.plusJakartaSans(color: Colors.white),
                        ),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.all(16),
                        backgroundColor: AppColors.primary,
                      ),
                    ),
                  ),
                  _ActionTile(
                    icon: Icons.security_outlined,
                    label: l.t('confidentialite'),
                    l: l,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ConfidentialiteScreen(isDriver: true),
                        ),
                      );
                    },
                  ),
                  _ActionTile(
                    icon: Icons.info_outline_rounded,
                    label: l.isArabic ? 'حول التطبيق' : 'À propos',
                    l: l,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AboutAppScreen(),
                        ),
                      );
                    },
                  ),

                  // ── Language toggle tile ─────────────────────────────
                  ValueListenableBuilder<Locale>(
                    valueListenable: localeNotifier,
                    builder: (_, locale, __) {
                      final isFr = locale.languageCode == 'fr';
                      return _ActionTile(
                        icon: Icons.language_rounded,
                        label: l.t('changer_langue'),
                        trailingLabel: isFr ? 'FR → AR' : 'AR → FR',
                        onTap: toggleLocale,
                        l: l,
                      );
                    },
                  ),

                  _ActionTile(
                    icon: Icons.logout_rounded,
                    label: l.t('se_deconnecter'),
                    isDestructive: true,
                    l: l,
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const ConnexionScreen(),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 110),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Quick Stat Card ──────────────────────────────────────────────────────────
class _QuickStat extends StatelessWidget {
  const _QuickStat({
    required this.label,
    required this.statutFilter,
    required this.icon,
    required this.color,
    required this.l,
  });

  final String label;
  final String statutFilter;
  final IconData icon;
  final Color color;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('signalements')
            .where('statut', isEqualTo: statutFilter)
            .snapshots(),
        builder: (context, snapshot) {
          final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
          final isLoading = snapshot.connectionState == ConnectionState.waiting;

          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppColors.botanicalShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(height: 12),
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
                        style:
                            (l.isArabic
                                    ? GoogleFonts.tajawal(fontSize: 26)
                                    : GoogleFonts.manrope(fontSize: 26))
                                .copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                ),
                      ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style:
                      (l.isArabic
                              ? GoogleFonts.cairo(fontSize: 12)
                              : GoogleFonts.plusJakartaSans(fontSize: 12))
                          .copyWith(
                            color: AppColors.onSurfaceVariant,
                            height: 1.4,
                          ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Action Tile ──────────────────────────────────────────────────────────────
class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.l,
    this.isDestructive = false,
    this.onTap,
    this.trailingLabel,
  });

  final IconData icon;
  final String label;
  final AppLocalizations l;
  final bool isDestructive;
  final VoidCallback? onTap;
  final String? trailingLabel;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : AppColors.onSurface;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.botanicalShadow,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? AppColors.error : AppColors.primary,
          size: 22,
        ),
        title: Text(
          label,
          style:
              (l.isArabic
                      ? GoogleFonts.cairo(fontSize: 14)
                      : GoogleFonts.plusJakartaSans(fontSize: 14))
                  .copyWith(fontWeight: FontWeight.w500, color: color),
        ),
        trailing: trailingLabel != null
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  trailingLabel!,
                  style:
                      (l.isArabic
                              ? GoogleFonts.cairo(fontSize: 11)
                              : GoogleFonts.plusJakartaSans(fontSize: 11))
                          .copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                ),
              )
            : Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.onSurfaceVariant,
                textDirection: l.isArabic
                    ? TextDirection.rtl
                    : TextDirection.ltr,
              ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onTap: onTap ?? () {},
      ),
    );
  }
}

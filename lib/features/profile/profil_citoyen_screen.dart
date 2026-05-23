import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../shared/firestore/signalement_model.dart';
import '../../main.dart' show toggleLocale, localeNotifier;
import '../auth/inscription_screen.dart';

import 'modifier_profil_screen.dart';
import 'notifications_screen.dart';
import 'confidentialite_screen.dart';

class ProfilCitoyenScreen extends StatelessWidget {
  const ProfilCitoyenScreen({super.key});

  Stream<DocumentSnapshot> get _citoyenStream {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return FirebaseFirestore.instance.collection('citoyens').doc(uid).snapshots();
  }

  Stream<List<Signalement>> get _myReportsStream {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return FirebaseFirestore.instance
        .collection('signalements')
        .where('citoyen_id', isEqualTo: uid)
        .snapshots()
        .map((snap) => snap.docs.map(Signalement.fromFirestore).toList());
  }

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const InscriptionScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    // Locale-aware font helpers.
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

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _citoyenStream,
        builder: (context, profileSnap) {
          final profileData = profileSnap.data?.data() as Map<String, dynamic>? ?? {};
          final pseudo = profileData['pseudo'] ?? profileData['nom'] ?? 'Citoyen';
          final nomComplet = profileData['nom'] ?? pseudo;
          final points = profileData['points'] ?? 0;
          
          String dateInscriptionStr = 'Récemment';
          int joursActifs = 1;
          if (profileData['created_at'] is Timestamp) {
            final dateInscription = (profileData['created_at'] as Timestamp).toDate();
            dateInscriptionStr = DateFormat('MMM yyyy').format(dateInscription);
            joursActifs = DateTime.now().difference(dateInscription).inDays;
            if (joursActifs < 1) joursActifs = 1;
          }

          final initials = pseudo.trim().isNotEmpty ? pseudo.trim().substring(0, 1).toUpperCase() : 'C';

          return StreamBuilder<List<Signalement>>(
            stream: _myReportsStream,
            builder: (context, reportsSnap) {
              final reports = reportsSnap.data ?? [];
              final totalSignalements = reports.length;
              final acceptes = reports.where((r) => r.statut == 'en attente').length;
              final resolus = reports.where((r) => r.statut == 'terminé').length;

              return SingleChildScrollView(
                child: Column(
                  children: [
                    // ── Green header ─────────────────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.fromLTRB(
                        24,
                        MediaQuery.of(context).padding.top + 60,
                        24,
                        32,
                      ),
                      decoration: const BoxDecoration(
                        gradient: AppColors.heroGradient,
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(32),
                        ),
                      ),
                      child: Column(
                        children: [
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
                                initials,
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
                            pseudo,
                            style: displayFont(
                              22,
                              FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${l.t('membre_depuis')} $dateInscriptionStr',
                            style: bodyFont(13, FontWeight.w400, color: Colors.white70),
                          ),
                          const SizedBox(height: 16),
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
                                  Icons.stars_rounded,
                                  color: Colors.amber,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$points pts',
                                  style: displayFont(
                                    16,
                                    FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Stats grid ───────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.t('statistiques'),
                            style: displayFont(
                              18,
                              FontWeight.w700,
                            ).copyWith(letterSpacing: -0.3),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              _StatCard(
                                label: l.t('total_signalements'),
                                value: '$totalSignalements',
                                icon: Icons.assignment_outlined,
                                color: AppColors.statusAssigned,
                                l: l,
                              ),
                              const SizedBox(width: 12),
                              _StatCard(
                                label: l.t('signalements_acceptes'),
                                value: '$acceptes',
                                icon: Icons.thumb_up_outlined,
                                color: AppColors.primary,
                                l: l,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _StatCard(
                                label: l.t('signalements_resolus'),
                                value: '$resolus',
                                icon: Icons.check_circle_outline_rounded,
                                color: AppColors.statusCompleted,
                                l: l,
                              ),
                              const SizedBox(width: 12),
                              _StatCard(
                                label: l.t('jours_actifs'),
                                value: '$joursActifs',
                                icon: Icons.calendar_today_outlined,
                                color: AppColors.tertiary,
                                l: l,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // ── Account actions ──────────────────────────────────────
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
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const ModifierProfilScreen()));
                            },
                            l: l,
                          ),
                          _ActionTile(
                            icon: Icons.notifications_outlined,
                            label: l.t('notifications'),
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                            },
                            l: l,
                          ),

                          // ── Language toggle tile ─────────────────────────────────
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
                            icon: Icons.security_outlined,
                            label: l.t('confidentialite'),
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const ConfidentialiteScreen()));
                            },
                            l: l,
                          ),
                          _ActionTile(
                            icon: Icons.logout_rounded,
                            label: l.t('se_deconnecter'),
                            isDestructive: true,
                            onTap: () => _signOut(context),
                            l: l,
                          ),
                          const SizedBox(height: 110),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
          );
        }
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.l,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
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
            Text(
              value,
              style:
                  (l.isArabic
                          ? GoogleFonts.tajawal(fontSize: 26)
                          : GoogleFonts.manrope(fontSize: 26))
                      .copyWith(fontWeight: FontWeight.w700, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style:
                  (l.isArabic
                          ? GoogleFonts.cairo(fontSize: 12)
                          : GoogleFonts.plusJakartaSans(fontSize: 12))
                      .copyWith(color: AppColors.onSurfaceVariant, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Action Tile ──────────────────────────────────────────────────────────────
class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.l,
    this.isDestructive = false,
    this.trailingLabel,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final AppLocalizations l;
  final bool isDestructive;
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
        onTap: onTap,
      ),
    );
  }
}

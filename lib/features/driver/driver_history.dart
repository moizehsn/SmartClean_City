import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_localizations.dart';

/// History tab — shows all missions completed by the driver
/// with before/after photo thumbnails. Fully localised.
class DriverHistory extends StatelessWidget {
  const DriverHistory({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          l.t('historique_missions'),
          style:
              (l.isArabic
                      ? GoogleFonts.tajawal(fontSize: 20)
                      : GoogleFonts.manrope(fontSize: 20))
                  .copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                    letterSpacing: -0.3,
                  ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('signalements')
            .where('statut', isEqualTo: 'terminé')
            .where('chauffeur_id', isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? '')
            .orderBy('timestamp_fin', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // ── Loading ────────────────────────────────────────────────
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2.5,
              ),
            );
          }

          // ── Error ──────────────────────────────────────────────────
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: AppColors.error.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l.t('erreur_chargement'),
                      style:
                          (l.isArabic
                                  ? GoogleFonts.cairo(fontSize: 15)
                                  : GoogleFonts.plusJakartaSans(fontSize: 15))
                              .copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style:
                          (l.isArabic
                                  ? GoogleFonts.cairo(fontSize: 12)
                                  : GoogleFonts.plusJakartaSans(fontSize: 12))
                              .copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            );
          }

          // ── Empty ──────────────────────────────────────────────────
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primaryFixed.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.history_rounded,
                      size: 40,
                      color: AppColors.primary.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l.t('aucune_mission_terminee'),
                    style:
                        (l.isArabic
                                ? GoogleFonts.tajawal(fontSize: 18)
                                : GoogleFonts.manrope(fontSize: 18))
                            .copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l.t('missions_terminees_ici'),
                    style:
                        (l.isArabic
                                ? GoogleFonts.cairo(fontSize: 14)
                                : GoogleFonts.plusJakartaSans(fontSize: 14))
                            .copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }

          // ── List ───────────────────────────────────────────────────
          final docs = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _HistoryCard(data: data, l: l),
              );
            },
          );
        },
      ),
    );
  }
}

// ─── History Card ─────────────────────────────────────────────────────────────
class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.data, required this.l});

  final Map<String, dynamic> data;
  final AppLocalizations l;

  /// Formats the date with intl and forces LTR so numbers don't scramble
  /// in RTL mode.
  String _formatDate() {
    final ts = data['timestamp_fin'] as Timestamp?;
    if (ts == null) return l.t('date_inconnue');
    return DateFormat('dd/MM/yyyy – HH:mm').format(ts.toDate());
  }

  @override
  Widget build(BuildContext context) {
    final String adresse = data['adresse_lisible'] ?? l.t('adresse_inconnue');
    final String? photoBefore = data['photo_base64'];
    final String? photoAfter = data['photo_apres_base64'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.botanicalShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.statusCompleted.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.statusCompleted,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      adresse,
                      style:
                          (l.isArabic
                                  ? GoogleFonts.cairo(fontSize: 14)
                                  : GoogleFonts.plusJakartaSans(fontSize: 14))
                              .copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface,
                              ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // ── Force LTR on timestamp so numbers stay correct ──
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        _formatDate(),
                        style:
                            (l.isArabic
                                    ? GoogleFonts.cairo(fontSize: 12)
                                    : GoogleFonts.plusJakartaSans(fontSize: 12))
                                .copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.statusCompleted.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  l.t('statut_termine'),
                  style:
                      (l.isArabic
                              ? GoogleFonts.cairo(fontSize: 11)
                              : GoogleFonts.plusJakartaSans(fontSize: 11))
                          .copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.statusCompleted,
                          ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Before / After thumbnails ───────────────────────────
          Row(
            children: [
              Expanded(
                child: _PhotoThumbnail(
                  label: l.t('avant'),
                  base64Data: photoBefore,
                  l: l,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PhotoThumbnail(
                  label: l.t('apres'),
                  base64Data: photoAfter,
                  l: l,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Photo Thumbnail ──────────────────────────────────────────────────────────
class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail({
    required this.label,
    required this.base64Data,
    required this.l,
  });

  final String label;
  final String? base64Data;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style:
              (l.isArabic
                      ? GoogleFonts.cairo(fontSize: 11)
                      : GoogleFonts.plusJakartaSans(fontSize: 11))
                  .copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceVariant,
                  ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: base64Data != null && base64Data!.isNotEmpty
              ? Image.memory(
                  base64Decode(base64Data!),
                  width: double.infinity,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(),
                )
              : _placeholder(),
        ),
      ],
    );
  }

  Widget _placeholder() {
    return Container(
      width: double.infinity,
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 24,
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 4),
          Text(
            l.t('non_disponible'),
            style:
                (l.isArabic
                        ? GoogleFonts.cairo(fontSize: 10)
                        : GoogleFonts.plusJakartaSans(fontSize: 10))
                    .copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

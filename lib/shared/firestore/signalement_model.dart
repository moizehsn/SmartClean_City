import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_localizations.dart';

// ─── Signalement Model ────────────────────────────────────────────────────────
/// Typed representation of a document in the `signalements` Firestore collection.
/// Used by all Citizen screens (AccueilScreen, MesSignalementsScreen,
/// SignalementDetailScreen).
class Signalement {
  final String id; // Firestore doc ID (auto-generated)
  final String idCourt; // e.g. "#4829"
  final String citoyenId; // "user_mock"
  final String statut; // "en attente" | "en cours" | "terminé" | "rejeté"
  final String adresseLisible;
  final double latitude;
  final double longitude;
  final String photoBase64;
  final DateTime? timestamp;

  const Signalement({
    required this.id,
    required this.idCourt,
    required this.citoyenId,
    required this.statut,
    required this.adresseLisible,
    required this.latitude,
    required this.longitude,
    required this.photoBase64,
    this.timestamp,
  });

  // ── Factory: Firestore → Signalement ───────────────────────────────────────
  factory Signalement.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Signalement(
      id: doc.id,
      idCourt: (data['id_court'] as String?) ?? '#????',
      citoyenId: (data['citoyen_id'] as String?) ?? '',
      statut: (data['statut'] as String?) ?? 'en attente',
      adresseLisible:
          (data['adresse_lisible'] as String?) ?? 'Adresse inconnue',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      photoBase64: (data['photo_base64'] as String?) ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }

  // ── Status helpers ──────────────────────────────────────────────────────────

  /// Foreground color for the status badge.
  Color get statusColor {
    switch (statut) {
      case 'en attente':
        return AppColors.statusPendingAdmin; // Orange #E65100
      case 'en cours':
        return AppColors.statusInProgress; // Purple #6A1B9A
      case 'terminé':
        return AppColors.statusCompleted; // Green  #00450D
      case 'rejeté':
        return AppColors.statusRejected; // Red    #BA1A1A
      default:
        return AppColors.onSurfaceVariant;
    }
  }

  /// Background color for the status badge (10% opacity tint).
  Color get statusBgColor => statusColor.withOpacity(0.10);

  /// Human-readable French label.
  String get statusLabel {
    switch (statut) {
      case 'en attente':
        return 'statut_en_attente';
      case 'en cours':
        return 'statut_en_cours';
      case 'terminé':
        return 'statut_termine';
      case 'rejeté':
        return 'statut_rejete';
      default:
        return statut;
    }
  }

  /// Icon for the status badge.
  IconData get statusIcon {
    switch (statut) {
      case 'en attente':
        return Icons.hourglass_empty_rounded;
      case 'en cours':
        return Icons.loop_rounded;
      case 'terminé':
        return Icons.check_circle_outline_rounded;
      case 'rejeté':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline_rounded;
    }
  }

  /// Top-border / accent color used on MesSignalementsScreen cards.
  Color get borderColor => statusColor;

  /// Derived title — use address as report title since we have no separate "titre" field.
  String get titre {
    // Use the first part of the readable address as a short title
    final parts = adresseLisible.split(',');
    if (parts.isNotEmpty && parts[0].trim().isNotEmpty) {
      return parts[0].trim();
    }
    return 'Signalement';
  }

  // ── Relative-time helper ───────────────────────────────────────────────────
  /// Returns a French relative-time string (e.g. "il y a 2 heures").
  String get relativeTime {
    if (timestamp == null) return '';
    final diff = DateTime.now().difference(timestamp!);
    if (diff.inSeconds < 60) return "À l'instant";
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return 'il y a $h heure${h > 1 ? 's' : ''}';
    }
    final d = diff.inDays;
    if (d == 1) return 'hier';
    if (d < 7) return 'il y a $d jours';
    if (d < 14) return 'il y a 1 semaine';
    return 'il y a ${(d / 7).floor()} semaines';
  }

  // ── Timeline step logic ─────────────────────────────────────────────────────
  /// Returns how many timeline steps are "done" for this report's statut.
  /// Step indices: 0=reçu, 1=vérif IA, 2=assigné, 3=nettoyage
  int get doneSteps {
    switch (statut) {
      case 'en attente':
        return 2; // steps 0 & 1 done
      case 'en cours':
        return 3; // steps 0, 1, 2 done
      case 'terminé':
        return 4; // all done
      default:
        return 1; // rejeté / unknown → only received
    }
  }
}

// ─── Firestore Status Chip ────────────────────────────────────────────────────
/// Same pill shape as ReportStatusChip but driven by the Firestore `statut` string
/// instead of the MockData `ReportStatus` enum.
class FirestoreStatusBadge extends StatelessWidget {
  const FirestoreStatusBadge({super.key, required this.signalement});
  final Signalement signalement;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: signalement.statusBgColor,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            signalement.statusIcon,
            size: 12,
            color: signalement.statusColor,
          ),
          const SizedBox(width: 5),
          Text(
            AppLocalizations.of(context).t(signalement.statusLabel),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ).copyWith(color: signalement.statusColor),
          ),
        ],
      ),
    );
  }
}

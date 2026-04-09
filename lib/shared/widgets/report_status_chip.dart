import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

/// Enum representing all possible states of a citizen report.
enum ReportStatus {
  pendingAi,
  pendingAdmin,
  assigned,
  inProgress,
  completed,
  rejected,
}

extension ReportStatusX on ReportStatus {
  String get label {
    switch (this) {
      case ReportStatus.pendingAi:
        return 'Vérification IA';
      case ReportStatus.pendingAdmin:
        return 'En attente';
      case ReportStatus.assigned:
        return 'Assigné';
      case ReportStatus.inProgress:
        return 'En cours';
      case ReportStatus.completed:
        return 'Terminé';
      case ReportStatus.rejected:
        return 'Rejeté';
    }
  }

  Color get foregroundColor {
    switch (this) {
      case ReportStatus.pendingAi:
        return AppColors.statusPendingAi;
      case ReportStatus.pendingAdmin:
        return AppColors.statusPendingAdmin;
      case ReportStatus.assigned:
        return AppColors.statusAssigned;
      case ReportStatus.inProgress:
        return AppColors.statusInProgress;
      case ReportStatus.completed:
        return AppColors.statusCompleted;
      case ReportStatus.rejected:
        return AppColors.statusRejected;
    }
  }

  Color get backgroundColor => foregroundColor.withOpacity(0.10);

  IconData get icon {
    switch (this) {
      case ReportStatus.pendingAi:
        return Icons.psychology_outlined;
      case ReportStatus.pendingAdmin:
        return Icons.hourglass_empty_rounded;
      case ReportStatus.assigned:
        return Icons.local_shipping_outlined;
      case ReportStatus.inProgress:
        return Icons.loop_rounded;
      case ReportStatus.completed:
        return Icons.check_circle_outline_rounded;
      case ReportStatus.rejected:
        return Icons.cancel_outlined;
    }
  }
}

/// A small pill-shaped chip showing the report status.
class ReportStatusChip extends StatelessWidget {
  const ReportStatusChip({super.key, required this.status});

  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 12, color: status.foregroundColor),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: status.foregroundColor,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

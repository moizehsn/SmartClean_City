import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/firestore/signalement_model.dart';
import '../../shared/widgets/glass_container.dart';

class SignalementDetailScreen extends StatelessWidget {
  const SignalementDetailScreen({super.key, required this.signalement});
  final Signalement signalement;

  // ── Timeline steps ────────────────────────────────────────────────────────
  static const _timelineSteps = [
    ('Signalement reçu', 'Votre rapport a été enregistré'),
    ('Vérification IA', 'Analyse de la photo terminée'),
    ("Assigné à l'équipe", 'Équipe de nettoyage en route'),
    ('Nettoyage effectué', 'Confirmation visuelle en attente'),
  ];

  @override
  Widget build(BuildContext context) {
    final doneCount = signalement.doneSteps;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Row(
          children: [
            Text(
              signalement.idCourt,
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(width: 10),
            FirestoreStatusBadge(signalement: signalement),
          ],
        ),
        leading: const BackButton(color: AppColors.onSurface),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Address subtitle ──────────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 14, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    signalement.adresseLisible,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  signalement.relativeTime,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Photo ─────────────────────────────────────────────────────
            _PhotoSection(photoBase64: signalement.photoBase64),
            const SizedBox(height: 24),

            // ── Timeline ──────────────────────────────────────────────────
            _SectionLabel(label: "Suivi de l'intervention"),
            const SizedBox(height: 12),
            GlassContainer(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: List.generate(_timelineSteps.length, (i) {
                  final (title, sub) = _timelineSteps[i];
                  final done = i < doneCount;
                  final isActive = i == doneCount - 1; // last "done" step
                  final isLast = i == _timelineSteps.length - 1;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Step indicator ──────────────────────────────────
                      Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: done
                                  ? (isActive
                                      ? AppColors.primary
                                      : AppColors.primaryFixed)
                                  : AppColors.surfaceContainerHigh,
                              border: isActive
                                  ? Border.all(
                                      color: AppColors.primary, width: 2.5)
                                  : null,
                            ),
                            child: Center(
                              child: Icon(
                                done
                                    ? Icons.check_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                size: 16,
                                color: done
                                    ? (isActive
                                        ? Colors.white
                                        : AppColors.primaryContainer)
                                    : AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                          if (!isLast)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              width: 2,
                              height: 44,
                              color: i < doneCount - 1
                                  ? AppColors.primaryFixed
                                  : AppColors.surfaceContainerHigh,
                            ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      // ── Step text ────────────────────────────────────────
                      Expanded(
                        child: Padding(
                          padding:
                              EdgeInsets.only(bottom: isLast ? 0 : 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 5),
                              Text(
                                title,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: done
                                      ? AppColors.onSurface
                                      : AppColors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                sub,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
            const SizedBox(height: 20),

            // ── Location ─────────────────────────────────────────────────
            _SectionLabel(label: 'Localisation'),
            const SizedBox(height: 12),
            _InfoCard(children: [
              _InfoRow(
                  icon: Icons.location_city_rounded,
                  text: signalement.adresseLisible),
              _InfoRow(
                  icon: Icons.map_outlined,
                  text:
                      '${signalement.latitude.toStringAsFixed(5)}, ${signalement.longitude.toStringAsFixed(5)}'),
            ]),
            const SizedBox(height: 20),

            // ── Type de déchet ────────────────────────────────────────────
            _SectionLabel(label: 'Type de déchet'),
            const SizedBox(height: 12),
            _InfoCard(children: [
              _InfoRow(
                  icon: Icons.delete_outline_rounded,
                  text: 'Ordures ménagères'),
            ]),
            const SizedBox(height: 20),

            // ── AI analysis ───────────────────────────────────────────────
            _SectionLabel(label: 'Analyse IA'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryFixed.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.psychology_outlined,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Dépassement de capacité confirmé. Intervention prioritaire recommandée dans les 24h.',
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
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _PhotoSection extends StatelessWidget {
  const _PhotoSection({required this.photoBase64});
  final String photoBase64;

  @override
  Widget build(BuildContext context) {
    if (photoBase64.isEmpty) {
      return _placeholder();
    }
    try {
      final bytes = base64Decode(photoBase64);
      return ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Image.memory(
          bytes,
          width: double.infinity,
          height: 220,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(),
        ),
      );
    } catch (_) {
      return _placeholder();
    }
  }

  Widget _placeholder() => Container(
        height: 220,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_outlined,
                  size: 48,
                  color: AppColors.onSurfaceVariant.withOpacity(0.5)),
              const SizedBox(height: 8),
              Text(
                'Photo du signalement',
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

// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.onSurface,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.botanicalShadow,
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

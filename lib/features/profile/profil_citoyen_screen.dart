import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/mock/mock_data.dart';

class ProfilCitoyenScreen extends StatelessWidget {
  const ProfilCitoyenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Green header with avatar ──────────────────────
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                  24, MediaQuery.of(context).padding.top + 60, 24, 32),
              decoration: const BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.20),
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: Center(
                      child: Text(
                        'AK',
                        style: GoogleFonts.manrope(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(MockUser.nom,
                      style: GoogleFonts.manrope(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  const SizedBox(height: 6),
                  Text('Membre depuis ${MockUser.membreDepuis}',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13, color: Colors.white70)),
                  const SizedBox(height: 16),
                  // Score badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.3), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.stars_rounded,
                            color: Colors.amber, size: 18),
                        const SizedBox(width: 6),
                        Text('${MockUser.score} pts',
                            style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Stats grid ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Statistiques',
                      style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                          letterSpacing: -0.3)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _StatCard(
                          label: 'Total\nSignalements',
                          value: '${MockUser.totalSignalements}',
                          icon: Icons.assignment_outlined,
                          color: AppColors.statusAssigned),
                      const SizedBox(width: 12),
                      _StatCard(
                          label: 'Signalements\nAcceptés',
                          value: '${MockUser.acceptes}',
                          icon: Icons.thumb_up_outlined,
                          color: AppColors.primary),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _StatCard(
                          label: 'Signalements\nRésolus',
                          value: '${MockUser.resolus}',
                          icon: Icons.check_circle_outline_rounded,
                          color: AppColors.statusCompleted),
                      const SizedBox(width: 12),
                      _StatCard(
                          label: 'Jours\nActifs',
                          value: '${MockUser.joursActifs}',
                          icon: Icons.calendar_today_outlined,
                          color: AppColors.tertiary),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Actions
                  Text('Compte',
                      style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                          letterSpacing: -0.3)),
                  const SizedBox(height: 12),
                  _ActionTile(
                      icon: Icons.person_outline_rounded,
                      label: 'Modifier le profil'),
                  _ActionTile(
                      icon: Icons.notifications_outlined,
                      label: 'Notifications'),
                  _ActionTile(
                      icon: Icons.security_outlined, label: 'Confidentialité'),
                  _ActionTile(
                      icon: Icons.logout_rounded,
                      label: 'Se déconnecter',
                      isDestructive: true),
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

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
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 12),
            Text(value,
                style: GoogleFonts.manrope(
                    fontSize: 26, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 4),
            Text(label,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                    height: 1.4)),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    this.isDestructive = false,
  });
  final IconData icon;
  final String label;
  final bool isDestructive;

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
        leading:
            Icon(icon, color: isDestructive ? AppColors.error : AppColors.primary, size: 22),
        title: Text(label,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 14, fontWeight: FontWeight.w500, color: color)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded,
            size: 14, color: AppColors.onSurfaceVariant),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onTap: () {},
      ),
    );
  }
}

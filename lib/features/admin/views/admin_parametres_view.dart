import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../core/constants/app_colors.dart';

/// Admin — Paramètres: admin profile info + change password
class AdminParametresView extends StatelessWidget {
  const AdminParametresView({super.key});

  @override
  Widget build(BuildContext context) {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    final currentUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('citoyens')
          .doc(currentUser?.uid ?? '')
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final nom = data['nom'] ?? 'Administrateur';
        final pseudo = data['pseudo'] ?? nom.split(' ').first;
        final email = data['email'] ?? currentUser?.email ?? '—';
        final phone = data['telephone'] ?? '—';
        final createdAt = (data['created_at'] as Timestamp?)?.toDate();
        final initial = pseudo.isNotEmpty ? pseudo[0].toUpperCase() : 'A';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Title ─────────────────────────────────────────────
              Text(
                isAr ? 'الإعدادات' : 'Paramètres',
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isAr ? 'إدارة ملف المسؤول' : 'Gérez votre profil administrateur',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),

              // ── Profile Card ──────────────────────────────────────
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 600),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppColors.botanicalShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Avatar + name header ─────────────────────────
                    Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              initial,
                              style: GoogleFonts.manrope(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nom,
                                style: GoogleFonts.manrope(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text(
                                  isAr ? 'مسؤول' : 'Administrateur',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Divider(
                      color: AppColors.outlineVariant.withOpacity(0.3),
                      height: 1,
                    ),
                    const SizedBox(height: 28),

                    // ── Info rows ────────────────────────────────────
                    _InfoRow(
                      icon: Icons.badge_outlined,
                      label: isAr ? 'الاسم المستعار' : 'Pseudo',
                      value: pseudo,
                    ),
                    const SizedBox(height: 18),
                    _InfoRow(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: email,
                    ),
                    const SizedBox(height: 18),
                    _InfoRow(
                      icon: Icons.phone_outlined,
                      label: isAr ? 'الهاتف' : 'Téléphone',
                      value: phone,
                    ),
                    const SizedBox(height: 18),
                    _InfoRow(
                      icon: Icons.calendar_today_rounded,
                      label: isAr ? 'عضو منذ' : 'Membre depuis',
                      value: createdAt != null
                          ? DateFormat('dd MMMM yyyy', isAr ? 'ar' : 'fr').format(createdAt)
                          : '—',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Security section ──────────────────────────────────
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 600),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppColors.botanicalShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.security_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          isAr ? 'الأمان' : 'Sécurité',
                          style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isAr ? 'غيّر كلمة المرور لتعزيز أمان حسابك.' : 'Modifiez votre mot de passe pour renforcer la sécurité de votre compte.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () async {
                        if (email == '—' || email.isEmpty) return;

                        try {
                          await FirebaseAuth.instance
                              .sendPasswordResetEmail(email: email);

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isAr ? '✓ تم إرسال بريد إعادة تعيين كلمة المرور إلى $email' : '✓ Email de réinitialisation envoyé à $email',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                  ),
                                ),
                                backgroundColor: AppColors.primary,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${isAr ? 'خطأ' : 'Erreur'}: $e',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                  ),
                                ),
                                backgroundColor: AppColors.error,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.lock_reset_rounded, size: 18),
                      label: Text(
                        isAr ? 'تغيير كلمة المرور' : 'Changer le mot de passe',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── System Info ────────────────────────────────────────
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 600),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppColors.botanicalShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.tertiary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.info_outline_rounded,
                            color: AppColors.tertiary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          isAr ? 'معلومات النظام' : 'Informations Système',
                          style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _InfoRow(
                      icon: Icons.eco_rounded,
                      label: isAr ? 'التطبيق' : 'Application',
                      value: 'SmartClean City v1.0',
                    ),
                    const SizedBox(height: 14),
                    _InfoRow(
                      icon: Icons.cloud_outlined,
                      label: 'Backend',
                      value: 'Firebase / Cloud Firestore',
                    ),
                    const SizedBox(height: 14),
                    _InfoRow(
                      icon: Icons.smart_toy_outlined,
                      label: isAr ? 'الرؤية الذكية' : 'IA Vision',
                      value: isAr ? 'Gemini 1.5 Flash (معطل مؤقتاً)' : 'Gemini 1.5 Flash (Temporairement désactivée)',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }
}

// ── Info Row ──────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 12),
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

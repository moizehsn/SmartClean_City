import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_localizations.dart';

class ModifierProfilScreen extends StatefulWidget {
  const ModifierProfilScreen({super.key});

  @override
  State<ModifierProfilScreen> createState() => _ModifierProfilScreenState();
}

class _ModifierProfilScreenState extends State<ModifierProfilScreen> {
  final _pseudoController = TextEditingController();
  String _nom = '';
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('citoyens').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _nom = data['nom'] ?? 'Citoyen';
        _pseudoController.text = data['pseudo'] ?? data['nom'] ?? 'Citoyen';
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('citoyens').doc(uid).update({
        'pseudo': _pseudoController.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).isArabic ? 'تم تحديث الملف الشخصي' : 'Profil mis à jour',
              style: GoogleFonts.plusJakartaSans(),
            ),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur de mise à jour',
              style: GoogleFonts.plusJakartaSans(),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) return;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).isArabic
                  ? 'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني'
                  : 'Un lien de réinitialisation a été envoyé à votre email.',
              style: GoogleFonts.plusJakartaSans(),
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur d\'envoi', style: GoogleFonts.plusJakartaSans()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final labelStyle = (l.isArabic ? GoogleFonts.cairo() : GoogleFonts.plusJakartaSans()).copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.onSurfaceVariant,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l.t('modifier_profil'),
          style: (l.isArabic ? GoogleFonts.tajawal() : GoogleFonts.manrope()).copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.onSurface),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.isArabic ? 'الاسم الكامل (للقراءة فقط)' : 'Nom complet (Lecture seule)', style: labelStyle),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: _nom,
                    enabled: false,
                    style: GoogleFonts.plusJakartaSans(color: Colors.grey[600]),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(l.isArabic ? 'الاسم المستعار (يظهر علناً)' : 'Pseudo (affiché publiquement)', style: labelStyle),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _pseudoController,
                    style: GoogleFonts.plusJakartaSans(color: AppColors.onSurface),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.surfaceContainerLowest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              l.isArabic ? 'حفظ التغييرات' : 'Enregistrer les modifications',
                              style: (l.isArabic ? GoogleFonts.tajawal() : GoogleFonts.plusJakartaSans()).copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Divider(color: Colors.grey[300]),
                  const SizedBox(height: 20),
                  Text(
                    l.isArabic ? 'الأمان' : 'Sécurité',
                    style: (l.isArabic ? GoogleFonts.tajawal() : GoogleFonts.manrope()).copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _resetPassword,
                    icon: const Icon(Icons.lock_reset_rounded, color: AppColors.primary),
                    label: Text(
                      l.isArabic ? 'تغيير كلمة المرور' : 'Changer le mot de passe',
                      style: (l.isArabic ? GoogleFonts.cairo() : GoogleFonts.plusJakartaSans()).copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/primary_button.dart';
import '../../core/services/auth_service.dart';
import '../../core/l10n/app_localizations.dart';
import 'complete_profile_screen.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  bool _isLoading = false;

  Future<void> _checkVerification() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.currentUser?.reload();
      final isVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;
      
      if (!mounted) return;
      
      if (isVerified) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CompleteProfileScreen()),
        );
      } else {
        final l = AppLocalizations.of(context);
        final errorMsg = l.isArabic 
            ? "البريد الإلكتروني غير مفعل. يرجى الضغط على الرابط في الرسالة."
            : "Email non vérifié. Veuillez cliquer sur le lien dans l'email.";
        _showError(errorMsg);
      }
    } catch (e) {
      if (mounted) {
        _showError('Erreur de vérification.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendLink() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lien renvoyé avec succès.', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      _showError('Erreur lors du renvoi du lien.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancel() async {
    await AuthService().signOut();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.plusJakartaSans(color: Colors.white)),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final spamWarning = l.isArabic
        ? "⚠️ إذا لم تجد الرسالة، يرجى التحقق من مجلد الرسائل غير المرغوب فيها (Spam)."
        : "⚠️ Si vous ne trouvez pas l'email, veuillez vérifier votre dossier Spam (Courrier indésirable).";

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mark_email_unread_outlined, size: 80, color: AppColors.primary),
              const SizedBox(height: 24),
              Text(
                'Vérifiez votre email',
                style: GoogleFonts.manrope(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Un lien de vérification a été envoyé à ${FirebaseAuth.instance.currentUser?.email}.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  color: AppColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              if (_isLoading)
                const CircularProgressIndicator(color: AppColors.primary)
              else
                Column(
                  children: [
                    PrimaryButton(
                      label: 'J\'ai vérifié',
                      onPressed: _checkVerification,
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _resendLink,
                      child: Text(
                        'Renvoyer le lien',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _cancel,
                      child: Text(
                        'Annuler',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

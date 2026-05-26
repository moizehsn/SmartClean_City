import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/primary_button.dart';
import '../../core/services/auth_service.dart';
import '../../core/l10n/app_localizations.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final l = AppLocalizations.of(context);
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _showSnackBar(l.t('veuillez_entrer_email'), isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService().sendPasswordResetEmail(email);
      if (!mounted) return;
      _showSnackBar('${l.t('lien_envoye_msg')} ($email)');
      Navigator.of(context).pop();
    } catch (e) {
      _showSnackBar(l.t('erreur_lien'), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.plusJakartaSans(color: Colors.white)),
        backgroundColor: isError ? Colors.red : AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l.t('mot_de_passe_oublie_sans_point'),
          style: (l.isArabic ? GoogleFonts.tajawal() : GoogleFonts.manrope()).copyWith(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.onSurface),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.t('reinitialisation'),
                style: (l.isArabic ? GoogleFonts.tajawal() : GoogleFonts.manrope()).copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l.t('entrez_email_reinitialisation'),
                style: (l.isArabic ? GoogleFonts.cairo() : GoogleFonts.plusJakartaSans()).copyWith(
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              
              AppTextField(
                hintText: l.t('adresse_email'),
                controller: _emailCtrl,
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 32),
              
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : PrimaryButton(
                      label: l.t('envoyer_lien'),
                      onPressed: _resetPassword,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

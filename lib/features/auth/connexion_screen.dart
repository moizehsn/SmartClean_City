import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/primary_button.dart';
import '../../core/services/auth_service.dart';
import 'inscription_screen.dart';
import 'forgot_password_screen.dart';

class ConnexionScreen extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  const ConnexionScreen({super.key, this.onLoginSuccess});

  @override
  State<ConnexionScreen> createState() => _ConnexionScreenState();
}

class _ConnexionScreenState extends State<ConnexionScreen> {
  final _emailCtrl = TextEditingController();
  final _mdpCtrl = TextEditingController();
  bool _obscureMdp = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _mdpCtrl.dispose();
    super.dispose();
  }

  Future<void> _seConnecter() async {
    final email = _emailCtrl.text.trim();
    final password = _mdpCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Veuillez remplir tous les champs.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await AuthService()
          .signInWithEmailAndPassword(email, password)
          .timeout(const Duration(seconds: 15));

      if (result?.user == null) {
        if (mounted) _showError('Erreur de connexion.');
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      // Signal AuthWrapper to rebuild and read currentUser synchronously.
      widget.onLoginSuccess?.call();
      return;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        if (mounted) _showError('Identifiants incorrects.');
      } else {
        if (mounted) _showError(e.message ?? 'Erreur de connexion.');
      }
    } catch (e) {
      if (mounted) _showError('Erreur inattendue.');
    }
    // Only reachable on error — reset loading
    if (mounted) setState(() => _isLoading = false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(color: Colors.white),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Container(
            height: size.height * 0.40,
            decoration: const BoxDecoration(gradient: AppColors.heroGradient),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // ── Logo ───────────────────────────────────────
                  SizedBox(
                    height: size.height * 0.28,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.30),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.eco_rounded,
                            color: Colors.white,
                            size: 38,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'SmartClean City',
                          style: GoogleFonts.manrope(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Propreté Urbaine par l'IA",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Form Card ───────────────────────────────────
                  Container(
                    constraints: BoxConstraints(minHeight: size.height * 0.72),
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bienvenue 👋',
                          style: GoogleFonts.manrope(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Connectez-vous pour signaler des déchets.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 28),

                        AppTextField(
                          hintText: 'Adresse email',
                          controller: _emailCtrl,
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          hintText: 'Mot de passe',
                          controller: _mdpCtrl,
                          prefixIcon: Icons.lock_outline_rounded,
                          obscureText: _obscureMdp,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _seConnecter(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureMdp
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppColors.onSurfaceVariant,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _obscureMdp = !_obscureMdp),
                          ),
                        ),
                        const SizedBox(height: 4),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()));
                            },
                            child: Text(
                              'Mot de passe oublié ?',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),

                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : PrimaryButton(
                                label: 'Se connecter',
                                onPressed: _seConnecter,
                              ),
                        const SizedBox(height: 22),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Vous n'avez pas de compte ? ",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const InscriptionScreen()));
                              },
                              child: Text(
                                "S'inscrire",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

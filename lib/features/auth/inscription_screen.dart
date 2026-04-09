import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/navigation/main_shell.dart';
import 'connexion_screen.dart';

class InscriptionScreen extends StatefulWidget {
  const InscriptionScreen({super.key});

  @override
  State<InscriptionScreen> createState() => _InscriptionScreenState();
}

class _InscriptionScreenState extends State<InscriptionScreen> {
  final _nomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _mdpCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscureMdp = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nomCtrl.dispose();
    _emailCtrl.dispose();
    _mdpCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _creerCompte() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  void _allerConnexion() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ConnexionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Hero gradient
          Container(
            height: size.height * 0.40,
            decoration: const BoxDecoration(gradient: AppColors.heroGradient),
          ),

          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // ── Logo ──────────────────────────────────────────
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
                                width: 1),
                          ),
                          child: const Icon(Icons.eco_rounded,
                              color: Colors.white, size: 38),
                        ),
                        const SizedBox(height: 14),
                        Text('SmartClean City',
                            style: GoogleFonts.manrope(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.5)),
                        const SizedBox(height: 4),
                        Text("Propreté Urbaine par l'IA",
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 13, color: Colors.white70)),
                      ],
                    ),
                  ),

                  // ── Form Card ────────────────────────────────────
                  Container(
                    constraints:
                        BoxConstraints(minHeight: size.height * 0.72),
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Créer un Compte',
                            style: GoogleFonts.manrope(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                                letterSpacing: -0.5)),
                        const SizedBox(height: 6),
                        Text('Rejoignez-nous pour une ville plus verte.',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                color: AppColors.onSurfaceVariant)),
                        const SizedBox(height: 28),

                        AppTextField(
                          hintText: 'Nom complet',
                          controller: _nomCtrl,
                          prefixIcon: Icons.person_outline_rounded,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 14),
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
                          textInputAction: TextInputAction.next,
                          suffixIcon: IconButton(
                            icon: Icon(
                                _obscureMdp
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppColors.onSurfaceVariant,
                                size: 20),
                            onPressed: () =>
                                setState(() => _obscureMdp = !_obscureMdp),
                          ),
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          hintText: 'Confirmer le mot de passe',
                          controller: _confirmCtrl,
                          prefixIcon: Icons.lock_outline_rounded,
                          obscureText: _obscureConfirm,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _creerCompte(),
                          suffixIcon: IconButton(
                            icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppColors.onSurfaceVariant,
                                size: 20),
                            onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),
                        const SizedBox(height: 28),

                        PrimaryButton(
                          label: 'Créer un compte',
                          onPressed: _creerCompte,
                        ),
                        const SizedBox(height: 22),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Vous avez déjà un compte ? ',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    color: AppColors.onSurfaceVariant)),
                            GestureDetector(
                              onTap: _allerConnexion,
                              child: Text('Se connecter',
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary)),
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

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/primary_button.dart';
import '../../core/services/auth_service.dart';
import 'auth_wrapper.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _phoneCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  String? _profession;
  bool _isLoading = false;

  final List<String> _professions = [
    'Étudiant / طالب',
    'Employé / موظف',
    'Indépendant / عمل حر',
    'Autre / أخرى'
  ];

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitProfile() async {
    final phone = _phoneCtrl.text.trim();
    final ageText = _ageCtrl.text.trim();
    
    if (phone.isEmpty || ageText.isEmpty || _profession == null) {
      _showError('Veuillez remplir tous les champs.');
      return;
    }

    final age = int.tryParse(ageText);
    if (age == null || age <= 0) {
      _showError('Âge invalide.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService().completeUserProfile(
        phone: phone,
        age: age,
        profession: _profession!,
      );
      if (!mounted) return;
      // Rebuild the wrapper
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
        (route) => false,
      );
    } catch (e) {
      _showError('Erreur lors de la sauvegarde du profil.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.plusJakartaSans(color: Colors.white)),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Compléter le profil', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
        centerTitle: true,
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dernière étape !',
                style: GoogleFonts.manrope(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ces informations nous aident à mieux comprendre notre communauté et à vous attribuer des points.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              
              AppTextField(
                hintText: 'Numéro de téléphone',
                controller: _phoneCtrl,
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              
              AppTextField(
                hintText: 'Âge',
                controller: _ageCtrl,
                prefixIcon: Icons.cake_outlined,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _profession,
                hint: Text('Profession', style: GoogleFonts.plusJakartaSans(color: AppColors.onSurfaceVariant)),
                items: _professions.map((p) => DropdownMenuItem(value: p, child: Text(p, style: GoogleFonts.plusJakartaSans()))).toList(),
                onChanged: (val) => setState(() => _profession = val),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.work_outline, color: AppColors.primary),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : PrimaryButton(
                      label: 'Terminer',
                      onPressed: _submitProfile,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

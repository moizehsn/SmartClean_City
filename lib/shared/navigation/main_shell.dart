import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../features/home/accueil_screen.dart';
import '../../features/reports/mes_signalements_screen.dart';
import '../../features/reports/nouveau_signalement_screen.dart';
import '../../features/chatbot/eco_bot_screen.dart';
import '../../features/profile/profil_citoyen_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});
  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  static const _screens = [
    AccueilScreen(),
    MesSignalementsScreen(),
    EcoBotScreen(),
    ProfilCitoyenScreen(),
  ];

  // Icon pairs — labels are built from AppLocalizations at build-time.
  static const _navIcons = [
    (Icons.home_outlined, Icons.home_rounded),
    (Icons.analytics_outlined, Icons.analytics_rounded),
    (Icons.smart_toy_outlined, Icons.smart_toy_rounded),
    (Icons.person_outline_rounded, Icons.person_rounded),
  ];

  // Translation keys matching each tab.
  static const _navKeys = ['accueil', 'signalements', 'ecobot', 'profil'];

  void _ouvrirNouveauSignalement() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const NouveauSignalementScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isHome = _currentIndex == 0;

    // Build nav items with translated labels.
    final navItems = List.generate(_navIcons.length, (i) {
      final (icon, activeIcon) = _navIcons[i];
      return (icon, activeIcon, l.t(_navKeys[i]));
    });

    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _currentIndex, children: _screens),

      // ── Dynamic FAB — visible only on tabs 0 & 1 ─────────────────────────
      floatingActionButton: (_currentIndex <= 1)
          ? FloatingActionButton(
              onPressed: _ouvrirNouveauSignalement,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              shape: const CircleBorder(),
              child: const Icon(Icons.add_rounded, size: 28),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        items: navItems,
        onTap: (i) => setState(() => _currentIndex = i),
        isArabic: l.isArabic,
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.currentIndex,
    required this.items,
    required this.onTap,
    required this.isArabic,
  });

  final int currentIndex;
  final List<(IconData, IconData, String)> items;
  final void Function(int) onTap;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest.withValues(alpha: 0.90),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.20),
                width: 1,
              ),
              boxShadow: AppColors.botanicalShadow,
            ),
            child: Row(
              children: List.generate(items.length, (i) {
                final (icon, activeIcon, label) = items[i];
                final isActive = i == currentIndex;
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (c, a) =>
                              ScaleTransition(scale: a, child: c),
                          child: Icon(
                            isActive ? activeIcon : icon,
                            key: ValueKey(isActive),
                            size: 24,
                            color: isActive
                                ? AppColors.primary
                                : AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          style:
                              (isArabic
                                      ? GoogleFonts.cairo(fontSize: 11)
                                      : GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                        ))
                                  .copyWith(
                                    fontWeight: isActive
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: isActive
                                        ? AppColors.primary
                                        : AppColors.onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

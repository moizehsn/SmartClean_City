import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/constants/app_colors.dart';
import 'driver_dashboard.dart';
import 'driver_map.dart';
import 'driver_history.dart';
import 'driver_profile.dart';

/// Main navigation shell for the Driver (Chauffeur) role.
/// Uses a shared [ValueNotifier<LatLng?>] to let the Dashboard trigger
/// a map camera animation when a pending mission card is tapped.
class DriverMainScreen extends StatefulWidget {
  const DriverMainScreen({super.key});

  @override
  State<DriverMainScreen> createState() => _DriverMainScreenState();
}

class _DriverMainScreenState extends State<DriverMainScreen> {
  int _currentIndex = 0;

  /// Shared notifier: Dashboard writes a LatLng, Map listens and animates.
  late final ValueNotifier<LatLng?> _focusTarget;

  /// Built once in initState so IndexedStack never recreates the widgets.
  late final List<Widget> _screens;

  static const _navItems = [
    (Icons.dashboard_outlined, Icons.dashboard_rounded, 'Accueil'),
    (Icons.map_outlined, Icons.map_rounded, 'Carte'),
    (Icons.history_outlined, Icons.history_rounded, 'Historique'),
    (Icons.person_outline_rounded, Icons.person_rounded, 'Profil'),
  ];

  @override
  void initState() {
    super.initState();
    _focusTarget = ValueNotifier(null);
    _screens = [
      DriverDashboard(
        onNavigateToMap: () => setState(() => _currentIndex = 1),
        focusTarget: _focusTarget,
      ),
      DriverMap(focusTarget: _focusTarget),
      const DriverHistory(),
      const DriverProfile(),
    ];
  }

  @override
  void dispose() {
    _focusTarget.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _DriverBottomNav(
        currentIndex: _currentIndex,
        items: _navItems,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ─── Glassmorphic Bottom Nav (identical style to Citizen) ──────────────────────
class _DriverBottomNav extends StatelessWidget {
  const _DriverBottomNav({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  final int currentIndex;
  final List<(IconData, IconData, String)> items;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 0, 16, MediaQuery.of(context).padding.bottom + 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest.withOpacity(0.90),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                  color: AppColors.outlineVariant.withOpacity(0.20), width: 1),
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
                          child: Icon(isActive ? activeIcon : icon,
                              key: ValueKey(isActive),
                              size: 24,
                              color: isActive
                                  ? AppColors.primary
                                  : AppColors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
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

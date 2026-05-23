import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../auth/connexion_screen.dart';
import 'views/admin_dashboard_view.dart';
import 'views/admin_signalements_view.dart';
import 'views/admin_citoyens_view.dart';
import 'views/admin_parametres_view.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Admin Dashboard 
// ─────────────────────────────────────────────────────────────────────────────

class AdminDashboardShell extends StatefulWidget {
  const AdminDashboardShell({super.key});

  @override
  State<AdminDashboardShell> createState() => _AdminDashboardShellState();
}

class _AdminDashboardShellState extends State<AdminDashboardShell> {
  int _selectedIndex = 0;
  bool _isArabic = false;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Menu items (dynamic labels for Arabic) ──────────────────────────────────
  static const _frLabels = [
    'Dashboard',
    'Gestion Signalements',
    'Utilisateurs',
    'Paramètres',
  ];
  static const _arLabels = [
    'لوحة القيادة',
    'إدارة البلاغات',
    'المستخدمين',
    'الإعدادات',
  ];

  List<_SidebarItem> get _menuItems {
    final labels = _isArabic ? _arLabels : _frLabels;
    return [
      _SidebarItem(icon: Icons.dashboard_rounded, label: labels[0]),
      _SidebarItem(icon: Icons.assignment_rounded, label: labels[1]),
      _SidebarItem(icon: Icons.people_rounded, label: labels[2]),
      _SidebarItem(icon: Icons.settings_rounded, label: labels[3]),
    ];
  }

  // ── Real views ─────────────────────────────────────────────────────────────
  List<Widget> _views() => [
        const AdminDashboardView(),
        AdminSignalementsView(searchQuery: _searchQuery),
        AdminCitoyensView(searchQuery: _searchQuery),
        const AdminParametresView(),
      ];

  Widget _buildContentView() => _views()[_selectedIndex];

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ConnexionScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Directionality(
        textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: Row(
          children: [
            // ── Left Sidebar ─────────────────────────────────────────────────
            _AdminSidebar(
              items: _menuItems,
              selectedIndex: _selectedIndex,
              onItemSelected: (i) => setState(() => _selectedIndex = i),
              onLogout: _signOut,
              isArabic: _isArabic,
            ),

            // ── Vertical divider ─────────────────────────────────────────────
            Container(width: 1, color: AppColors.outlineVariant.withOpacity(0.3)),

            // ── Main content area ────────────────────────────────────────────
            Expanded(
              child: Column(
                children: [
                  // ── Top bar ──────────────────────────────────────────────
                  _AdminTopBar(
                    title: _menuItems[_selectedIndex].label,
                    isArabic: _isArabic,
                    onToggleLanguage: () => setState(() => _isArabic = !_isArabic),
                    searchCtrl: _searchCtrl,
                    searchQuery: _searchQuery,
                  ),
                  // ── Content ──────────────────────────────────────────────
                  Expanded(child: _buildContentView()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sidebar
// ─────────────────────────────────────────────────────────────────────────────

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onLogout,
    this.isArabic = false,
  });

  final List<_SidebarItem> items;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final VoidCallback onLogout;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF002408), // Deep botanical green
            Color(0xFF00350B), // Slightly lighter
            Color(0xFF00450D), // AppColors.primary
          ],
        ),
      ),
      child: Column(
        children: [
          // ── Logo / Brand ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 8),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                    ),
                  ),
                  child: const Icon(
                    Icons.eco_rounded,
                    color: Color(0xFF92D78C),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SmartClean',
                      style: GoogleFonts.manrope(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      isArabic ? 'لوحة الإدارة' : 'Admin Panel',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(
              color: Colors.white.withOpacity(0.10),
              height: 1,
            ),
          ),
          const SizedBox(height: 12),

          // ── Menu Items ──────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final item = items[i];
                final isActive = i == selectedIndex;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => onItemSelected(i),
                      borderRadius: BorderRadius.circular(12),
                      splashColor: Colors.white.withOpacity(0.05),
                      hoverColor: Colors.white.withOpacity(0.05),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.white.withOpacity(0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: isActive
                              ? Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                )
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item.icon,
                              size: 20,
                              color: isActive
                                  ? const Color(0xFFADF4A5)
                                  : Colors.white54,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              item.label,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight:
                                    isActive ? FontWeight.w600 : FontWeight.w400,
                                color: isActive
                                    ? Colors.white
                                    : Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Logout button ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Divider(
              color: Colors.white.withOpacity(0.08),
              height: 1,
            ),
          ),

          // ── Admin info + logout ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('citoyens')
                  .doc(FirebaseAuth.instance.currentUser?.uid ?? '')
                  .snapshots(),
              builder: (context, snap) {
                final data = snap.data?.data() as Map<String, dynamic>? ?? {};
                final adminName = data['pseudo'] ?? data['nom'] ?? 'Admin';

                return Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: onLogout,
                    borderRadius: BorderRadius.circular(12),
                    splashColor: Colors.red.withOpacity(0.1),
                    hoverColor: Colors.red.withOpacity(0.06),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.06),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                adminName.isNotEmpty
                                    ? adminName[0].toUpperCase()
                                    : 'A',
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFADF4A5),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  adminName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  isArabic ? 'مسؤول' : 'Administrateur',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    color: Colors.white38,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.logout_rounded,
                            size: 18,
                            color: Colors.white38,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top Bar
// ─────────────────────────────────────────────────────────────────────────────

class _AdminTopBar extends StatelessWidget {
  const _AdminTopBar({
    required this.title,
    required this.isArabic,
    required this.onToggleLanguage,
    required this.searchCtrl,
    required this.searchQuery,
  });
  final String title;
  final bool isArabic;
  final VoidCallback onToggleLanguage;
  final TextEditingController searchCtrl;
  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(
          bottom: BorderSide(
            color: AppColors.outlineVariant.withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),

          // ── Search bar ──────────────────────────────────────────────────
          Container(
            width: 280,
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.outlineVariant.withOpacity(0.4),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: AppColors.onSurfaceVariant.withOpacity(0.5),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: searchCtrl,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppColors.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: isArabic ? 'بحث…' : 'Rechercher…',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant.withOpacity(0.5),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      searchCtrl.clear();
                    },
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: AppColors.onSurfaceVariant.withOpacity(0.5),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // ── Language Toggle ─────────────────────────────────────────────
          InkWell(
            onTap: onToggleLanguage,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.outlineVariant.withOpacity(0.4),
                ),
              ),
              child: Center(
                child: Text(
                  isArabic ? 'FR' : 'AR',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // ── Notification bell ───────────────────────────────────────────
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.outlineVariant.withOpacity(0.4),
              ),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              size: 20,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data model for sidebar items
// ─────────────────────────────────────────────────────────────────────────────

class _SidebarItem {
  const _SidebarItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

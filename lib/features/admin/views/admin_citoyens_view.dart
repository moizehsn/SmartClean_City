import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../core/constants/app_colors.dart';

/// Admin — User management hub: role-based tabs, universal search, Promote/Delete.
class AdminCitoyensView extends StatefulWidget {
  final String searchQuery;
  const AdminCitoyensView({super.key, this.searchQuery = ''});

  @override
  State<AdminCitoyensView> createState() => _AdminCitoyensViewState();
}

class _AdminCitoyensViewState extends State<AdminCitoyensView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  static const _roleFilters = ['all', 'citoyen', 'chauffeur', 'admin'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    final tabLabels = [
      isAr ? 'الكل' : 'Tous',
      isAr ? 'المواطنون' : 'Citoyens',
      isAr ? 'السائقون' : 'Chauffeurs',
      isAr ? 'المديرون' : 'Administrateurs',
    ];

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance.collection('citoyens').snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child:
                  CircularProgressIndicator(color: AppColors.primary));
        }
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(
                    isAr ? 'خطأ في تحميل المستخدمين' : 'Erreur de chargement',
                    style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    '${snap.error}',
                    style: GoogleFonts.robotoMono(
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          );
        }

        final docs = snap.data?.docs ?? [];
        final allData =
            docs.map((d) => (id: d.id, data: d.data() as Map<String, dynamic>)).toList();

        // tab filter
        final roleFilter = _roleFilters[_tabCtrl.index];
        final tabData = roleFilter == 'all'
            ? allData
            : allData.where((e) => e.data['role'] == roleFilter).toList();

        // search filter (client-side)
        final query = widget.searchQuery.toLowerCase().trim();
        final filtered = query.isEmpty
            ? tabData
            : tabData.where((e) {
                final nom =
                    (e.data['nom'] as String? ?? '').toLowerCase();
                final email =
                    (e.data['email'] as String? ?? '').toLowerCase();
                final pseudo =
                    (e.data['pseudo'] as String? ?? '').toLowerCase();
                return nom.contains(query) ||
                    email.contains(query) ||
                    pseudo.contains(query);
              }).toList();

        // summary counts (unfiltered)
        final cCitoyens =
            allData.where((e) => e.data['role'] == 'citoyen').length;
        final cChauffeurs =
            allData.where((e) => e.data['role'] == 'chauffeur').length;
        final cAdmins =
            allData.where((e) => e.data['role'] == 'admin').length;
        int totalPts = 0;
        for (final e in docs) {
          totalPts +=
              ((e.data() as Map)['points'] as num?)?.toInt() ?? 0;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title row ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAr ? 'إدارة المستخدمين' : 'Gestion des Utilisateurs',
                    style: GoogleFonts.manrope(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                        letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isAr
                        ? '$cCitoyens مواطن • $cChauffeurs سائق • $cAdmins مسؤول • $totalPts نقطة موزعة'
                        : '$cCitoyens citoyens • $cChauffeurs chauffeurs • $cAdmins admins • $totalPts pts distribués',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),

            // ── Tab bar ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabCtrl,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.onSurfaceVariant,
                  labelStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 13, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 13, fontWeight: FontWeight.w500),
                  tabs: tabLabels
                      .map((l) => Tab(
                          height: 38,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(l),
                          )))
                      .toList(),
                ),
              ),
            ),

            // ── Data table ───────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 16, 28, 40),
                child: filtered.isEmpty
                    ? Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: AppColors.botanicalShadow,
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Text(
                              query.isNotEmpty
                                  ? (isAr
                                      ? 'لا توجد نتائج لـ "$query"'
                                      : 'Aucun résultat pour "$query"')
                                  : (isAr
                                      ? 'لا يوجد مستخدمون في هذه الفئة'
                                      : 'Aucun utilisateur dans cette catégorie'),
                              style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.onSurfaceVariant),
                            ),
                          ),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: AppColors.botanicalShadow,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(
                                  AppColors.surfaceContainerLow),
                              columnSpacing: 24,
                              columns: [
                                DataColumn(
                                    label: Text('#',
                                        style: _h(isAr))),
                                DataColumn(
                                    label: Text(isAr ? 'الاسم' : 'Nom',
                                        style: _h(isAr))),
                                DataColumn(
                                    label: Text(isAr ? 'البريد' : 'Email',
                                        style: _h(isAr))),
                                DataColumn(
                                    label: Text(isAr ? 'الدور' : 'Rôle',
                                        style: _h(isAr))),
                                DataColumn(
                                    label: Text(isAr ? 'النقاط' : 'Points',
                                        style: _h(isAr))),
                                DataColumn(
                                    label: Text(isAr ? 'التسجيل' : 'Inscrit le',
                                        style: _h(isAr))),
                                DataColumn(
                                    label: Text(isAr ? 'إجراءات' : 'Actions',
                                        style: _h(isAr))),
                              ],
                              rows: List.generate(filtered.length, (i) {
                                final e = filtered[i];
                                final d = e.data;
                                final docId = e.id;
                                final nom = d['nom'] ?? '—';
                                final email = d['email'] ?? '—';
                                final role =
                                    d['role'] as String? ?? 'citoyen';
                                final pts = d['points'] ?? 0;
                                final createdAt =
                                    (d['created_at'] as Timestamp?)
                                        ?.toDate();
                                final pseudo = d['pseudo'] as String? ??
                                    nom.toString().split(' ').first;
                                final camionType =
                                    d['camion_type'] as String?;
                                final matricule =
                                    d['matricule'] as String?;
                                final showPoints = role != 'chauffeur' &&
                                    role != 'admin';

                                return DataRow(cells: [
                                  // rank
                                  DataCell(Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: i < 3
                                          ? AppColors.primary
                                              .withOpacity(0.10)
                                          : AppColors
                                              .surfaceContainerLow,
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                        child: Text('${i + 1}',
                                            style: GoogleFonts.manrope(
                                                fontWeight:
                                                    FontWeight.w700,
                                                fontSize: 12,
                                                color: i < 3
                                                    ? AppColors.primary
                                                    : AppColors
                                                        .onSurfaceVariant))),
                                  )),
                                  // nom
                                  DataCell(Text(nom,
                                      style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.onSurface))),
                                  // email
                                  DataCell(Text(email,
                                      style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          color: AppColors
                                              .onSurfaceVariant))),
                                  // role badge
                                  DataCell(_RoleBadge(
                                      role: role, isAr: isAr)),
                                  // points
                                  DataCell(showPoints
                                      ? Row(
                                          mainAxisSize:
                                              MainAxisSize.min,
                                          children: [
                                              const Icon(
                                                  Icons
                                                      .stars_rounded,
                                                  size: 16,
                                                  color: Colors.amber),
                                              const SizedBox(width: 4),
                                              Text('$pts',
                                                  style: GoogleFonts
                                                      .manrope(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight
                                                                  .w700,
                                                          color: AppColors
                                                              .primary)),
                                            ])
                                      : Text('-',
                                          style: GoogleFonts.manrope(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors
                                                  .onSurfaceVariant))),
                                  // date
                                  DataCell(Text(
                                    createdAt != null
                                        ? DateFormat('dd/MM/yyyy')
                                            .format(createdAt)
                                        : '—',
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        color: AppColors
                                            .onSurfaceVariant),
                                  )),
                                  // actions
                                  DataCell(_UserActions(
                                    docId: docId,
                                    currentRole: role,
                                    nom: nom.toString(),
                                    pseudo: pseudo,
                                    email: email.toString(),
                                    camionType:
                                        camionType ?? '',
                                    matricule: matricule ?? '',
                                    isAr: isAr,
                                  )),
                                ]);
                              }),
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  static TextStyle _h(bool isAr) => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.onSurfaceVariant,
      );
}

// ── Role Badge ─────────────────────────────────────────────────────────────────

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role, required this.isAr});
  final String role;
  final bool isAr;

  Color get _color {
    switch (role) {
      case 'admin':
        return const Color(0xFF6C63FF);
      case 'chauffeur':
        return AppColors.primary;
      default:
        return AppColors.onSurfaceVariant;
    }
  }

  String get _label {
    switch (role) {
      case 'admin':
        return isAr ? 'مسؤول' : 'Admin';
      case 'chauffeur':
        return isAr ? 'سائق' : 'Chauffeur';
      default:
        return isAr ? 'مواطن' : 'Citoyen';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        _label,
        style: GoogleFonts.plusJakartaSans(
            fontSize: 11, fontWeight: FontWeight.w700, color: _color),
      ),
    );
  }
}

// ── User Actions (Promote / Delete) ────────────────────────────────────────────

class _UserActions extends StatelessWidget {
  const _UserActions({
    required this.docId,
    required this.currentRole,
    required this.nom,
    required this.pseudo,
    required this.email,
    required this.camionType,
    required this.matricule,
    required this.isAr,
  });

  final String docId;
  final String currentRole;
  final String nom;
  final String pseudo;
  final String email;
  final String camionType;
  final String matricule;
  final bool isAr;

  Future<void> _promote(BuildContext context) async {
    String selectedRole =
        currentRole == 'chauffeur' ? 'admin' : 'chauffeur';
    final camionCtrl = TextEditingController(text: camionType);
    final matriculeCtrl = TextEditingController(text: matricule);
    bool saving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24)),
          backgroundColor: AppColors.surfaceContainerLowest,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.swap_horiz_rounded,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          isAr
                              ? 'ترقية المستخدم'
                              : 'Promouvoir l\'utilisateur',
                          style: GoogleFonts.manrope(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.onSurface,
                              letterSpacing: -0.3),
                        ),
                      ),
                      IconButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: const Icon(Icons.close_rounded),
                          color: AppColors.onSurfaceVariant),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isAr ? 'المستخدم: $nom' : 'Utilisateur: $nom',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 20),

                  // Role dropdown
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? 'الدور الجديد' : 'Nouveau rôle',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        items: [
                          DropdownMenuItem(
                              value: 'chauffeur',
                              child: Text(
                                  isAr ? 'سائق' : 'Chauffeur')),
                          DropdownMenuItem(
                              value: 'admin',
                              child: Text(
                                  isAr ? 'مسؤول' : 'Administrateur')),
                        ],
                        onChanged: (v) {
                          if (v != null) setD(() => selectedRole = v);
                        },
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: AppColors.onSurface),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.badge_rounded,
                              size: 18,
                              color: AppColors.onSurfaceVariant),
                          filled: true,
                          fillColor: AppColors.surfaceContainerLow,
                          border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: AppColors.outlineVariant
                                      .withOpacity(0.4))),
                          enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: AppColors.outlineVariant
                                      .withOpacity(0.4))),
                          focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 1.5)),
                          contentPadding:
                              const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 14),
                        ),
                      ),
                    ],
                  ),

                  // Conditional truck fields
                  if (selectedRole == 'chauffeur') ...[
                    const SizedBox(height: 14),
                    _PromoteField(
                      label: isAr ? 'نوع الشاحنة' : 'Type de Camion',
                      hint: 'ex: Sonacom K120',
                      controller: camionCtrl,
                      icon: Icons.local_shipping_outlined,
                    ),
                    const SizedBox(height: 14),
                    _PromoteField(
                      label: isAr ? 'رقم التسجيل' : 'Matricule',
                      hint: 'ex: 03 525 75290',
                      controller: matriculeCtrl,
                      icon: Icons.confirmation_number_outlined,
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: saving
                          ? null
                          : () async {
                              setD(() => saving = true);
                              try {
                                final Map<String, dynamic> update = {
                                  'role': selectedRole
                                };
                                if (selectedRole == 'chauffeur') {
                                  update['camion_type'] =
                                      camionCtrl.text.trim();
                                  update['matricule'] =
                                      matriculeCtrl.text.trim();
                                } else {
                                  update['camion_type'] =
                                      FieldValue.delete();
                                  update['matricule'] =
                                      FieldValue.delete();
                                }
                                await FirebaseFirestore.instance
                                    .collection('citoyens')
                                    .doc(docId)
                                    .update(update);
                                if (ctx.mounted) Navigator.of(ctx).pop();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isAr
                                            ? '✓ تمت الترقية بنجاح'
                                            : '✓ Promotion réussie',
                                        style: GoogleFonts
                                            .plusJakartaSans(
                                                color: Colors.white),
                                      ),
                                      backgroundColor:
                                          AppColors.primary,
                                      behavior:
                                          SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(
                                                  12)),
                                    ),
                                  );
                                }
                              } catch (e) {
                                setD(() => saving = false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${isAr ? 'خطأ' : 'Erreur'}: $e',
                                        style: GoogleFonts
                                            .plusJakartaSans(
                                                color: Colors.white),
                                      ),
                                      backgroundColor:
                                          AppColors.error,
                                      behavior:
                                          SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(
                                                  12)),
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14)),
                      ),
                      child: saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5))
                          : Text(
                              isAr
                                  ? 'حفظ الترقية'
                                  : 'Enregistrer la promotion',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.surfaceContainerLowest,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Icons.delete_forever_rounded,
                      size: 32, color: AppColors.error),
                ),
                const SizedBox(height: 18),
                Text(
                  isAr ? 'تأكيد الحذف' : 'Confirmer la suppression',
                  style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                      letterSpacing: -0.3),
                ),
                const SizedBox(height: 12),
                Text(
                  isAr
                      ? 'هل أنت متأكد من حذف هذا المستخدم نهائياً؟\nلن يتمكن من الوصول إلى التطبيق بعد الآن.'
                      : 'Êtes-vous sûr de vouloir supprimer\ncet utilisateur définitivement ?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: AppColors.onSurfaceVariant,
                      height: 1.5),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            Navigator.of(ctx).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              AppColors.onSurfaceVariant,
                          side: BorderSide(
                              color: AppColors.outlineVariant
                                  .withOpacity(0.5)),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(14)),
                        ),
                        child: Text(
                          isAr ? 'إلغاء' : 'Annuler',
                          style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            Navigator.of(ctx).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(14)),
                        ),
                        child: Text(
                          isAr ? 'حذف' : 'Supprimer',
                          style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('citoyens')
            .doc(docId)
            .delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isAr ? '✓ تم حذف المستخدم' : '✓ Utilisateur supprimé',
                style: GoogleFonts.plusJakartaSans(
                    color: Colors.white),
              ),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${isAr ? 'خطأ' : 'Erreur'}: $e',
                style:
                    GoogleFonts.plusJakartaSans(color: Colors.white),
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionBtn(
          icon: Icons.swap_horiz_rounded,
          color: AppColors.primary,
          tooltip: isAr ? 'ترقية' : 'Promouvoir',
          onTap: () => _promote(context),
        ),
        const SizedBox(width: 4),
        _ActionBtn(
          icon: Icons.delete_outline_rounded,
          color: AppColors.error,
          tooltip: isAr ? 'حذف' : 'Supprimer',
          onTap: () => _delete(context),
        ),
      ],
    );
  }
}

// ── Action Button ─────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  const _ActionBtn(
      {required this.icon,
      required this.color,
      required this.tooltip,
      required this.onTap});
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

// ── Promote Dialog Field ──────────────────────────────────────────────────────

class _PromoteField extends StatelessWidget {
  const _PromoteField(
      {required this.label,
      required this.hint,
      required this.controller,
      required this.icon});
  final String label, hint;
  final TextEditingController controller;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 14, color: AppColors.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color:
                    AppColors.onSurfaceVariant.withOpacity(0.5)),
            prefixIcon:
                Icon(icon, size: 18, color: AppColors.onSurfaceVariant),
            filled: true,
            fillColor: AppColors.surfaceContainerLow,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color:
                        AppColors.outlineVariant.withOpacity(0.4))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color:
                        AppColors.outlineVariant.withOpacity(0.4))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: AppColors.primary, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }
}

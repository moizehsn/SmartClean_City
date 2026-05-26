import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../core/constants/app_colors.dart';

/// Admin — Gestion des Signalements with filter pills + data table + QA actions
class AdminSignalementsView extends StatefulWidget {
  final String searchQuery;
  const AdminSignalementsView({super.key, this.searchQuery = ''});

  @override
  State<AdminSignalementsView> createState() => _AdminSignalementsViewState();
}

class _AdminSignalementsViewState extends State<AdminSignalementsView> {
  int _filterIndex = 0;

  static const _filters = <String?>[
    null,
    'en attente',
    'en cours',
    'en vérification',
    'terminé',
    'rejeté',
  ];

  List<String> _filterLabels(bool isAr) => [
    isAr ? 'الكل' : 'Tous',
    isAr ? 'انتظار' : 'En attente',
    isAr ? 'جاري' : 'En cours',
    isAr ? 'مراجعة' : 'Vérification',
    isAr ? 'منتهي' : 'Terminé',
    isAr ? 'مرفوض' : 'Rejeté',
  ];

  Stream<QuerySnapshot> get _stream {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('signalements')
        .orderBy('timestamp', descending: true);

    final statut = _filters[_filterIndex];
    if (statut != null) {
      query = query.where('statut', isEqualTo: statut);
    }
    return query.snapshots();
  }

  Future<void> _updateStatut(String docId, String newStatut) async {
    await FirebaseFirestore.instance
        .collection('signalements')
        .doc(docId)
        .update({'statut': newStatut});
  }

  // ── Admin QA: Approve after photo ─────────────────────────────────────────
  Future<void> _approveReport(String docId, String? citoyenId) async {
    final batch = FirebaseFirestore.instance.batch();
    final ref = FirebaseFirestore.instance.collection('signalements').doc(docId);

    batch.update(ref, {
      'statut': 'terminé',
      'timestamp_qa': FieldValue.serverTimestamp(),
    });

    // Gamification: award citizen 10 points on Admin approval
    if (citoyenId != null && citoyenId != 'user_mock' && citoyenId != 'unknown') {
      final citoyenRef = FirebaseFirestore.instance.collection('citoyens').doc(citoyenId);
      batch.update(citoyenRef, {'points': FieldValue.increment(10)});
    }

    await batch.commit();
  }

  // ── Admin QA: Reject after photo — revert to en cours ──────────────────────
  Future<void> _rejectReport(String docId) async {
    await FirebaseFirestore.instance
        .collection('signalements')
        .doc(docId)
        .update({
          'statut': 'en cours',
          'photo_apres_base64': FieldValue.delete(),
          'timestamp_fin': FieldValue.delete(),
        });
  }

  // ── QA Review bottom sheet ─────────────────────────────────────────────────
  void _showQAReview(String docId, Map<String, dynamic> data, bool isAr) {
    final photoAvant = data['photo_base64'] as String?;
    final photoApres = data['photo_apres_base64'] as String?;
    final idCourt = data['id_court'] as String? ?? '#????';
    final addr = data['adresse_lisible'] as String? ?? 'Adresse inconnue';
    final citoyenId = data['citoyen_id'] as String?;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: AppColors.surfaceContainerLowest,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.statusVerification.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.pending_outlined,
                                  size: 13,
                                  color: AppColors.statusVerification,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  isAr ? 'قيد المراجعة' : 'En vérification',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.statusVerification,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isAr ? 'مراجعة الجودة — $idCourt' : 'Contrôle Qualité — $idCourt',
                            style: GoogleFonts.manrope(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.onSurface,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            addr,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: AppColors.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Before / After photo comparison ────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Before
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr ? 'قبل التنظيف' : 'Avant nettoyage',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.statusPendingAdmin,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: photoAvant != null && photoAvant.isNotEmpty
                                ? Image.memory(
                                    base64Decode(photoAvant),
                                    height: 180,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _photoError(),
                                  )
                                : _photoError(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // After
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr ? 'بعد التنظيف' : 'Après nettoyage',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.statusCompleted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: photoApres != null && photoApres.isNotEmpty
                                ? Image.memory(
                                    base64Decode(photoApres),
                                    height: 180,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _photoError(),
                                  )
                                : _photoError(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Info note ────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.statusVerification.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.statusVerification,
                        size: 16,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isAr
                              ? 'الموافقة ستمنح المواطن 10 نقاط. الرفض سيعيد المهمة للسائق.'
                              : 'Approuver accordera 10 points au citoyen. Rejeter renverra la mission au chauffeur.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Action buttons ──────────────────────────────────
                Row(
                  children: [
                    // Reject button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          Navigator.of(ctx).pop();
                          await _rejectReport(docId);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isAr ? 'تم رفض الصورة — المهمة عادت للسائق' : 'Photo rejetée — mission renvoyée au chauffeur',
                                  style: GoogleFonts.plusJakartaSans(color: Colors.white),
                                ),
                                backgroundColor: AppColors.error,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                margin: const EdgeInsets.all(16),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: Text(isAr ? 'رفض' : 'Rejeter'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Approve button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.of(ctx).pop();
                          await _approveReport(docId, citoyenId);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isAr ? 'تمت الموافقة — المهمة مكتملة ✓' : 'Approuvé — Mission terminée ✓',
                                  style: GoogleFonts.plusJakartaSans(color: Colors.white),
                                ),
                                backgroundColor: AppColors.statusCompleted,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                margin: const EdgeInsets.all(16),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.check_circle_rounded, size: 18),
                        label: Text(isAr ? 'موافقة' : 'Approuver'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.statusCompleted,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
                          elevation: 0,
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
  }

  Widget _photoError() => Container(
    height: 180,
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Center(
      child: Icon(Icons.broken_image_outlined, color: AppColors.onSurfaceVariant, size: 36),
    ),
  );

  void _showReportDetails(Map<String, dynamic> data, String docId, bool isAr) {
    final addr = data['adresse_lisible'] as String? ?? 'Adresse inconnue';
    final statut = data['statut'] as String? ?? 'en attente';
    final idCourt = data['id_court'] as String? ?? '#????';
    final photoBase64 = data['photo_base64'] as String?;
    final citoyenId = data['citoyen_id'] as String?;
    final lat = (data['latitude'] as num?)?.toDouble();
    final lng = (data['longitude'] as num?)?.toDouble();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.surfaceContainerLowest,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isAr ? 'تفاصيل البلاغ' : 'Détails du Signalement',
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Photo thumbnail ─────────────────────────────────────
                if (photoBase64 != null && photoBase64.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(
                      base64Decode(photoBase64),
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 220,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 40,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.photo_camera_outlined,
                        size: 40,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),

                // ── Details ─────────────────────────────────────────────
                _DetailRow(icon: Icons.tag_rounded, label: 'ID', value: idCourt),
                const SizedBox(height: 12),
                _DetailRow(icon: Icons.location_on_rounded, label: isAr ? 'العنوان' : 'Adresse', value: addr),
                if (lat != null && lng != null) ...[
                  const SizedBox(height: 12),
                  _DetailRow(icon: Icons.map_rounded, label: isAr ? 'الإحداثيات' : 'Coordonnées', value: '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}'),
                ],
                if (citoyenId != null) ...[
                  const SizedBox(height: 12),
                  _DetailRow(icon: Icons.person_rounded, label: isAr ? 'معرف المواطن' : 'Citoyen ID', value: citoyenId),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Text(
                      isAr ? 'الحالة' : 'Statut',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 14),
                    _StatusBadge(statut: statut, isAr: isAr),
                  ],
                ),
                const SizedBox(height: 32),

                // ── Close button ──────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.onSurfaceVariant,
                      side: BorderSide(
                        color: AppColors.outlineVariant.withOpacity(0.5),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      isAr ? 'إغلاق' : 'Fermer',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    final labels = _filterLabels(isAr);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title ────────────────────────────────────────────
          Text(
            isAr ? 'إدارة البلاغات' : 'Gestion des Signalements',
            style: GoogleFonts.manrope(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isAr ? 'عرض وتصفية وإدارة جميع بلاغات المواطنين' : 'Visualiser, filtrer et gérer tous les rapports citoyens',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),

          // ── Filter pills ─────────────────────────────────────
          SizedBox(
            height: 42,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: labels.length,
              itemBuilder: (_, i) {
                final active = i == _filterIndex;
                // 'En vérification' pill gets the teal QA color
                final pillColor = _filters[i] == 'en vérification'
                    ? AppColors.statusVerification
                    : AppColors.primary;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _filterIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? pillColor
                            : AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(100),
                        border: active
                            ? null
                            : Border.all(
                                color: AppColors.outlineVariant.withOpacity(0.4),
                              ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_filters[i] == 'en vérification' && active)
                            Padding(
                              padding: const EdgeInsets.only(right: 5),
                              child: Icon(
                                Icons.pending_outlined,
                                size: 13,
                                color: active ? Colors.white : AppColors.statusVerification,
                              ),
                            ),
                          Text(
                            labels[i],
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: active ? Colors.white : AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // ── Data Table ───────────────────────────────────────
          StreamBuilder<QuerySnapshot>(
            stream: _stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
              }

              if (snapshot.hasError) {
                return _buildError(snapshot.error);
              }

              final docs = snapshot.data?.docs ?? [];

              // client-side search filter
              final query = widget.searchQuery.toLowerCase().trim();
              final filtered = query.isEmpty
                  ? docs
                  : docs.where((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      final addr =
                          (d['adresse_lisible'] as String? ?? '').toLowerCase();
                      final id = (d['id_court'] as String? ?? '').toLowerCase();
                      return addr.contains(query) || id.contains(query);
                    }).toList();

              if (filtered.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppColors.botanicalShadow,
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.inbox_rounded,
                          size: 48,
                          color: AppColors.onSurfaceVariant.withOpacity(0.4)),
                      const SizedBox(height: 12),
                      Text(
                        widget.searchQuery.isNotEmpty
                            ? (isAr
                                ? 'لا توجد نتائج لـ "${widget.searchQuery}"'
                                : 'Aucun résultat pour "${widget.searchQuery}"')
                            : (isAr
                                ? 'لا توجد بلاغات في هذه الفئة'
                                : 'Aucun signalement dans cette catégorie'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Container(
                width: double.infinity,
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
                        AppColors.surfaceContainerLow,
                      ),
                      columnSpacing: 24,
                      columns: [
                        DataColumn(label: Text('ID', style: _hStyle())),
                        DataColumn(label: Text(isAr ? 'العنوان' : 'Adresse', style: _hStyle())),
                        DataColumn(label: Text(isAr ? 'الحالة' : 'Statut', style: _hStyle())),
                        DataColumn(label: Text(isAr ? 'التاريخ' : 'Date', style: _hStyle())),
                        DataColumn(label: Text(isAr ? 'إجراءات' : 'Actions', style: _hStyle())),
                      ],
                      rows: filtered.map((doc) {
                        final d = doc.data() as Map<String, dynamic>;
                        final statut = d['statut'] as String? ?? 'en attente';
                        final addr = d['adresse_lisible'] as String? ?? '';
                        final ts = (d['timestamp'] as Timestamp?)?.toDate();
                        final citoyenId = d['citoyen_id'] as String?;
                        final isQA = statut == 'en vérification';

                        return DataRow(
                          color: isQA
                              ? WidgetStateProperty.all(
                                  AppColors.statusVerification.withOpacity(0.05))
                              : null,
                          cells: [
                            DataCell(Text(
                              d['id_court'] ?? '#????',
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppColors.primary,
                              ),
                            )),
                            DataCell(
                              SizedBox(
                                width: 260,
                                child: Text(
                                  addr,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(_StatusBadge(statut: statut, isAr: isAr)),
                            DataCell(Text(
                              ts != null
                                  ? DateFormat('dd/MM/yyyy – HH:mm').format(ts)
                                  : '—',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: AppColors.onSurfaceVariant,
                              ),
                            )),
                            DataCell(Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _ActionBtn(
                                  icon: Icons.visibility_rounded,
                                  color: AppColors.onSurfaceVariant,
                                  tooltip: isAr ? 'عرض التفاصيل' : 'Voir les détails',
                                  onTap: () => _showReportDetails(d, doc.id, isAr),
                                ),
                                const SizedBox(width: 4),
                                // QA actions for 'en vérification' reports
                                if (isQA) ...[
                                  _ActionBtn(
                                    icon: Icons.rate_review_rounded,
                                    color: AppColors.statusVerification,
                                    tooltip: isAr ? 'مراجعة الصور' : 'Réviser les photos',
                                    onTap: () => _showQAReview(doc.id, d, isAr),
                                  ),
                                  const SizedBox(width: 4),
                                  _ActionBtn(
                                    icon: Icons.check_circle_rounded,
                                    color: AppColors.statusCompleted,
                                    tooltip: isAr ? 'موافقة → منتهي' : 'Approuver → Terminé',
                                    onTap: () => _approveReport(doc.id, citoyenId),
                                  ),
                                  const SizedBox(width: 4),
                                  _ActionBtn(
                                    icon: Icons.replay_rounded,
                                    color: AppColors.error,
                                    tooltip: isAr ? 'رفض → إعادة للسائق' : 'Rejeter → Renvoyer au chauffeur',
                                    onTap: () => _rejectReport(doc.id),
                                  ),
                                ] else ...[
                                  if (statut == 'en attente') ...[
                                    _ActionBtn(
                                      icon: Icons.check_rounded,
                                      color: AppColors.primary,
                                      tooltip: isAr ? 'قبول ← قيد المعالجة' : 'Accepter → En cours',
                                      onTap: () =>
                                          _updateStatut(doc.id, 'en cours'),
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  if (statut != 'rejeté' && statut != 'terminé')
                                    _ActionBtn(
                                      icon: Icons.close_rounded,
                                      color: AppColors.error,
                                      tooltip: isAr ? 'رفض' : 'Rejeter',
                                      onTap: () =>
                                          _updateStatut(doc.id, 'rejeté'),
                                    ),
                                ],
                              ],
                            )),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildError(Object? error) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFB300), width: 1.5),
        ),
        child: SelectableText(
          error?.toString() ?? (Directionality.of(context) == TextDirection.rtl ? 'خطأ غير معروف' : 'Erreur inconnue'),
          style: GoogleFonts.robotoMono(
            fontSize: 12,
            color: const Color(0xFF3E2723),
          ),
        ),
      );

  static TextStyle _hStyle() => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.onSurfaceVariant,
      );
}

// ── Action Button ─────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });
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
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

// ── Status Badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.statut, this.isAr = false});
  final String statut;
  final bool isAr;

  Color get _color {
    switch (statut) {
      case 'en attente':
        return AppColors.statusPendingAdmin;
      case 'en cours':
        return AppColors.statusInProgress;
      case 'en vérification':
        return AppColors.statusVerification;
      case 'terminé':
        return AppColors.statusCompleted;
      case 'rejeté':
        return AppColors.statusRejected;
      default:
        return AppColors.onSurfaceVariant;
    }
  }

  String get _label {
    switch (statut) {
      case 'en attente':
        return isAr ? 'انتظار' : 'En attente';
      case 'en cours':
        return isAr ? 'جاري' : 'En cours';
      case 'en vérification':
        return isAr ? 'مراجعة' : 'Vérification';
      case 'terminé':
        return isAr ? 'منتهي' : 'Terminé';
      case 'rejeté':
        return isAr ? 'مرفوض' : 'Rejeté';
      default:
        return statut;
    }
  }

  IconData get _icon {
    switch (statut) {
      case 'en vérification':
        return Icons.pending_outlined;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final showIcon = statut == 'en vérification';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(_icon, size: 11, color: _color),
            const SizedBox(width: 4),
          ],
          Text(
            _label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 8),
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

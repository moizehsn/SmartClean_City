import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../core/constants/app_colors.dart';

/// Admin — Gestion des Signalements with filter pills + data table + actions
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
    'terminé',
    'rejeté',
  ];

  List<String> _filterLabels(bool isAr) => [
    isAr ? 'الكل' : 'Tous',
    isAr ? 'انتظار' : 'En attente',
    isAr ? 'جاري' : 'En cours',
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
                            ? AppColors.primary
                            : AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(100),
                        border: active
                            ? null
                            : Border.all(
                                color: AppColors.outlineVariant.withOpacity(0.4),
                              ),
                      ),
                      child: Text(
                        labels[i],
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: active ? Colors.white : AppColors.onSurfaceVariant,
                        ),
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

                        return DataRow(cells: [
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
                          )),
                        ]);
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
      case 'terminé':
        return isAr ? 'منتهي' : 'Terminé';
      case 'rejeté':
        return isAr ? 'مرفوض' : 'Rejeté';
      default:
        return statut;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        _label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _color,
        ),
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

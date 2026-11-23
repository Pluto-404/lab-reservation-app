import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../models/laboratory_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/info_state.dart';
import '../../widgets/summary_stat_card.dart';
import 'laboratory_form_page.dart';

class LaboratoryManagementPage extends StatefulWidget {
  const LaboratoryManagementPage({
    super.key,
    this.showAppBar = true,
  });

  final bool showAppBar;

  @override
  State<LaboratoryManagementPage> createState() =>
      _LaboratoryManagementPageState();
}

class _LaboratoryManagementPageState
    extends State<LaboratoryManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  String _selectedFilter = 'Semua';

  List<LaboratoryModel> _filterLaboratories(
    List<LaboratoryModel> laboratories,
  ) {
    final keyword = _searchController.text.toLowerCase().trim();

    return laboratories.where((lab) {
      final matchesSearch =
          lab.name.toLowerCase().contains(keyword) ||
          lab.building.toLowerCase().contains(keyword) ||
          lab.facilities.any((f) => f.toLowerCase().contains(keyword));

      final matchesFilter = switch (_selectedFilter) {
        'Aktif' => lab.isActive,
        'Nonaktif' => !lab.isActive,
        _ => true,
      };

      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openForm({LaboratoryModel? laboratory}) async {
    final result = await Navigator.push<LaboratoryModel>(
      context,
      MaterialPageRoute(
        builder: (_) => LaboratoryFormPage(
          laboratory: laboratory,
        ),
      ),
    );

    if (result == null || !mounted) return;

    try {
      if (laboratory == null) {
        await _firestoreService.addLaboratory(result);
      } else {
        await _firestoreService.updateLaboratory(result);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            laboratory == null
                ? 'Laboratorium berhasil ditambahkan.'
                : 'Laboratorium berhasil diperbarui.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan laboratorium: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  Future<void> _deleteLaboratory(
    LaboratoryModel laboratory,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Laboratorium'),
        content: Text(
          'Apakah kamu yakin ingin menghapus ${laboratory.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.danger,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _firestoreService.deleteLaboratory(laboratory.labId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Laboratorium berhasil dihapus.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus laboratorium: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bodyContent = StreamBuilder<List<LaboratoryModel>>(
      stream: _firestoreService.getAllLaboratories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(48),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return InfoState(
            icon: Icons.error_outline,
            text: 'Gagal mengambil data laboratorium.',
            subtext: '${snapshot.error}',
          );
        }

        final allLaboratories = snapshot.data ?? <LaboratoryModel>[];
        final laboratories = _filterLaboratories(allLaboratories);

        final activeCount =
            allLaboratories.where((lab) => lab.isActive).length;

        final inactiveCount =
            allLaboratories.where((lab) => !lab.isActive).length;

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Manajemen Laboratorium',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.ink,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Kelola ketersediaan data dan fasilitas laboratorium.',
                        style: TextStyle(color: AppTheme.muted),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _openForm(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Tambah Lab'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Statistik dari Firestore
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 600 ? 3 : 1;

                return GridView.count(
                  crossAxisCount: columns,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: columns == 3 ? 2.5 : 4.0,
                  children: [
                    SummaryStatCard(
                      title: 'Total Laboratorium',
                      value: '${allLaboratories.length}',
                      icon: Icons.science_outlined,
                      iconColor: AppTheme.primary,
                      backgroundColor: AppTheme.soft,
                    ),
                    SummaryStatCard(
                      title: 'Laboratorium Aktif',
                      value: '$activeCount',
                      icon: Icons.check_circle_outline,
                      iconColor: AppTheme.success,
                      backgroundColor: AppTheme.successSoft,
                    ),
                    SummaryStatCard(
                      title: 'Lab Nonaktif',
                      value: '$inactiveCount',
                      icon: Icons.pause_circle_outline,
                      iconColor: AppTheme.warning,
                      backgroundColor: AppTheme.warningSoft,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Pencarian
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Cari nama, gedung, atau fasilitas...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
            ),

            const SizedBox(height: 16),

            // Filter status
            Wrap(
              spacing: 8,
              children: ['Semua', 'Aktif', 'Nonaktif'].map((filter) {
                return ChoiceChip(
                  label: Text(filter),
                  selected: _selectedFilter == filter,
                  onSelected: (_) {
                    setState(() {
                      _selectedFilter = filter;
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Daftar Laboratorium',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
                Text(
                  '${laboratories.length} lab ditemukan',
                  style: const TextStyle(
                    color: AppTheme.muted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            if (laboratories.isEmpty)
              const InfoState(
                icon: Icons.search_off,
                text: 'Laboratorium tidak ditemukan.',
                subtext: 'Coba ubah kata kunci pencarian atau ganti filter status.',
              )
            else
              ...laboratories.map(
                (laboratory) => _LaboratoryCard(
                  laboratory: laboratory,
                  onEdit: () => _openForm(laboratory: laboratory),
                  onDelete: () => _deleteLaboratory(laboratory),
                ),
              ),
          ],
        );
      },
    );

    if (!widget.showAppBar) {
      return PageWidth(maxWidth: 800, child: bodyContent);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Laboratorium'),
      ),
      body: PageWidth(maxWidth: 800, child: bodyContent),
    );
  }
}

class _LaboratoryCard extends StatelessWidget {
  final LaboratoryModel laboratory;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _LaboratoryCard({
    required this.laboratory,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final active = laboratory.isActive;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppTheme.soft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.science_outlined,
                      color: AppTheme.deep,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          laboratory.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 15,
                              color: AppTheme.muted,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                laboratory.building,
                                style: const TextStyle(
                                  color: AppTheme.muted,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? AppTheme.successSoft
                          : AppTheme.dangerSoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      active ? 'Aktif' : 'Nonaktif',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: active
                            ? AppTheme.success
                            : AppTheme.danger,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  const Icon(
                    Icons.people_outline,
                    size: 15,
                    color: AppTheme.muted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Kapasitas: ${laboratory.capacity} orang',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.muted,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.access_time,
                    size: 15,
                    color: AppTheme.muted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    laboratory.operationalHours.isEmpty
                        ? '08.00 - 16.00'
                        : laboratory.operationalHours,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.muted,
                    ),
                  ),
                ],
              ),

              if (laboratory.facilities.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: laboratory.facilities.map((facility) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        facility,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.ink,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: AppTheme.outline),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: onDelete,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.danger,
                      side: const BorderSide(color: AppTheme.danger),
                      minimumSize: const Size(0, 38),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Hapus', style: TextStyle(fontSize: 13)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: onEdit,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 38),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit', style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../models/laboratory_model.dart';
import '../../services/firestore_service.dart';
import 'laboratory_form_page.dart';

class LaboratoryManagementPage extends StatefulWidget {
  const LaboratoryManagementPage({super.key});

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
    final keyword = _searchController.text.toLowerCase();

    return laboratories.where((lab) {
      final matchesSearch =
          lab.name.toLowerCase().contains(keyword) ||
          lab.building.toLowerCase().contains(keyword);

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Laboratorium'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<LaboratoryModel>>(
        stream: _firestoreService.getAllLaboratories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Gagal mengambil data laboratorium:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final allLaboratories =
              snapshot.data ?? <LaboratoryModel>[];

          final laboratories =
              _filterLaboratories(allLaboratories);

          final activeCount =
              allLaboratories.where((lab) => lab.isActive).length;

          final inactiveCount =
              allLaboratories.where((lab) => !lab.isActive).length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Manajemen Laboratorium',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Kelola informasi dan data laboratorium kampus.',
                      style: TextStyle(color: AppTheme.muted),
                    ),

                    const SizedBox(height: 24),

                    // Statistik dari Firestore
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns =
                            constraints.maxWidth >= 600 ? 3 : 1;

                        return GridView.count(
                          crossAxisCount: columns,
                          shrinkWrap: true,
                          physics:
                              const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio:
                              columns == 3 ? 2.8 : 4,
                          children: [
                            _SummaryCard(
                              title: 'Total Laboratorium',
                              value: '${allLaboratories.length}',
                              icon: Icons.science_outlined,
                              color: AppTheme.primary,
                            ),
                            _SummaryCard(
                              title: 'Laboratorium Aktif',
                              value: '$activeCount',
                              icon: Icons.check_circle_outline,
                              color: AppTheme.success,
                            ),
                            _SummaryCard(
                              title: 'Laboratorium Nonaktif',
                              value: '$inactiveCount',
                              icon: Icons.pause_circle_outline,
                              color: AppTheme.warning,
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 28),

                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: () => _openForm(),
                        icon: const Icon(Icons.add),
                        label: const Text('Tambah Laboratorium'),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Pencarian
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText:
                            'Cari nama atau gedung laboratorium...',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Filter status
                    Wrap(
                      spacing: 8,
                      children: ['Semua', 'Aktif', 'Nonaktif']
                          .map((filter) {
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
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Daftar Laboratorium',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.ink,
                          ),
                        ),
                        Text(
                          '${laboratories.length} data',
                          style: const TextStyle(
                            color: AppTheme.muted,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    if (laboratories.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 42,
                                  color: AppTheme.muted,
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'Laboratorium tidak ditemukan.',
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      ...laboratories.map(
                        (laboratory) => _LaboratoryCard(
                          laboratory: laboratory,
                          onEdit: () => _openForm(
                            laboratory: laboratory,
                          ),
                          onDelete: () =>
                              _deleteLaboratory(laboratory),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.ink,
                    ),
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.soft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.science_outlined,
                    color: AppTheme.primary,
                    size: 26,
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
                          fontWeight: FontWeight.bold,
                          color: AppTheme.ink,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        laboratory.building,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? AppTheme.successSoft
                        : AppTheme.dangerSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    active ? 'Aktif' : 'Nonaktif',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: active
                          ? AppTheme.success
                          : AppTheme.danger,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            Wrap(
              spacing: 20,
              runSpacing: 10,
              children: [
                _InfoItem(
                  icon: Icons.people_outline,
                  text: '${laboratory.capacity} orang',
                ),
                _InfoItem(
                  icon: Icons.access_time,
                  text: laboratory.operationalHours,
                ),
                _InfoItem(
                  icon: Icons.location_on_outlined,
                  text: laboratory.labId,
                ),
              ],
            ),

            const SizedBox(height: 14),

            const Text(
              'Fasilitas:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppTheme.ink,
              ),
            ),

            const SizedBox(height: 8),

            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: laboratory.facilities.map((facility) {
                return Chip(
                  label: Text(
                    facility,
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: AppTheme.soft,
                  side: BorderSide.none,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),

            const Divider(height: 28),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 17,
                  ),
                  label: const Text('Edit'),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: onDelete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.danger,
                  ),
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 17,
                  ),
                  label: const Text('Hapus'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: AppTheme.muted,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.muted,
          ),
        ),
      ],
    );
  }
}

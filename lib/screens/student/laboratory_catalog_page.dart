import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../models/laboratory_model.dart';
import '../../services/firestore_service.dart';
import 'laboratory_detail_page.dart';
import 'widgets/info_state.dart';

class LaboratoryCatalog extends StatefulWidget {
  const LaboratoryCatalog({super.key});

  @override
  State<LaboratoryCatalog> createState() => _LaboratoryCatalogState();
}

class _LaboratoryCatalogState extends State<LaboratoryCatalog> {
  final search = TextEditingController();
  final labs = FirestoreService();

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<List<LaboratoryModel>>(
        stream: labs.getActiveLaboratories(),
        builder: (context, snapshot) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Laboratorium',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                'Lihat informasi dan fasilitas laboratorium kampus.',
                style: TextStyle(color: AppTheme.muted),
              ),
              const SizedBox(height: 22),
              TextField(
                controller: search,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Cari nama, lokasi, atau fasilitas',
                ),
              ),
              const SizedBox(height: 22),
              if (snapshot.hasError)
                const InfoState(
                  icon: Icons.wifi_off_rounded,
                  text:
                      'Gagal memuat laboratorium. Periksa koneksi atau izin Firestore.',
                ),
              if (!snapshot.hasError && !snapshot.hasData)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(36),
                    child: CircularProgressIndicator(),
                  ),
                ),
              if (snapshot.hasData) ...[
                Builder(
                  builder: (_) {
                    final q = search.text.toLowerCase().trim();
                    final items = snapshot.data!
                        .where((lab) =>
                            '${lab.name} ${lab.building} ${lab.facilities.join(' ')}'
                                .toLowerCase()
                                .contains(q))
                        .toList()
                      ..sort((a, b) => a.name.compareTo(b.name));
                    if (items.isEmpty) {
                      return const InfoState(
                        icon: Icons.search_off,
                        text: 'Belum ada laboratorium yang cocok.',
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${items.length} laboratorium',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        for (final lab in items)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _LabCard(lab: lab),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ],
          );
        },
      );
}

class _LabCard extends StatelessWidget {
  const _LabCard({required this.lab});
  final LaboratoryModel lab;

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => LaboratoryDetail(lab: lab),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 88,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7FC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: lab.imageUrl != null && lab.imageUrl!.isNotEmpty
                        ? Image.network(
                            lab.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.computer_rounded,
                              color: AppTheme.deep,
                              size: 36,
                            ),
                          )
                        : const Icon(
                            Icons.computer_rounded,
                            color: AppTheme.deep,
                            size: 36,
                          ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lab.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 9),
                      Text(
                        lab.building,
                        style: const TextStyle(
                          color: AppTheme.muted,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Kapasitas ${lab.capacity} orang',
                        style: const TextStyle(
                          color: AppTheme.muted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Lihat detail  ›',
                        style: TextStyle(
                          color: AppTheme.deep,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

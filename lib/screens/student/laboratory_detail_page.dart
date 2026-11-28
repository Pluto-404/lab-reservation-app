import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../models/laboratory_model.dart';
import '../../routes/app_routes.dart';

class LaboratoryDetail extends StatelessWidget {
  const LaboratoryDetail({super.key, required this.lab});
  final LaboratoryModel lab;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Detail Laboratorium')),
        body: SafeArea(
          child: PageWidth(
            maxWidth: 680,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Container(
                  height: 184,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7FC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: lab.imageUrl != null && lab.imageUrl!.isNotEmpty
                        ? Image.network(
                            lab.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.apartment_rounded,
                              color: AppTheme.deep,
                              size: 56,
                            ),
                          )
                        : const Icon(
                            Icons.apartment_rounded,
                            color: AppTheme.deep,
                            size: 56,
                          ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  lab.name,
                  style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: AppTheme.muted,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        lab.building,
                        style: const TextStyle(color: AppTheme.muted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                const Text(
                  'Informasi laboratorium',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 15),
                _DetailRow(
                  icon: Icons.groups_outlined,
                  label: 'Kapasitas',
                  value: '${lab.capacity} orang',
                ),
                _DetailRow(
                  icon: Icons.schedule_outlined,
                  label: 'Jam operasional',
                  value: lab.operationalHours.isEmpty
                      ? 'Belum ditentukan'
                      : lab.operationalHours,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Fasilitas tersedia',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                if (lab.facilities.isEmpty)
                  const Text(
                    'Fasilitas belum didata.',
                    style: TextStyle(color: AppTheme.muted),
                  ),
                for (final item in lab.facilities)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 18,
                          color: AppTheme.success,
                        ),
                        const SizedBox(width: 9),
                        Expanded(child: Text(item)),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7FC),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.deep, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Reservasi memerlukan persetujuan asisten lab.',
                          style: TextStyle(color: AppTheme.deep, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRoutes.studentSchedule,
                    arguments: lab,
                  ),
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: const Text('Cek Jadwal & Ajukan'),
                ),
              ],
            ),
          ),
        ),
      );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.deep, size: 20),
            const SizedBox(width: 10),
            SizedBox(
              width: 111,
              child: Text(
                label,
                style: const TextStyle(color: AppTheme.muted, fontSize: 12),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
}

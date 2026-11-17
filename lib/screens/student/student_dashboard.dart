import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../models/user_model.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({
    super.key,
    required this.profile,
    required this.openCatalog,
  });

  final UserModel profile;
  final VoidCallback openCatalog;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Halo, ${profile.name.isEmpty ? 'Mahasiswa' : profile.name.split(' ').first}!',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 7),
          const Text(
            'Temukan laboratorium yang cocok untuk kegiatanmu.',
            style: TextStyle(color: AppTheme.muted),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7FC),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.event_available_outlined,
                  color: AppTheme.deep,
                  size: 32,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Butuh laboratorium?',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Lihat fasilitas dan pilih lab sebelum mengajukan reservasi.',
                  style: TextStyle(color: AppTheme.muted),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: openCatalog,
                  icon: const Icon(Icons.search),
                  label: const Text('Jelajahi laboratorium'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Cara menggunakan LabBook',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          const _Instruction(
            icon: Icons.apartment_outlined,
            number: '01',
            title: 'Temukan laboratorium',
            detail: 'Cari berdasarkan nama, lokasi, dan fasilitas.',
          ),
          const _Instruction(
            icon: Icons.calendar_month_outlined,
            number: '02',
            title: 'Periksa jadwal',
            detail: 'Pilih tanggal dan jam melalui fitur reservasi.',
          ),
          const _Instruction(
            icon: Icons.verified_outlined,
            number: '03',
            title: 'Tunggu persetujuan',
            detail: 'Pengajuan akan diperiksa asisten laboratorium.',
          ),
        ],
      );
}

class _Instruction extends StatelessWidget {
  const _Instruction({
    required this.icon,
    required this.number,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String number;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7FC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppTheme.deep),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$number · $title',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        detail,
                        style: const TextStyle(color: AppTheme.muted, fontSize: 12),
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

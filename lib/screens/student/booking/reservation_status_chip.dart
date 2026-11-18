import 'package:flutter/material.dart';

import '../../../app_theme.dart';

/// Chip status reservasi (teks + warna, bukan warna saja).
class ReservationStatusChip extends StatelessWidget {
  const ReservationStatusChip({super.key, required this.status});

  final String status;

  static String label(String status) => switch (status) {
    'pending' => 'Menunggu',
    'approved' => 'Disetujui',
    'rejected' => 'Ditolak',
    'cancelled' => 'Dibatalkan',
    'completed' => 'Selesai',
    'maintenance_block' => 'Diblokir',
    _ => status,
  };

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (status) {
      'pending' => (AppTheme.warningSoft, AppTheme.warning),
      'approved' => (AppTheme.successSoft, const Color(0xFF16845B)),
      'rejected' => (AppTheme.dangerSoft, AppTheme.danger),
      'completed' => (AppTheme.soft, AppTheme.deep),
      _ => (const Color(0xFFEEF2F6), AppTheme.muted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label(status),
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

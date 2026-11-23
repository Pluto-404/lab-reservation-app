import 'package:flutter/material.dart';

import '../app_theme.dart';

/// Chip status reservasi (teks + warna semantik, bukan warna saja).
/// Mengikuti spesifikasi komponen DESIGN.md section 6:
/// - Rounded rectangle dengan radius 8
/// - Menampilkan label tekstual bahasa Indonesia
/// - Menggunakan palet token AppTheme
class ReservationStatusChip extends StatelessWidget {
  const ReservationStatusChip({
    super.key,
    required this.status,
    this.compact = false,
  });

  final String status;
  final bool compact;

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
      'approved' => (AppTheme.successSoft, AppTheme.success),
      'rejected' => (AppTheme.dangerSoft, AppTheme.danger),
      'completed' => (AppTheme.soft, AppTheme.deep),
      _ => (const Color(0xFFEEF2F6), AppTheme.muted),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label(status),
        style: TextStyle(
          color: fg,
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

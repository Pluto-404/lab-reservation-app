import '../models/reservation_model.dart';
import 'date_id.dart';

/// Filter rentang waktu untuk daftar jadwal blokir.
enum BlockTimeFilter {
  upcoming('Akan Datang'),
  past('Sudah Lewat'),
  all('Semua');

  const BlockTimeFilter(this.label);
  final String label;
}

/// Grup jadwal blokir (tunggal atau seri rutin mingguan).
class ScheduleBlockGroup {
  const ScheduleBlockGroup({
    required this.groupKey,
    required this.items,
  });

  final String groupKey;
  final List<ReservationModel> items;

  ReservationModel get first => items.first;
  ReservationModel get last => items.last;
  bool get isRecurring => items.length > 1;
  int get count => items.length;

  String get labName => first.labName;
  String get title => first.title;
  String get purpose => first.purpose;

  /// Label pola mingguan, contoh: "Setiap Sabtu · 08:00 – 10:00 WIB".
  String get recurringScheduleLabel =>
      'Setiap ${DateId.dayLong(first.startTime)} · '
      '${DateId.range(first.startTime, first.endTime)} WIB';

  /// Rentang tanggal seri, contoh: "28 Nov 2026 – 13 Mar 2027".
  String get dateRangeLabel {
    if (items.length == 1) return DateId.short(first.startTime);
    return '${DateId.short(first.startTime)} – ${DateId.short(last.startTime)}';
  }
}

/// Helper murni untuk menyaring dan mengelompokkan jadwal blokir admin.
class ScheduleBlockHelper {
  ScheduleBlockHelper._();

  static List<ReservationModel> filterBlocks({
    required List<ReservationModel> reservations,
    BlockTimeFilter timeFilter = BlockTimeFilter.upcoming,
    String? labId,
    String query = '',
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final q = query.trim().toLowerCase();

    final filtered = reservations.where((r) {
      if (r.type != 'maintenance_block') return false;

      final matchesTime = switch (timeFilter) {
        BlockTimeFilter.upcoming => r.endTime.isAfter(current),
        BlockTimeFilter.past => !r.endTime.isAfter(current),
        BlockTimeFilter.all => true,
      };
      if (!matchesTime) return false;

      if (labId != null && labId.isNotEmpty && r.labId != labId) return false;

      if (q.isNotEmpty) {
        final haystack =
            '${r.title} ${r.purpose} ${r.labName}'.toLowerCase();
        if (!haystack.contains(q)) return false;
      }

      return true;
    }).toList();

    // Urutkan: untuk 'Akan Datang' terdekat lebih dulu; untuk 'Sudah Lewat'/'Semua' terbaru lebih dulu.
    filtered.sort((a, b) {
      if (timeFilter == BlockTimeFilter.upcoming) {
        return a.startTime.compareTo(b.startTime);
      }
      return b.startTime.compareTo(a.startTime);
    });

    return filtered;
  }

  /// Mengelompokkan blokir yang memiliki kesamaan lab, judul, keterangan,
  /// hari dalam seminggu, dan jam mulai–selesai.
  static List<ScheduleBlockGroup> groupBlocks(
    List<ReservationModel> blocks,
  ) {
    final Map<String, List<ReservationModel>> grouped = {};
    for (final b in blocks) {
      final startMin = b.startTime.hour * 60 + b.startTime.minute;
      final endMin = b.endTime.hour * 60 + b.endTime.minute;
      final key =
          '${b.labId}|${b.title.trim()}|${b.purpose.trim()}|${b.startTime.weekday}|$startMin|$endMin';
      grouped.putIfAbsent(key, () => []).add(b);
    }

    return grouped.entries.map((entry) {
      final sortedItems = [...entry.value]
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
      return ScheduleBlockGroup(
        groupKey: entry.key,
        items: sortedItems,
      );
    }).toList();
  }
}

import '../models/laboratory_model.dart';
import '../models/reservation_model.dart';
import 'date_id.dart';

/// Rentang periode filter laporan admin.
enum ReportPeriod {
  all('Semua'),
  today('Hari Ini'),
  last7Days('7 Hari'),
  last30Days('30 Hari');

  const ReportPeriod(this.label);
  final String label;
}

/// Statistik utilisasi satu laboratorium.
class LabUtilizationStat {
  const LabUtilizationStat({
    required this.labId,
    required this.labName,
    required this.bookingCount,
    required this.totalMinutes,
  });

  final String labId;
  final String labName;
  final int bookingCount;
  final int totalMinutes;

  double get totalHours => totalMinutes / 60.0;
}

/// Ringkasan laporan peminjaman untuk evaluasi utilisasi lab.
class ReportSummary {
  const ReportSummary({
    required this.totalBookings,
    required this.approvedOrCompletedCount,
    required this.completedCount,
    required this.pendingCount,
    required this.rejectedCount,
    required this.cancelledCount,
    required this.walkInCount,
    required this.totalUsageMinutes,
    required this.labStats,
  });

  final int totalBookings;
  final int approvedOrCompletedCount;
  final int completedCount;
  final int pendingCount;
  final int rejectedCount;
  final int cancelledCount;
  final int walkInCount;
  final int totalUsageMinutes;
  final List<LabUtilizationStat> labStats;

  double get totalUsageHours => totalUsageMinutes / 60.0;

  /// Persentase pengajuan yang disetujui/selesai dari pengajuan yang sudah diputuskan
  /// (approved + completed + rejected), atau 0 bila belum ada.
  int get approvalRatePercent {
    final decided = approvedOrCompletedCount + rejectedCount;
    if (decided == 0) return 0;
    return ((approvedOrCompletedCount / decided) * 100).round();
  }

  LabUtilizationStat? get topLab => labStats.isEmpty ? null : labStats.first;
}

/// Kalkulator murni untuk laporan dan utilisasi laboratorium.
class ReportCalculator {
  ReportCalculator._();

  /// Mengembalikan status efektif untuk tampilan laporan/riwayat:
  /// reservasi `approved` yang `endTime` sudah lewat ditampilkan sebagai `completed`.
  static String effectiveStatus(ReservationModel r, {DateTime? now}) {
    final current = now ?? DateTime.now();
    if (r.status == 'approved' && !r.endTime.isAfter(current)) {
      return 'completed';
    }
    return r.status;
  }

  static bool matchesPeriod(
    ReservationModel r,
    ReportPeriod period, {
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final today = DateId.dateOnly(current);
    final bookingDay = DateId.dateOnly(r.startTime);

    return switch (period) {
      ReportPeriod.all => true,
      ReportPeriod.today => DateId.isSameDay(bookingDay, today),
      ReportPeriod.last7Days =>
        !bookingDay.isBefore(DateId.addDays(today, -6)) &&
            !bookingDay.isAfter(today),
      ReportPeriod.last30Days =>
        !bookingDay.isBefore(DateId.addDays(today, -29)) &&
            !bookingDay.isAfter(today),
    };
  }

  /// Menyaring daftar reservasi non-maintenance berdasarkan periode, lab, dan status efektif.
  static List<ReservationModel> filterReservations({
    required List<ReservationModel> reservations,
    ReportPeriod period = ReportPeriod.all,
    String? labId,
    String statusFilter = 'semua',
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final filtered = reservations.where((r) {
      if (r.type == 'maintenance_block') return false;
      if (!matchesPeriod(r, period, now: current)) return false;
      if (labId != null && labId.isNotEmpty && r.labId != labId) return false;
      if (statusFilter != 'semua' &&
          effectiveStatus(r, now: current) != statusFilter) {
        return false;
      }
      return true;
    }).toList();

    filtered.sort((a, b) => b.startTime.compareTo(a.startTime));
    return filtered;
  }

  /// Menghitung ringkasan metrik dan utilisasi per lab dari daftar reservasi terfilter.
  static ReportSummary summarize({
    required List<ReservationModel> reservations,
    required List<LaboratoryModel> laboratories,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    var approvedOrCompleted = 0;
    var completed = 0;
    var pending = 0;
    var rejected = 0;
    var cancelled = 0;
    var walkIn = 0;
    var totalUsageMinutes = 0;

    final Map<String, String> labNames = {
      for (final lab in laboratories) lab.labId: lab.name,
    };
    final Map<String, int> countByLab = {};
    final Map<String, int> minutesByLab = {};

    for (final r in reservations) {
      if (r.type == 'maintenance_block') continue;
      if (r.type == 'walk_in') walkIn++;

      final status = effectiveStatus(r, now: current);
      switch (status) {
        case 'approved':
          approvedOrCompleted++;
        case 'completed':
          approvedOrCompleted++;
          completed++;
        case 'pending':
          pending++;
        case 'rejected':
          rejected++;
        case 'cancelled':
          cancelled++;
      }

      if (status == 'approved' || status == 'completed') {
        final duration = r.endTime.difference(r.startTime).inMinutes;
        if (duration > 0) {
          totalUsageMinutes += duration;
          labNames.putIfAbsent(r.labId, () => r.labName);
          countByLab[r.labId] = (countByLab[r.labId] ?? 0) + 1;
          minutesByLab[r.labId] = (minutesByLab[r.labId] ?? 0) + duration;
        }
      }
    }

    final labStats = <LabUtilizationStat>[
      for (final entry in labNames.entries)
        LabUtilizationStat(
          labId: entry.key,
          labName: entry.value,
          bookingCount: countByLab[entry.key] ?? 0,
          totalMinutes: minutesByLab[entry.key] ?? 0,
        ),
    ]..sort((a, b) {
        final byMinutes = b.totalMinutes.compareTo(a.totalMinutes);
        if (byMinutes != 0) return byMinutes;
        return a.labName.compareTo(b.labName);
      });

    final totalNonMaintenance =
        reservations.where((r) => r.type != 'maintenance_block').length;

    return ReportSummary(
      totalBookings: totalNonMaintenance,
      approvedOrCompletedCount: approvedOrCompleted,
      completedCount: completed,
      pendingCount: pending,
      rejectedCount: rejected,
      cancelledCount: cancelled,
      walkInCount: walkIn,
      totalUsageMinutes: totalUsageMinutes,
      labStats: labStats,
    );
  }

  static String formatHours(double hours) {
    if (hours == hours.roundToDouble()) {
      return '${hours.toInt()} jam';
    }
    return '${hours.toStringAsFixed(1)} jam';
  }

  static String buildPlainTextSummary({
    required ReportSummary summary,
    required ReportPeriod period,
    String? labName,
  }) {
    final buffer = StringBuffer()
      ..writeln('Laporan Utilisasi Laboratorium LabBook')
      ..writeln('Periode: ${period.label}')
      ..writeln('Filter Lab: ${labName ?? 'Semua Laboratorium'}')
      ..writeln('Total Peminjaman: ${summary.totalBookings}')
      ..writeln(
        'Disetujui / Selesai: ${summary.approvedOrCompletedCount} '
        '(${summary.approvalRatePercent}%)',
      )
      ..writeln('Walk-in: ${summary.walkInCount}')
      ..writeln('Total Jam Pakai: ${formatHours(summary.totalUsageHours)}');

    if (summary.labStats.isNotEmpty) {
      buffer.writeln('\nUtilisasi per Laboratorium:');
      for (final stat in summary.labStats) {
        buffer.writeln(
          '- ${stat.labName}: ${stat.bookingCount} peminjaman '
          '(${formatHours(stat.totalHours)})',
        );
      }
    }
    return buffer.toString().trim();
  }
}

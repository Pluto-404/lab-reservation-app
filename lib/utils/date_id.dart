/// Helper format tanggal & jam berbahasa Indonesia (tanpa package intl).
class DateId {
  DateId._();

  static const _daysShort = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
  static const _daysLong = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];
  static const _monthsShort = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  static const _monthsLong = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Hari Senin pada minggu dari tanggal [d] (jam 00:00).
  static DateTime startOfWeek(DateTime d) =>
      DateTime(d.year, d.month, d.day - (d.weekday - 1));

  static DateTime addDays(DateTime d, int days) =>
      DateTime(d.year, d.month, d.day + days);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String dayShort(DateTime d) => _daysShort[d.weekday - 1];
  static String dayLong(DateTime d) => _daysLong[d.weekday - 1];

  /// Contoh: "Senin, 23 November 2026"
  static String full(DateTime d) =>
      '${dayLong(d)}, ${d.day} ${_monthsLong[d.month - 1]} ${d.year}';

  /// Contoh: "23 Nov 2026"
  static String short(DateTime d) =>
      '${d.day} ${_monthsShort[d.month - 1]} ${d.year}';

  /// Contoh: "08:30"
  static String time(DateTime d) => hm(d.hour, d.minute);

  static String hm(int hour, int minute) =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  /// Contoh: "08:00 – 10:00"
  static String range(DateTime start, DateTime end) =>
      '${time(start)} – ${time(end)}';

  /// Label minggu, contoh: "23 – 29 Nov 2026" atau "30 Nov – 6 Des 2026".
  static String weekLabel(DateTime weekStart) {
    final end = addDays(weekStart, 6);
    if (weekStart.year != end.year) {
      return '${short(weekStart)} – ${short(end)}';
    }
    if (weekStart.month != end.month) {
      return '${weekStart.day} ${_monthsShort[weekStart.month - 1]} – '
          '${end.day} ${_monthsShort[end.month - 1]} ${end.year}';
    }
    return '${weekStart.day} – ${end.day} '
        '${_monthsShort[end.month - 1]} ${end.year}';
  }
}

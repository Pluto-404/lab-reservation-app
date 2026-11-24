import '../models/laboratory_model.dart';
import '../models/reservation_model.dart';
import 'date_id.dart';

/// Jam operasional laboratorium hasil parsing teks, contoh "08:00 - 16:00".
class OperationalHours {
  const OperationalHours(
    this.startMinute,
    this.endMinute, {
    this.isDefined = true,
  });

  final int startMinute;
  final int endMinute;

  /// false bila teks jam operasional kosong / tidak bisa dibaca. Pada kasus ini
  /// kalender memakai rentang tampilan bawaan dan validasi jam tidak dipaksa.
  final bool isDefined;

  /// Rentang tampilan bawaan kalender (bukan aturan lab).
  static const fallback = OperationalHours(7 * 60, 18 * 60, isDefined: false);

  factory OperationalHours.parse(String raw) {
    final matches = RegExp(r'(\d{1,2})[:.](\d{2})').allMatches(raw).toList();
    if (matches.length < 2) return fallback;
    int toMinute(RegExpMatch m) =>
        int.parse(m.group(1)!) * 60 + int.parse(m.group(2)!);
    final start = toMinute(matches[0]);
    final end = toMinute(matches[1]);
    if (start < 0 || end > 24 * 60 || end <= start) return fallback;
    return OperationalHours(start, end);
  }

  /// Jam pertama yang ditampilkan di grid kalender.
  int get firstHour => startMinute ~/ 60;

  /// Jam akhir (eksklusif) grid kalender.
  int get lastHour => (endMinute + 59) ~/ 60;

  String get label =>
      '${DateId.hm(startMinute ~/ 60, startMinute % 60)} – '
      '${DateId.hm(endMinute ~/ 60, endMinute % 60)}';
}

/// Aturan validasi pengajuan booking (murni logika, mudah diuji).
///
/// Aturan bentrok mengikuti DOKUMEN_PERANCANGAN_LABBOOK.md:
/// `(start < existing.end) && (end > existing.start)` pada lab yang sama dan
/// status `approved` atau `maintenance_block`.
class BookingValidator {
  BookingValidator._();

  static bool overlaps(
    DateTime aStart,
    DateTime aEnd,
    DateTime bStart,
    DateTime bEnd,
  ) => aStart.isBefore(bEnd) && aEnd.isAfter(bStart);

  /// Jadwal yang mengunci slot (tidak bisa dipesan orang lain).
  static bool isBlocking(ReservationModel r) =>
      r.status == 'approved' ||
      r.status == 'maintenance_block' ||
      r.type == 'maintenance_block';

  static ReservationModel? findBlockingConflict({
    required DateTime start,
    required DateTime end,
    required List<ReservationModel> labSchedule,
  }) {
    for (final r in labSchedule) {
      if (isBlocking(r) && overlaps(start, end, r.startTime, r.endTime)) {
        return r;
      }
    }
    return null;
  }

  /// Pengajuan milik pengguna sendiri (menunggu / disetujui) yang beririsan,
  /// agar tidak mengajukan slot yang sama dua kali.
  static ReservationModel? findOwnConflict({
    required DateTime start,
    required DateTime end,
    required String labId,
    required List<ReservationModel> myReservations,
  }) {
    for (final r in myReservations) {
      final active = r.status == 'pending' || r.status == 'approved';
      if (active &&
          r.labId == labId &&
          overlaps(start, end, r.startTime, r.endTime)) {
        return r;
      }
    }
    return null;
  }

  /// Mengembalikan pesan kesalahan pertama, atau null bila jadwal valid.
  /// Bila [start] atau [end] belum lengkap, mengembalikan null (belum dicek).
  static String? validateSchedule({
    required LaboratoryModel lab,
    required DateTime? start,
    required DateTime? end,
    List<ReservationModel> labSchedule = const [],
    List<ReservationModel> myReservations = const [],
    DateTime? now,
  }) {
    if (start == null || end == null) return null;
    final current = now ?? DateTime.now();

    if (!end.isAfter(start)) {
      return 'Waktu selesai harus setelah waktu mulai.';
    }
    if (!DateId.isSameDay(start, end)) {
      return 'Peminjaman hanya dapat dilakukan dalam satu hari yang sama.';
    }
    if (start.isBefore(current)) {
      return 'Waktu mulai sudah lewat. Pilih jadwal yang akan datang.';
    }

    final hours = OperationalHours.parse(lab.operationalHours);
    if (hours.isDefined) {
      final startMin = start.hour * 60 + start.minute;
      final endMin = end.hour * 60 + end.minute;
      if (startMin < hours.startMinute || endMin > hours.endMinute) {
        return 'Jadwal di luar jam operasional laboratorium (${hours.label}).';
      }
    }

    final blocking = findBlockingConflict(
      start: start,
      end: end,
      labSchedule: labSchedule,
    );
    if (blocking != null) {
      final what = blocking.type == 'maintenance_block'
          ? 'diblokir untuk "${blocking.title}"'
          : 'sudah digunakan untuk "${blocking.title}"';
      return 'Jadwal tersebut $what '
          '(${DateId.range(blocking.startTime, blocking.endTime)}). '
          'Silakan pilih waktu lain.';
    }

    final own = findOwnConflict(
      start: start,
      end: end,
      labId: lab.labId,
      myReservations: myReservations,
    );
    if (own != null) {
      final state = own.status == 'pending'
          ? 'menunggu persetujuan'
          : 'sudah disetujui';
      return 'Kamu sudah punya pengajuan pada jam tersebut ($state, '
          '${DateId.range(own.startTime, own.endTime)}).';
    }
    return null;
  }

  static String? validateParticipants({
    required String raw,
    required LaboratoryModel lab,
  }) {
    final text = raw.trim();
    if (text.isEmpty) return 'Isi jumlah peserta.';
    final value = int.tryParse(text);
    if (value == null || value < 1) {
      return 'Jumlah peserta minimal 1 orang.';
    }
    if (lab.capacity > 0 && value > lab.capacity) {
      return 'Jumlah peserta melebihi kapasitas laboratorium '
          '(${lab.capacity} orang).';
    }
    return null;
  }
}

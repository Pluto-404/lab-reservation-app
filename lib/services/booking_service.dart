import '../models/laboratory_model.dart';
import '../models/reservation_model.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

/// Lapisan data untuk fitur kalender & pengajuan booking mahasiswa.
/// Memakai FirestoreService milik tim (cek bentrok + simpan reservasi).
class BookingService {
  final FirestoreService _firestore = FirestoreService();

  /// Jadwal lab yang mengunci slot (approved + maintenance_block), realtime.
  Stream<List<ReservationModel>> watchLabSchedule(String labId) =>
      _firestore.getCalendarReservations(labId);

  /// Seluruh reservasi milik mahasiswa, realtime. Diurutkan di sisi klien agar
  /// tidak membutuhkan composite index tambahan di Firestore.
  Stream<List<ReservationModel>> watchMyReservations(String userId) =>
      _firestore.getMyReservations(userId);

  /// Kirim pengajuan. Cek bentrok dijalankan lagi di lapisan data
  /// (FirestoreService.createReservation) sebelum dokumen disimpan.
  Future<String> submit({
    required LaboratoryModel lab,
    required UserModel profile,
    required String title,
    required String purpose,
    required int participants,
    required DateTime start,
    required DateTime end,
  }) async {
    final reservation = ReservationModel(
      reservationId: '',
      labId: lab.labId,
      labName: lab.name,
      userId: profile.uid,
      studentName: profile.name,
      studentNim: profile.nim,
      studentClass: profile.className,
      title: title,
      purpose: purpose,
      participants: participants,
      startTime: start,
      endTime: end,
      createdAt: DateTime.now(),
    );
    return await _firestore
        .createReservation(reservation)
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () => throw Exception(
            'Koneksi terlalu lama. Periksa internet lalu coba lagi.',
          ),
        );
  }

  /// Batalkan hanya reservasi milik pengguna, sebelum waktu mulai.
  /// Menggunakan transaksi dan validasi pada FirestoreService.
  Future<void> cancelMyReservation({
    required String reservationId,
    required String userId,
  }) {
    return _firestore.cancelReservation(
      reservationId: reservationId,
      userId: userId,
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  /// Seluruh reservasi milik mahasiswa, realtime. Difilter di sisi klien agar
  /// tidak membutuhkan composite index tambahan di Firestore.
  Stream<List<ReservationModel>> watchMyReservations(String userId) {
    if (userId.isEmpty) return Stream.value(const <ReservationModel>[]);
    return FirebaseFirestore.instance
        .collection('reservations')
        .where('user_id', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ReservationModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Kirim pengajuan. Cek bentrok dijalankan lagi di lapisan data
  /// (FirestoreService.createReservation) sebelum dokumen disimpan.
  Future<void> submit({
    required LaboratoryModel lab,
    required UserModel profile,
    required String title,
    required String purpose,
    required int participants,
    required DateTime start,
    required DateTime end,
  }) {
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
    return _firestore
        .createReservation(reservation)
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () => throw Exception(
            'Koneksi terlalu lama. Periksa internet lalu coba lagi.',
          ),
        );
  }
  /// Batalkan hanya reservasi milik pengguna, sebelum waktu mulai.
  /// Transaksi mencegah pembatalan status yang sudah berubah saat diproses.
  /// Firestore Security Rules tetap wajib membatasi update di sisi server.
  Future<void> cancelMyReservation({
    required String reservationId,
    required String userId,
  }) async {
    if (reservationId.isEmpty ||
        userId.isEmpty ||
        FirebaseAuth.instance.currentUser?.uid != userId) {
      throw StateError('Data pemesanan tidak valid.');
    }
    final ref = FirebaseFirestore.instance.collection('reservations').doc(reservationId);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final doc = await transaction.get(ref);
      if (!doc.exists) throw StateError('Pemesanan tidak ditemukan.');
      final booking = ReservationModel.fromFirestore(doc);
      if (booking.userId != userId || booking.type != 'student_booking') {
        throw StateError('Kamu tidak dapat membatalkan pemesanan ini.');
      }
      if (booking.status != 'pending' && booking.status != 'approved') {
        throw StateError('Status pemesanan tidak dapat dibatalkan.');
      }
      if (!booking.startTime.isAfter(DateTime.now())) {
        throw StateError('Pemesanan yang sudah dimulai tidak bisa dibatalkan.');
      }
      transaction.update(ref, {'status': 'cancelled'});
    });
  }

}

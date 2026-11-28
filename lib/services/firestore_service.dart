import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/laboratory_model.dart';
import '../models/reservation_model.dart';
import '../utils/booking_validator.dart';
import '../utils/date_id.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Koleksi Firestore
  CollectionReference get _labsRef => _firestore.collection('laboratories');
  CollectionReference get _reservationsRef => _firestore.collection('reservations');

  /// Stream daftar laboratorium aktif (untuk katalog mahasiswa)
  Stream<List<LaboratoryModel>> getActiveLaboratories() {
    return _labsRef
        .where('is_active', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => LaboratoryModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Stream semua laboratorium (untuk manajemen oleh Admin)
  Stream<List<LaboratoryModel>> getAllLaboratories() {
    return _labsRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => LaboratoryModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Mengambil detail satu laboratorium berdasarkan ID
  Future<LaboratoryModel?> getLaboratoryById(String labId) async {
    final doc = await _labsRef.doc(labId).get();
    if (doc.exists) {
      return LaboratoryModel.fromFirestore(doc);
    }
    return null;
  }

  /// Menambah laboratorium baru (Admin)
  Future<void> addLaboratory(LaboratoryModel lab) async {
    final docRef = _labsRef.doc();
    final newLab = LaboratoryModel(
      labId: docRef.id,
      name: lab.name,
      building: lab.building,
      capacity: lab.capacity,
      facilities: lab.facilities,
      operationalHours: lab.operationalHours,
      isActive: lab.isActive,
      imageUrl: lab.imageUrl,
    );
    await docRef.set(newLab.toMap());
  }

  /// Memperbarui informasi laboratorium (Admin)
  Future<void> updateLaboratory(LaboratoryModel lab) async {
    await _labsRef.doc(lab.labId).update(lab.toMap());
  }

  /// Menghapus laboratorium (Admin)
Future<void> deleteLaboratory(String labId) async {
  await _labsRef.doc(labId).delete();
}

  /// Mengubah status aktif laboratorium (Admin)
  Future<void> toggleLabStatus(String labId, bool isActive) async {
    await _labsRef.doc(labId).update({'is_active': isActive});
  }

  /// Mengecek apakah ada jadwal yang beririsan pada lab yang sama.
  /// Kondisi bentrok: (start_time < existing.end_time) AND (end_time > existing.start_time)
  /// Berlaku untuk status 'approved' atau 'maintenance_block'
  Future<bool> checkScheduleConflict({
    required String labId,
    required DateTime startTime,
    required DateTime endTime,
    String? excludeReservationId,
  }) async {
    // Ambil jadwal yang sudah disetujui atau diblokir maintenance pada lab tersebut
    final querySnapshot = await _reservationsRef
        .where('lab_id', isEqualTo: labId)
        .where('status', whereIn: ['approved', 'maintenance_block'])
        .get();

    for (final doc in querySnapshot.docs) {
      // Jika sedang edit, lewati reservasi itu sendiri
      if (excludeReservationId != null && doc.id == excludeReservationId) {
        continue;
      }

      final existing = ReservationModel.fromFirestore(doc);

      // Pastikan jadwal ini berstatus approved atau bertipe maintenance_block
      final bool isBlocking = existing.status == 'approved' ||
          existing.status == 'maintenance_block' ||
          existing.type == 'maintenance_block';
      if (!isBlocking) continue;

      // Rumus bentrok rentang waktu
      final bool isOverlapping =
          startTime.isBefore(existing.endTime) && endTime.isAfter(existing.startTime);

      if (isOverlapping) {
        return true; // Ditemukan jadwal bentrok!
      }
    }

    return false; // Jadwal kosong dan aman dipesan
  }

  /// Pengajuan reservasi baru oleh mahasiswa (dengan pencegahan bentrok otomatis)
  /// Mengembalikan ID dokumen reservasi yang baru dibuat.
  Future<String> createReservation(ReservationModel reservation) async {
    // 1. Cek apakah ada jadwal bentrok terlebih dahulu
    final bool isConflict = await checkScheduleConflict(
      labId: reservation.labId,
      startTime: reservation.startTime,
      endTime: reservation.endTime,
    );

    if (isConflict) {
      throw Exception(
        'Jadwal yang kamu pilih bertabrakan dengan jadwal lain yang sudah disetujui atau sedang dalam masa pemeliharaan lab.',
      );
    }

    // 2. Simpan reservasi ke Firestore
    final docRef = _reservationsRef.doc();
    final newReservation = ReservationModel(
      reservationId: docRef.id,
      labId: reservation.labId,
      labName: reservation.labName,
      userId: reservation.userId,
      studentName: reservation.studentName,
      studentNim: reservation.studentNim,
      studentClass: reservation.studentClass,
      title: reservation.title,
      purpose: reservation.purpose,
      participants: reservation.participants,
      startTime: reservation.startTime,
      endTime: reservation.endTime,
      type: reservation.type,
      status: reservation.status, // Default 'pending'
      rejectionReason: reservation.rejectionReason,
      adminId: reservation.adminId,
      createdAt: DateTime.now(),
    );

    await docRef.set(newReservation.toMap());
    return docRef.id;
  }

  /// Stream riwayat reservasi mandiri milik mahasiswa yang sedang login.
  /// Diurutkan di sisi klien/memori agar tidak memerlukan composite index tambahan di Firestore.
  Stream<List<ReservationModel>> getMyReservations(String userId) {
    if (userId.isEmpty) return Stream.value(const <ReservationModel>[]);
    return _reservationsRef
        .where('user_id', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ReservationModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Stream antrean reservasi pending untuk Approval Center (Admin)
  Stream<List<ReservationModel>> getPendingReservations() {
    return _reservationsRef
        .where('status', isEqualTo: 'pending')
        .orderBy('created_at', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ReservationModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Stream seluruh reservasi untuk halaman Admin
  Stream<List<ReservationModel>> getAllReservations() {
    return _reservationsRef
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ReservationModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Stream seluruh reservasi aktif & approved untuk kalender interaktif
  Stream<List<ReservationModel>> getCalendarReservations(String labId) {
    return _reservationsRef
        .where('lab_id', isEqualTo: labId)
        .where('status', whereIn: ['approved', 'maintenance_block'])
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ReservationModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Menyetujui pengajuan peminjaman (Admin)
  /// Memeriksa apakah terjadi bentrok sebelum persetujuan disimpan.
  Future<void> approveReservation({
    required String reservationId,
    required String adminId,
  }) async {
    final doc = await _reservationsRef.doc(reservationId).get();
    if (!doc.exists) {
      throw Exception('Data reservasi tidak ditemukan.');
    }
    final booking = ReservationModel.fromFirestore(doc);

    // Cek apakah ada jadwal lain yang bertabrakan sebelum menyetujui
    final bool isConflict = await checkScheduleConflict(
      labId: booking.labId,
      startTime: booking.startTime,
      endTime: booking.endTime,
      excludeReservationId: reservationId,
    );

    if (isConflict) {
      throw Exception(
        'Tidak dapat menyetujui: Jadwal ini bertabrakan dengan jadwal lain yang sudah disetujui atau pemeliharaan lab.',
      );
    }

    await _reservationsRef.doc(reservationId).update({
      'status': 'approved',
      'admin_id': adminId,
    });
  }

  /// Menolak pengajuan peminjaman dengan wajib menyertakan alasan (Admin)
  Future<void> rejectReservation({
    required String reservationId,
    required String adminId,
    required String rejectionReason,
  }) async {
    await _reservationsRef.doc(reservationId).update({
      'status': 'rejected',
      'admin_id': adminId,
      'rejection_reason': rejectionReason,
    });
  }

  /// Pembatalan reservasi mandiri oleh mahasiswa sebelum jadwal berlangsung.
  /// Menjalankan transaksi dan validasi keamanan.
  Future<void> cancelReservation({
    required String reservationId,
    required String userId,
  }) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (reservationId.isEmpty || userId.isEmpty || currentUid != userId) {
      throw StateError('Data pemesanan tidak valid atau autentikasi tidak sesuai.');
    }

    final docRef = _reservationsRef.doc(reservationId);
    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      if (!doc.exists) {
        throw StateError('Pemesanan tidak ditemukan.');
      }
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
      transaction.update(docRef, {'status': 'cancelled'});
    });
  }

  /// Blokir jadwal untuk kelas reguler atau pemeliharaan (Admin)
  Future<void> blockMaintenanceSchedule({
    required String labId,
    required String labName,
    required String adminId,
    required String title,
    required String purpose,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final bool isConflict = await checkScheduleConflict(
      labId: labId,
      startTime: startTime,
      endTime: endTime,
    );
    if (isConflict) {
      throw Exception(
        'Slot waktu tersebut bertabrakan dengan jadwal yang sudah disetujui atau diblokir.',
      );
    }

    final docRef = _reservationsRef.doc();
    final blockReservation = ReservationModel(
      reservationId: docRef.id,
      labId: labId,
      labName: labName,
      userId: adminId,
      studentName: 'Laboran / Admin',
      studentNim: '-',
      studentClass: '-',
      title: title,
      purpose: purpose,
      startTime: startTime,
      endTime: endTime,
      type: 'maintenance_block',
      status: 'approved',
      adminId: adminId,
      createdAt: DateTime.now(),
    );

    await docRef.set(blockReservation.toMap());
  }

  /// Blokir jadwal rutin mingguan untuk kelas reguler atau pemeliharaan (Admin).
  /// Memeriksa seluruh minggu sebelum menyimpan secara atomik menggunakan batch.
  Future<int> blockRecurringMaintenanceSchedule({
    required String labId,
    required String labName,
    required String adminId,
    required String title,
    required String purpose,
    required DateTime firstStartTime,
    required DateTime firstEndTime,
    required int repeatWeeks,
  }) async {
    if (repeatWeeks <= 1) {
      await blockMaintenanceSchedule(
        labId: labId,
        labName: labName,
        adminId: adminId,
        title: title,
        purpose: purpose,
        startTime: firstStartTime,
        endTime: firstEndTime,
      );
      return 1;
    }

    final slots = BookingValidator.generateWeeklySlots(
      firstStart: firstStartTime,
      firstEnd: firstEndTime,
      weeks: repeatWeeks,
    );

    final querySnapshot = await _reservationsRef
        .where('lab_id', isEqualTo: labId)
        .where('status', whereIn: ['approved', 'maintenance_block'])
        .get();

    final existingBlocking = querySnapshot.docs
        .map((doc) => ReservationModel.fromFirestore(doc))
        .where(BookingValidator.isBlocking)
        .toList();

    final conflictingDates = <String>[];
    for (final slot in slots) {
      final conflict = BookingValidator.findBlockingConflict(
        start: slot.start,
        end: slot.end,
        labSchedule: existingBlocking,
      );
      if (conflict != null) {
        conflictingDates.add(DateId.short(slot.start));
      }
    }

    if (conflictingDates.isNotEmpty) {
      throw Exception(
        'Slot waktu bertabrakan dengan jadwal lain pada tanggal: '
        '${conflictingDates.join(', ')}.',
      );
    }

    final batch = _firestore.batch();
    final now = DateTime.now();
    for (final slot in slots) {
      final docRef = _reservationsRef.doc();
      final blockReservation = ReservationModel(
        reservationId: docRef.id,
        labId: labId,
        labName: labName,
        userId: adminId,
        studentName: 'Laboran / Admin',
        studentNim: '-',
        studentClass: '-',
        title: title,
        purpose: purpose,
        startTime: slot.start,
        endTime: slot.end,
        type: 'maintenance_block',
        status: 'approved',
        adminId: adminId,
        createdAt: now,
      );
      batch.set(docRef, blockReservation.toMap());
    }

    await batch.commit();
    return slots.length;
  }

  /// Menghapus blokir jadwal maintenance/kelas reguler (Admin)
  Future<void> deleteMaintenanceBlock(String reservationId) async {
    final docRef = _reservationsRef.doc(reservationId);
    final doc = await docRef.get();
    if (!doc.exists) {
      throw Exception('Jadwal blokir tidak ditemukan.');
    }
    final existing = ReservationModel.fromFirestore(doc);
    if (existing.type != 'maintenance_block') {
      throw Exception(
        'Hanya jadwal blokir pemeliharaan atau kelas reguler yang dapat dihapus di sini.',
      );
    }
    await docRef.delete();
  }

  /// Menghapus beberapa blokir jadwal sekaligus secara atomik (Admin)
  Future<int> deleteMaintenanceBlocks(List<String> reservationIds) async {
    if (reservationIds.isEmpty) return 0;
    final batch = _firestore.batch();
    for (final id in reservationIds) {
      batch.delete(_reservationsRef.doc(id));
    }
    await batch.commit();
    return reservationIds.length;
  }
}

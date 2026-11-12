import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/laboratory_model.dart';
import '../models/reservation_model.dart';

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
  Future<void> createReservation(ReservationModel reservation) async {
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
      startTime: reservation.startTime,
      endTime: reservation.endTime,
      type: reservation.type,
      status: reservation.status, // Default 'pending'
      rejectionReason: reservation.rejectionReason,
      adminId: reservation.adminId,
      createdAt: DateTime.now(),
    );

    await docRef.set(newReservation.toMap());
  }

  /// Stream riwayat reservasi mandiri milik mahasiswa yang sedang login
  Stream<List<ReservationModel>> getMyReservations(String userId) {
    return _reservationsRef
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ReservationModel.fromFirestore(doc))
          .toList();
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
  Future<void> approveReservation({
    required String reservationId,
    required String adminId,
  }) async {
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

  /// Pembatalan reservasi mandiri oleh mahasiswa sebelum jadwal berlangsung
  Future<void> cancelReservation(String reservationId) async {
    await _reservationsRef.doc(reservationId).update({
      'status': 'cancelled',
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
}

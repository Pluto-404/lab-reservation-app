import 'package:cloud_firestore/cloud_firestore.dart';

class ReservationModel {
  final String reservationId;
  final String labId;
  final String labName;
  final String userId;
  final String studentName;
  final String studentNim;
  final String studentClass;
  final String title;
  final String purpose;
  final DateTime startTime;
  final DateTime endTime;
  final String type; // 'student_booking' | 'walk_in' | 'maintenance_block'
  final String status; // 'pending' | 'approved' | 'rejected' | 'cancelled' | 'completed'
  final String? rejectionReason;
  final String? adminId;
  final DateTime createdAt;

  ReservationModel({
    required this.reservationId,
    required this.labId,
    required this.labName,
    required this.userId,
    required this.studentName,
    required this.studentNim,
    required this.studentClass,
    required this.title,
    required this.purpose,
    required this.startTime,
    required this.endTime,
    this.type = 'student_booking',
    this.status = 'pending',
    this.rejectionReason,
    this.adminId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'reservation_id': reservationId,
      'lab_id': labId,
      'lab_name': labName,
      'user_id': userId,
      'student_name': studentName,
      'student_nim': studentNim,
      'student_class': studentClass,
      'title': title,
      'purpose': purpose,
      'start_time': Timestamp.fromDate(startTime),
      'end_time': Timestamp.fromDate(endTime),
      'type': type,
      'status': status,
      'rejection_reason': rejectionReason,
      'admin_id': adminId,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  factory ReservationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ReservationModel(
      reservationId: doc.id,
      labId: data['lab_id'] ?? '',
      labName: data['lab_name'] ?? '',
      userId: data['user_id'] ?? '',
      studentName: data['student_name'] ?? '',
      studentNim: data['student_nim'] ?? '',
      studentClass: data['student_class'] ?? '',
      title: data['title'] ?? '',
      purpose: data['purpose'] ?? '',
      startTime: (data['start_time'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (data['end_time'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: data['type'] ?? 'student_booking',
      status: data['status'] ?? 'pending',
      rejectionReason: data['rejection_reason'],
      adminId: data['admin_id'],
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

}
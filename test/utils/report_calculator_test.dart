import 'package:flutter_test/flutter_test.dart';
import 'package:labbook/models/laboratory_model.dart';
import 'package:labbook/models/reservation_model.dart';
import 'package:labbook/utils/report_calculator.dart';

void main() {
  final labs = [
    LaboratoryModel(
      labId: 'lab-1',
      name: 'Lab RPL',
      building: 'Gedung A',
      capacity: 30,
      facilities: const ['30 PC'],
      operationalHours: '08:00 - 16:00',
    ),
    LaboratoryModel(
      labId: 'lab-2',
      name: 'Lab Jaringan',
      building: 'Gedung B',
      capacity: 25,
      facilities: const ['Router'],
      operationalHours: '08:00 - 16:00',
    ),
  ];

  ReservationModel makeReservation({
    required String id,
    required String labId,
    required String labName,
    required DateTime start,
    required DateTime end,
    String type = 'student_booking',
    String status = 'approved',
  }) {
    return ReservationModel(
      reservationId: id,
      labId: labId,
      labName: labName,
      userId: 'u-1',
      studentName: 'Budi',
      studentNim: 'K3523001',
      studentClass: 'PTIK A',
      title: 'Riset',
      purpose: 'Penelitian',
      startTime: start,
      endTime: end,
      type: type,
      status: status,
      createdAt: start,
    );
  }

  group('ReportCalculator', () {
    test('effectiveStatus marks past approved reservations as completed', () {
      final now = DateTime(2026, 11, 28, 15, 0);
      final pastApproved = makeReservation(
        id: '1',
        labId: 'lab-1',
        labName: 'Lab RPL',
        start: DateTime(2026, 11, 28, 8, 0),
        end: DateTime(2026, 11, 28, 10, 0),
        status: 'approved',
      );
      final futureApproved = makeReservation(
        id: '2',
        labId: 'lab-1',
        labName: 'Lab RPL',
        start: DateTime(2026, 11, 28, 16, 0),
        end: DateTime(2026, 11, 28, 18, 0),
        status: 'approved',
      );
      final pastPending = makeReservation(
        id: '3',
        labId: 'lab-1',
        labName: 'Lab RPL',
        start: DateTime(2026, 11, 28, 8, 0),
        end: DateTime(2026, 11, 28, 10, 0),
        status: 'pending',
      );

      expect(ReportCalculator.effectiveStatus(pastApproved, now: now), 'completed');
      expect(ReportCalculator.effectiveStatus(futureApproved, now: now), 'approved');
      expect(ReportCalculator.effectiveStatus(pastPending, now: now), 'pending');
    });

    test('filterReservations excludes maintenance blocks and filters by period & status', () {
      final now = DateTime(2026, 11, 28, 15, 0);
      final items = [
        makeReservation(
          id: '1',
          labId: 'lab-1',
          labName: 'Lab RPL',
          start: DateTime(2026, 11, 28, 8, 0),
          end: DateTime(2026, 11, 28, 10, 0),
          status: 'approved',
        ),
        makeReservation(
          id: '2',
          labId: 'lab-2',
          labName: 'Lab Jaringan',
          start: DateTime(2026, 11, 10, 8, 0),
          end: DateTime(2026, 11, 10, 10, 0),
          status: 'rejected',
        ),
        makeReservation(
          id: '3',
          labId: 'lab-1',
          labName: 'Lab RPL',
          start: DateTime(2026, 11, 28, 11, 0),
          end: DateTime(2026, 11, 28, 13, 0),
          type: 'maintenance_block',
          status: 'approved',
        ),
      ];

      final todayCompleted = ReportCalculator.filterReservations(
        reservations: items,
        period: ReportPeriod.today,
        statusFilter: 'completed',
        now: now,
      );
      expect(todayCompleted.map((e) => e.reservationId), ['1']);

      final allNonMaintenance = ReportCalculator.filterReservations(
        reservations: items,
        period: ReportPeriod.all,
        now: now,
      );
      expect(allNonMaintenance.length, 2);
    });

    test('summarize calculates usage hours, approval rate, and sorts labs', () {
      final now = DateTime(2026, 11, 28, 15, 0);
      final items = [
        makeReservation(
          id: '1',
          labId: 'lab-1',
          labName: 'Lab RPL',
          start: DateTime(2026, 11, 28, 8, 0),
          end: DateTime(2026, 11, 28, 10, 0),
          status: 'approved',
        ),
        makeReservation(
          id: '2',
          labId: 'lab-2',
          labName: 'Lab Jaringan',
          start: DateTime(2026, 11, 28, 9, 0),
          end: DateTime(2026, 11, 28, 12, 0),
          type: 'walk_in',
          status: 'approved',
        ),
        makeReservation(
          id: '3',
          labId: 'lab-1',
          labName: 'Lab RPL',
          start: DateTime(2026, 11, 28, 13, 0),
          end: DateTime(2026, 11, 28, 14, 0),
          status: 'rejected',
        ),
      ];

      final summary = ReportCalculator.summarize(
        reservations: items,
        laboratories: labs,
        now: now,
      );

      expect(summary.totalBookings, 3);
      expect(summary.approvedOrCompletedCount, 2);
      expect(summary.completedCount, 2);
      expect(summary.rejectedCount, 1);
      expect(summary.walkInCount, 1);
      expect(summary.totalUsageMinutes, 300);
      expect(summary.totalUsageHours, 5.0);
      expect(summary.approvalRatePercent, 67);
      expect(summary.topLab?.labId, 'lab-2');
      expect(summary.topLab?.totalHours, 3.0);
    });
  });
}

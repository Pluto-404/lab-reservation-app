import 'package:flutter_test/flutter_test.dart';
import 'package:labbook/models/reservation_model.dart';
import 'package:labbook/utils/schedule_block_helper.dart';

void main() {
  ReservationModel makeBlock({
    required String id,
    String labId = 'lab-1',
    String labName = 'Lab RPL',
    String title = 'Praktikum Web',
    String purpose = 'Kelas Reguler',
    required DateTime start,
    required DateTime end,
    String type = 'maintenance_block',
  }) {
    return ReservationModel(
      reservationId: id,
      labId: labId,
      labName: labName,
      userId: 'admin-1',
      studentName: 'Laboran / Admin',
      studentNim: '-',
      studentClass: '-',
      title: title,
      purpose: purpose,
      startTime: start,
      endTime: end,
      type: type,
      status: 'approved',
      createdAt: start,
    );
  }

  group('ScheduleBlockHelper', () {
    final now = DateTime(2026, 11, 28, 12, 0);

    test('filterBlocks filters by timeFilter, labId, and search query', () {
      final items = [
        makeBlock(
          id: 'past-1',
          start: DateTime(2026, 11, 21, 8, 0),
          end: DateTime(2026, 11, 21, 10, 0),
        ),
        makeBlock(
          id: 'up-1',
          labId: 'lab-1',
          title: 'Praktikum Web',
          start: DateTime(2026, 11, 28, 13, 0),
          end: DateTime(2026, 11, 28, 15, 0),
        ),
        makeBlock(
          id: 'up-2',
          labId: 'lab-2',
          labName: 'Lab Jaringan',
          title: 'Maintenance Router',
          start: DateTime(2026, 12, 5, 8, 0),
          end: DateTime(2026, 12, 5, 10, 0),
        ),
        makeBlock(
          id: 'student-1',
          type: 'student_booking',
          start: DateTime(2026, 11, 28, 16, 0),
          end: DateTime(2026, 11, 28, 17, 0),
        ),
      ];

      final upcoming = ScheduleBlockHelper.filterBlocks(
        reservations: items,
        timeFilter: BlockTimeFilter.upcoming,
        now: now,
      );
      expect(upcoming.map((e) => e.reservationId), ['up-1', 'up-2']);

      final past = ScheduleBlockHelper.filterBlocks(
        reservations: items,
        timeFilter: BlockTimeFilter.past,
        now: now,
      );
      expect(past.map((e) => e.reservationId), ['past-1']);

      final byLabAndQuery = ScheduleBlockHelper.filterBlocks(
        reservations: items,
        timeFilter: BlockTimeFilter.all,
        labId: 'lab-2',
        query: 'router',
        now: now,
      );
      expect(byLabAndQuery.map((e) => e.reservationId), ['up-2']);
    });

    test('groupBlocks groups weekly recurring blocks and separates different times/titles', () {
      final blocks = [
        makeBlock(
          id: 'w1',
          title: 'Praktikum Web',
          start: DateTime(2026, 11, 28, 8, 0),
          end: DateTime(2026, 11, 28, 10, 0),
        ),
        makeBlock(
          id: 'w2',
          title: 'Praktikum Web',
          start: DateTime(2026, 12, 5, 8, 0),
          end: DateTime(2026, 12, 5, 10, 0),
        ),
        makeBlock(
          id: 'single',
          title: 'Maintenance AC',
          start: DateTime(2026, 12, 1, 13, 0),
          end: DateTime(2026, 12, 1, 15, 0),
        ),
      ];

      final groups = ScheduleBlockHelper.groupBlocks(blocks);
      expect(groups.length, 2);

      final recurring = groups.firstWhere((g) => g.isRecurring);
      expect(recurring.count, 2);
      expect(recurring.items.map((e) => e.reservationId), ['w1', 'w2']);

      final single = groups.firstWhere((g) => !g.isRecurring);
      expect(single.count, 1);
      expect(single.first.reservationId, 'single');
    });
  });
}

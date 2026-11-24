import 'package:flutter_test/flutter_test.dart';
import 'package:labbook/models/laboratory_model.dart';
import 'package:labbook/models/reservation_model.dart';
import 'package:labbook/utils/booking_validator.dart';

void main() {
  final lab = LaboratoryModel(
    labId: 'lab-1',
    name: 'Lab RPL',
    building: 'Gedung A',
    capacity: 30,
    facilities: const ['PC'],
    operationalHours: '08:00 - 16:00',
  );

  ReservationModel reservation({
    String id = 'r1',
    String status = 'approved',
    String type = 'student_booking',
    String userId = 'other',
    required DateTime start,
    required DateTime end,
  }) => ReservationModel(
    reservationId: id,
    labId: 'lab-1',
    labName: 'Lab RPL',
    userId: userId,
    studentName: 'Tester',
    studentNim: 'M001',
    studentClass: 'A',
    title: 'Praktikum',
    purpose: 'Praktikum rutin',
    startTime: start,
    endTime: end,
    type: type,
    status: status,
    createdAt: DateTime(2026, 11, 1),
  );

  final now = DateTime(2026, 11, 18, 9);
  final day = DateTime(2026, 11, 20);
  DateTime at(int h, [int m = 0]) =>
      DateTime(day.year, day.month, day.day, h, m);

  group('BookingValidator.isBlocking', () {
    test('mengunci slot jika status approved, status maintenance_block, atau type maintenance_block', () {
      expect(
        BookingValidator.isBlocking(
          reservation(status: 'approved', start: at(8), end: at(10)),
        ),
        isTrue,
      );
      expect(
        BookingValidator.isBlocking(
          reservation(status: 'maintenance_block', start: at(8), end: at(10)),
        ),
        isTrue,
      );
      expect(
        BookingValidator.isBlocking(
          reservation(
            status: 'other',
            type: 'maintenance_block',
            start: at(8),
            end: at(10),
          ),
        ),
        isTrue,
      );
      expect(
        BookingValidator.isBlocking(
          reservation(status: 'pending', start: at(8), end: at(10)),
        ),
        isFalse,
      );
      expect(
        BookingValidator.isBlocking(
          reservation(status: 'rejected', start: at(8), end: at(10)),
        ),
        isFalse,
      );
      expect(
        BookingValidator.isBlocking(
          reservation(status: 'cancelled', start: at(8), end: at(10)),
        ),
        isFalse,
      );
    });
  });

  group('OperationalHours.parse', () {
    test('membaca "08:00 - 16:00"', () {
      final h = OperationalHours.parse('08:00 - 16:00');
      expect(h.isDefined, isTrue);
      expect(h.startMinute, 480);
      expect(h.endMinute, 960);
    });

    test('teks kosong memakai fallback', () {
      expect(OperationalHours.parse('').isDefined, isFalse);
    });
  });

  group('validateSchedule', () {
    test('jadwal kosong -> valid', () {
      expect(
        BookingValidator.validateSchedule(
          lab: lab,
          start: at(9),
          end: at(11),
          now: now,
        ),
        isNull,
      );
    });

    test('waktu selesai sebelum mulai -> error', () {
      expect(
        BookingValidator.validateSchedule(
          lab: lab,
          start: at(11),
          end: at(9),
          now: now,
        ),
        contains('Waktu selesai'),
      );
    });

    test('waktu lampau -> error', () {
      expect(
        BookingValidator.validateSchedule(
          lab: lab,
          start: DateTime(2026, 11, 17, 9),
          end: DateTime(2026, 11, 17, 10),
          now: now,
        ),
        contains('sudah lewat'),
      );
    });

    test('di luar jam operasional -> error', () {
      expect(
        BookingValidator.validateSchedule(
          lab: lab,
          start: at(15),
          end: at(17),
          now: now,
        ),
        contains('jam operasional'),
      );
    });

    test('bentrok dengan jadwal approved -> error', () {
      final msg = BookingValidator.validateSchedule(
        lab: lab,
        start: at(10),
        end: at(12),
        labSchedule: [reservation(start: at(9), end: at(11))],
        now: now,
      );
      expect(msg, contains('sudah digunakan'));
    });

    test('menempel tanpa beririsan (11:00 setelah 09:00-11:00) -> valid', () {
      final msg = BookingValidator.validateSchedule(
        lab: lab,
        start: at(11),
        end: at(12),
        labSchedule: [reservation(start: at(9), end: at(11))],
        now: now,
      );
      expect(msg, isNull);
    });

    test('bentrok dengan blokir maintenance -> error', () {
      final msg = BookingValidator.validateSchedule(
        lab: lab,
        start: at(9),
        end: at(10),
        labSchedule: [
          reservation(
            status: 'approved',
            type: 'maintenance_block',
            start: at(8),
            end: at(12),
          ),
        ],
        now: now,
      );
      expect(msg, contains('diblokir'));
    });

    test('pengajuan pending orang lain tidak memblokir', () {
      final msg = BookingValidator.validateSchedule(
        lab: lab,
        start: at(9),
        end: at(10),
        labSchedule: [
          reservation(status: 'pending', start: at(9), end: at(10)),
        ],
        now: now,
      );
      expect(msg, isNull);
    });

    test('pengajuan sendiri yang beririsan -> error', () {
      final msg = BookingValidator.validateSchedule(
        lab: lab,
        start: at(9),
        end: at(10),
        myReservations: [
          reservation(
            status: 'pending',
            userId: 'me',
            start: at(9),
            end: at(11),
          ),
        ],
        now: now,
      );
      expect(msg, contains('sudah punya pengajuan'));
    });
  });

  group('validateParticipants', () {
    test('kosong, nol, dan melebihi kapasitas ditolak', () {
      expect(
        BookingValidator.validateParticipants(raw: '', lab: lab),
        isNotNull,
      );
      expect(
        BookingValidator.validateParticipants(raw: '0', lab: lab),
        isNotNull,
      );
      expect(
        BookingValidator.validateParticipants(raw: '31', lab: lab),
        contains('kapasitas'),
      );
    });

    test('dalam kapasitas diterima', () {
      expect(
        BookingValidator.validateParticipants(raw: '30', lab: lab),
        isNull,
      );
    });
  });
}

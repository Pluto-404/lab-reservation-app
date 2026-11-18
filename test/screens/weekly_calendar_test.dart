import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:labbook/app_theme.dart';
import 'package:labbook/models/reservation_model.dart';
import 'package:labbook/screens/student/schedule/weekly_calendar.dart';
import 'package:labbook/utils/booking_validator.dart';

void main() {
  // Rabu, 18 Nov 2026 -> minggu mulai Senin 16 Nov 2026.
  final weekStart = DateTime(2026, 11, 16);
  final now = DateTime(2026, 11, 18, 9);

  ReservationModel booking(String title, DateTime start, DateTime end) =>
      ReservationModel(
        reservationId: title,
        labId: 'lab-1',
        labName: 'Lab RPL',
        userId: 'u1',
        studentName: 'Tester',
        studentNim: 'M001',
        studentClass: 'A',
        title: title,
        purpose: 'Latihan',
        startTime: start,
        endTime: end,
        status: 'approved',
        createdAt: DateTime(2026, 11, 1),
      );

  Widget host(Widget child) => MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: SizedBox(width: 420, height: 640, child: child)),
  );

  testWidgets('menampilkan 7 hari, blok jadwal, dan merespons ketukan', (
    tester,
  ) async {
    ReservationModel? tapped;
    DateTime? slot;
    await tester.pumpWidget(
      host(
        WeeklyCalendar(
          weekStart: weekStart,
          hours: OperationalHours.parse('08:00 - 16:00'),
          now: now,
          reservations: [
            booking(
              'Praktikum',
              DateTime(2026, 11, 19, 10),
              DateTime(2026, 11, 19, 12),
            ),
          ],
          onSlotTap: (s) => slot = s,
          onReservationTap: (r) => tapped = r,
        ),
      ),
    );

    for (final d in ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min']) {
      expect(find.text(d), findsOneWidget);
    }
    expect(find.text('Praktikum'), findsOneWidget);

    await tester.tap(find.text('Praktikum'));
    expect(tapped?.title, 'Praktikum');
    expect(slot, isNull);
  });

  testWidgets('waktu lampau memicu onBlockedTap, bukan onSlotTap', (
    tester,
  ) async {
    String? blocked;
    DateTime? slot;
    await tester.pumpWidget(
      host(
        WeeklyCalendar(
          weekStart: weekStart,
          hours: OperationalHours.parse('08:00 - 16:00'),
          now: now,
          reservations: const [],
          onSlotTap: (s) => slot = s,
          onReservationTap: (_) {},
          onBlockedTap: (m) => blocked = m,
        ),
      ),
    );

    // Kolom Senin (hari sudah lewat), area grid jam 09:00.
    await tester.tapAt(
      tester.getTopLeft(find.byType(WeeklyCalendar)) + const Offset(60, 120),
    );
    expect(blocked, isNotNull);
    expect(slot, isNull);
  });
}

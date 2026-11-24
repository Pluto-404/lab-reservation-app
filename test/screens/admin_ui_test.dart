import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:labbook/app_theme.dart';
import 'package:labbook/models/reservation_model.dart';
import 'package:labbook/screens/admin/booking_approval_page.dart';
import 'package:labbook/widgets/info_state.dart';
import 'package:labbook/widgets/reservation_status_chip.dart';
import 'package:labbook/widgets/summary_stat_card.dart';

void main() {
  group('Admin Shared UI Widgets Tests', () {
    testWidgets('RejectReservationDialog validates empty text and returns reason',
        (tester) async {
      String? resultReason;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    resultReason = await showDialog<String>(
                      context: context,
                      builder: (dialogContext) => const RejectReservationDialog(
                        studentName: 'Ahmad Mahasiswa',
                      ),
                    );
                  },
                  child: const Text('Buka Dialog Penolakan'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Buka Dialog Penolakan'));
      await tester.pumpAndSettle();

      expect(find.text('Tolak Peminjaman'), findsOneWidget);
      expect(find.textContaining('Ahmad Mahasiswa'), findsOneWidget);

      // Attempt submit without reason
      await tester.tap(find.widgetWithText(FilledButton, 'Tolak'));
      await tester.pump();

      // Check inline validation error
      expect(find.text('Alasan penolakan wajib diisi.'), findsOneWidget);
      expect(resultReason, isNull);

      // Input reason
      await tester.enterText(find.byType(TextField), 'Jadwal lab sedang renovasi.');
      await tester.pump();
      expect(find.text('Alasan penolakan wajib diisi.'), findsNothing);

      // Submit valid reason
      await tester.tap(find.widgetWithText(FilledButton, 'Tolak'));
      await tester.pumpAndSettle();

      expect(find.text('Tolak Peminjaman'), findsNothing);
      expect(resultReason, 'Jadwal lab sedang renovasi.');
    });

    testWidgets('RejectReservationDialog cancel returns null',
        (tester) async {
      String? resultReason = 'not-null';

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    resultReason = await showDialog<String>(
                      context: context,
                      builder: (dialogContext) => const RejectReservationDialog(
                        studentName: 'Ahmad Mahasiswa',
                      ),
                    );
                  },
                  child: const Text('Buka Dialog Penolakan'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Buka Dialog Penolakan'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Batal'));
      await tester.pumpAndSettle();

      expect(find.text('Tolak Peminjaman'), findsNothing);
      expect(resultReason, isNull);
    });

    testWidgets(
        'BookingApprovalCard renders action buttons when pending and not processing',
        (tester) async {
      final sampleBooking = ReservationModel(
        reservationId: 'RES-001',
        labId: 'LAB-1',
        labName: 'Lab Software Engineering',
        userId: 'USER-1',
        studentName: 'Siti Rahma',
        studentNim: 'M0520001',
        studentClass: 'Informatika A',
        title: 'Praktikum Mandiri',
        purpose: 'Mengerjakan tugas akhir',
        startTime: DateTime(2026, 11, 25, 9, 0),
        endTime: DateTime(2026, 11, 25, 11, 0),
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: BookingApprovalCard(
              booking: sampleBooking,
              formatDate: (_) => '25/11/2026',
              formatTime: (_) => '09.00',
              onApprove: () {},
              onReject: () {},
              isProcessing: false,
            ),
          ),
        ),
      );

      expect(find.text('RES-001'), findsOneWidget);
      expect(find.text('Siti Rahma'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Tolak'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Setujui'), findsOneWidget);
      expect(find.text('Memproses pembaruan...'), findsNothing);
    });

    testWidgets(
        'BookingApprovalCard hides action buttons and displays spinner when isProcessing is true',
        (tester) async {
      final sampleBooking = ReservationModel(
        reservationId: 'RES-002',
        labId: 'LAB-1',
        labName: 'Lab Software Engineering',
        userId: 'USER-2',
        studentName: 'Budi Santoso',
        studentNim: 'M0520002',
        studentClass: 'Informatika B',
        title: 'Praktikum Mandiri',
        purpose: 'Riset tugas akhir',
        startTime: DateTime(2026, 11, 25, 13, 0),
        endTime: DateTime(2026, 11, 25, 15, 0),
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: BookingApprovalCard(
              booking: sampleBooking,
              formatDate: (_) => '25/11/2026',
              formatTime: (_) => '13.00',
              onApprove: () {},
              onReject: () {},
              isProcessing: true,
            ),
          ),
        ),
      );

      expect(find.text('RES-002'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Tolak'), findsNothing);
      expect(find.widgetWithText(ElevatedButton, 'Setujui'), findsNothing);
      expect(find.text('Memproses pembaruan...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
    testWidgets('ReservationStatusChip renders expected labels',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Column(
              children: const [
                ReservationStatusChip(status: 'pending'),
                ReservationStatusChip(status: 'approved'),
                ReservationStatusChip(status: 'rejected'),
                ReservationStatusChip(status: 'completed'),
                ReservationStatusChip(status: 'cancelled'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Menunggu'), findsOneWidget);
      expect(find.text('Disetujui'), findsOneWidget);
      expect(find.text('Ditolak'), findsOneWidget);
      expect(find.text('Selesai'), findsOneWidget);
      expect(find.text('Dibatalkan'), findsOneWidget);
    });

    testWidgets('SummaryStatCard renders title, value and responds to tap',
        (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SummaryStatCard(
              title: 'Total Lab',
              value: '12',
              icon: Icons.science_outlined,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Total Lab'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.byIcon(Icons.science_outlined), findsOneWidget);

      await tester.tap(find.byType(SummaryStatCard));
      expect(tapped, isTrue);
    });

    testWidgets('InfoState renders icon, message and subtext',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: InfoState(
              icon: Icons.inbox_outlined,
              text: 'Tidak ada pengajuan',
              subtext: 'Silakan tunggu peminjaman masuk.',
            ),
          ),
        ),
      );

      expect(find.text('Tidak ada pengajuan'), findsOneWidget);
      expect(find.text('Silakan tunggu peminjaman masuk.'), findsOneWidget);
      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:labbook/app_theme.dart';
import 'package:labbook/widgets/info_state.dart';
import 'package:labbook/widgets/reservation_status_chip.dart';
import 'package:labbook/widgets/summary_stat_card.dart';

void main() {
  group('Admin Shared UI Widgets Tests', () {
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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:labbook/routes/app_router.dart';
import 'package:labbook/screens/splash_screen.dart';

void main() {
  testWidgets('SplashScreen widget build test', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: AppRouter.onGenerateRoute,
        home: const SplashScreen(),
      ),
    );

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('Lewati'), findsOneWidget);
  });
}

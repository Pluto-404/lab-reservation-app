import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:labbook/main.dart';
import 'package:labbook/models/laboratory_model.dart';
import 'package:labbook/models/user_model.dart';
import 'package:labbook/routes/app_router.dart';
import 'package:labbook/routes/app_routes.dart';
import 'package:labbook/screens/auth_pages.dart';
import 'package:labbook/screens/splash_screen.dart';
import 'package:labbook/screens/student/laboratory_detail_page.dart';
import 'package:labbook/screens/student/student_home.dart';

void main() {
  final dummyUser = UserModel(
    uid: 'user-123',
    email: 'test@student.uns.ac.id',
    name: 'Mahasiswa Test',
    nim: 'M0520001',
    className: 'PTIK A',
    cohort: '2023',
    role: 'student',
    createdAt: DateTime(2026, 1, 1),
  );

  final dummyLab = LaboratoryModel(
    labId: 'lab-1',
    name: 'Lab Rekayasa Perangkat Lunak',
    building: 'Gedung A Lantai 2',
    capacity: 35,
    facilities: ['35 PC', 'AC', 'Proyektor'],
    operationalHours: '08:00 - 16:00',
    isActive: true,
  );

  group('AppRouter Route Generation Tests', () {
    testWidgets('Generates SplashScreen for AppRoutes.splash', (tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            final route = AppRouter.onGenerateRoute(
              const RouteSettings(name: AppRoutes.splash),
            );
            expect(route, isA<MaterialPageRoute>());
            final widget = (route as MaterialPageRoute).builder(context);
            expect(widget, isA<SplashScreen>());
            return const SizedBox.shrink();
          },
        ),
      );
    });

    testWidgets('Generates AuthGate for AppRoutes.authGate', (tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            final route = AppRouter.onGenerateRoute(
              const RouteSettings(name: AppRoutes.authGate),
            );
            expect(route, isA<PageRouteBuilder>());
            final pageRoute = route as PageRouteBuilder;
            final widget = pageRoute.pageBuilder(
              context,
              const AlwaysStoppedAnimation(1.0),
              const AlwaysStoppedAnimation(1.0),
            );
            expect(widget, isA<AuthGate>());
            return const SizedBox.shrink();
          },
        ),
      );
    });

    testWidgets('Generates LoginPage for AppRoutes.login', (tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            final route = AppRouter.onGenerateRoute(
              const RouteSettings(name: AppRoutes.login),
            );
            expect(route, isA<MaterialPageRoute>());
            final widget = (route as MaterialPageRoute).builder(context);
            expect(widget, isA<LoginPage>());
            return const SizedBox.shrink();
          },
        ),
      );
    });

    testWidgets('Generates RegisterPage for AppRoutes.register', (tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            final route = AppRouter.onGenerateRoute(
              const RouteSettings(name: AppRoutes.register),
            );
            expect(route, isA<MaterialPageRoute>());
            final widget = (route as MaterialPageRoute).builder(context);
            expect(widget, isA<RegisterPage>());
            return const SizedBox.shrink();
          },
        ),
      );
    });

    testWidgets('Generates StudentHome with valid UserModel argument', (tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            final route = AppRouter.onGenerateRoute(
              RouteSettings(name: AppRoutes.studentHome, arguments: dummyUser),
            );
            expect(route, isA<MaterialPageRoute>());
            final widget = (route as MaterialPageRoute).builder(context);
            expect(widget, isA<StudentHome>());
            return const SizedBox.shrink();
          },
        ),
      );
    });

    testWidgets('Returns error route when StudentHome lacks UserModel', (tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            final route = AppRouter.onGenerateRoute(
              const RouteSettings(name: AppRoutes.studentHome),
            );
            expect(route, isA<MaterialPageRoute>());
            final widget = (route as MaterialPageRoute).builder(context);
            expect(widget, isNot(isA<StudentHome>()));
            expect(widget, isA<Scaffold>());
            return const SizedBox.shrink();
          },
        ),
      );
    });

    testWidgets('Generates LaboratoryDetail with valid LaboratoryModel argument', (tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            final route = AppRouter.onGenerateRoute(
              RouteSettings(name: AppRoutes.laboratoryDetail, arguments: dummyLab),
            );
            expect(route, isA<MaterialPageRoute>());
            final widget = (route as MaterialPageRoute).builder(context);
            expect(widget, isA<LaboratoryDetail>());
            return const SizedBox.shrink();
          },
        ),
      );
    });

    testWidgets('Returns error route when LaboratoryDetail lacks LaboratoryModel', (tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            final route = AppRouter.onGenerateRoute(
              const RouteSettings(name: AppRoutes.laboratoryDetail),
            );
            expect(route, isA<MaterialPageRoute>());
            final widget = (route as MaterialPageRoute).builder(context);
            expect(widget, isNot(isA<LaboratoryDetail>()));
            expect(widget, isA<Scaffold>());
            return const SizedBox.shrink();
          },
        ),
      );
    });

    testWidgets('Generates AdminHome placeholder for AppRoutes.adminHome', (tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            final route = AppRouter.onGenerateRoute(
              const RouteSettings(name: AppRoutes.adminHome),
            );
            expect(route, isA<MaterialPageRoute>());
            final widget = (route as MaterialPageRoute).builder(context);
            expect(widget, isA<Scaffold>());
            return const SizedBox.shrink();
          },
        ),
      );
    });

    testWidgets('Returns error route for unknown route name', (tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            final route = AppRouter.onGenerateRoute(
              const RouteSettings(name: '/some-random-unknown-route'),
            );
            expect(route, isA<MaterialPageRoute>());
            final widget = (route as MaterialPageRoute).builder(context);
            expect(widget, isA<Scaffold>());
            return const SizedBox.shrink();
          },
        ),
      );
    });

    testWidgets('Returns error route on onUnknownRoute callback', (tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            final route = AppRouter.onUnknownRoute(
              const RouteSettings(name: '/completely-lost-route'),
            );
            expect(route, isA<MaterialPageRoute>());
            final widget = (route as MaterialPageRoute).builder(context);
            expect(widget, isA<Scaffold>());
            return const SizedBox.shrink();
          },
        ),
      );
    });
  });
}

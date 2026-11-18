import 'package:flutter/material.dart';

import '../main.dart';
import '../models/laboratory_model.dart';
import '../models/user_model.dart';
import '../screens/auth_pages.dart';
import '../screens/splash_screen.dart';
import '../screens/student/booking/booking_form_page.dart';
import '../screens/student/laboratory_detail_page.dart';
import '../screens/student/schedule/student_schedule_page.dart';
import '../screens/student/student_home.dart';
import 'app_routes.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );

      case AppRoutes.authGate:
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) =>
              const AuthGate(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 350),
        );

      case AppRoutes.login:
        return MaterialPageRoute(
          builder: (_) => const LoginPage(),
          settings: settings,
        );

      case AppRoutes.register:
        return MaterialPageRoute(
          builder: (_) => const RegisterPage(),
          settings: settings,
        );

      case AppRoutes.studentHome:
        final profile = settings.arguments as UserModel?;
        if (profile == null) {
          return _errorRoute(
            'Profil pengguna (UserModel) diperlukan untuk membuka halaman mahasiswa.',
            settings,
          );
        }
        return MaterialPageRoute(
          builder: (_) => StudentHome(profile: profile),
          settings: settings,
        );

      case AppRoutes.laboratoryDetail:
        final lab = settings.arguments as LaboratoryModel?;
        if (lab == null) {
          return _errorRoute(
            'Data laboratorium (LaboratoryModel) diperlukan untuk membuka halaman detail.',
            settings,
          );
        }
        return MaterialPageRoute(
          builder: (_) => LaboratoryDetail(lab: lab),
          settings: settings,
        );

      case AppRoutes.studentSchedule:
        final lab = settings.arguments is LaboratoryModel
            ? settings.arguments as LaboratoryModel
            : null;
        return MaterialPageRoute(
          builder: (_) => StudentSchedulePage(initialLab: lab, showAppBar: true),
          settings: settings,
        );

      case AppRoutes.studentBooking:
        final args = settings.arguments is BookingFormArgs
            ? settings.arguments as BookingFormArgs
            : null;
        if (args == null) {
          return _errorRoute(
            'Data laboratorium dan profil (BookingFormArgs) diperlukan untuk membuka form booking.',
            settings,
          );
        }
        return MaterialPageRoute(
          builder: (_) => BookingFormPage(args: args),
          settings: settings,
        );

      case AppRoutes.adminHome:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('LabBook Admin')),
            body: const Center(
              child: Text('Dashboard admin dalam pengembangan.'),
            ),
          ),
          settings: settings,
        );

      default:
        return _errorRoute(
          'Rute "${settings.name}" tidak ditemukan.',
          settings,
        );
    }
  }

  static Route<dynamic> onUnknownRoute(RouteSettings settings) => _errorRoute(
        'Halaman "${settings.name}" tidak tersedia.',
        settings,
      );

  static Route<dynamic> _errorRoute(String message, RouteSettings settings) =>
      MaterialPageRoute(
        settings: settings,
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Halaman Tidak Ditemukan')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Colors.redAccent),
              ),
            ),
          ),
        ),
      );
}

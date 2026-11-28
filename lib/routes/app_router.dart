
import 'package:flutter/material.dart';

import '../main.dart';
import '../models/laboratory_model.dart';
import '../models/user_model.dart';
import '../screens/auth_pages.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/admin/admin_report_page.dart';
import '../screens/admin/booking_approval_page.dart';
import '../screens/admin/laboratory_management_page.dart';
import '../screens/admin/schedule_block_page.dart';
import '../screens/admin/walk_in_page.dart';
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
      case AppRoutes.authGate:
      case '/auth-gate':
        return MaterialPageRoute(
          builder: (_) => const AuthGate(),
          settings: settings,
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
          builder: (_) => StudentSchedulePage(
            initialLab: lab,
            showAppBar: true,
          ),
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

        return MaterialPageRoute<DateTime>(
          builder: (_) => BookingFormPage(args: args),
          settings: settings,
        );

      // Admin Routes
      case AppRoutes.adminHome:
        return MaterialPageRoute(
          builder: (_) => const AdminDashboard(),
          settings: settings,
        );

      case AppRoutes.adminApprovals:
        return MaterialPageRoute(
          builder: (_) => const BookingApprovalPage(),
          settings: settings,
        );

      case AppRoutes.adminManageLabs:
        return MaterialPageRoute(
          builder: (_) => const LaboratoryManagementPage(),
          settings: settings,
        );

      case AppRoutes.adminWalkIn:
        return MaterialPageRoute(
          builder: (_) => const WalkInPage(),
          settings: settings,
        );

      case AppRoutes.adminScheduleBlock:
        return MaterialPageRoute(
          builder: (_) => const ScheduleBlockPage(),
          settings: settings,
        );

      case AppRoutes.adminReports:
        return MaterialPageRoute(
          builder: (_) => const AdminReportPage(),
          settings: settings,
        );

      default:
        return _errorRoute(
          'Rute "${settings.name}" tidak ditemukan.',
          settings,
        );
    }
  }

  static Route<dynamic> onUnknownRoute(RouteSettings settings) =>
      _errorRoute(
        'Halaman "${settings.name}" tidak tersedia.',
        settings,
      );

  static Route<dynamic> _errorRoute(
    String message,
    RouteSettings settings,
  ) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => Scaffold(
        appBar: AppBar(
          title: const Text('Halaman Tidak Ditemukan'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.redAccent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

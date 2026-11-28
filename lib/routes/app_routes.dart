abstract class AppRoutes {
  // Core & Auth
  static const String authGate = '/';
  static const String login = '/login';
  static const String register = '/register';

  // Mahasiswa (Student)
  static const String studentHome = '/student/home';
  static const String laboratoryDetail = '/student/lab-detail';

  // Future Student Routes
  static const String studentBooking = '/student/booking';
  static const String studentReservations = '/student/reservations';
  static const String studentSchedule = '/student/schedule';

  // Admin
  static const String adminHome = '/admin/home';

  // Future Admin Routes
  static const String adminApprovals = '/admin/approvals';
  static const String adminManageLabs = '/admin/manage-labs';
  static const String adminWalkIn = '/admin/walk-in';
  static const String adminScheduleBlock = '/admin/schedule-block';
  static const String adminReports = '/admin/reports';
}

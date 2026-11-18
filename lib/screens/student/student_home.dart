import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app_theme.dart';
import '../../models/user_model.dart';
import 'laboratory_catalog_page.dart';
import 'schedule/student_schedule_page.dart';
import 'student_dashboard.dart';
import 'student_profile_page.dart';

class StudentHome extends StatefulWidget {
  const StudentHome({super.key, required this.profile});
  final UserModel profile;

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  late int selected = widget.profile.nim.isEmpty ||
          widget.profile.className.isEmpty ||
          widget.profile.cohort.isEmpty
      ? _profileTab
      : 0;
  bool _scheduleOpened = false;

  static const int _scheduleTab = 2;
  static const int _profileTab = 3;
  late UserModel profile = widget.profile;

  @override
  void didUpdateWidget(covariant StudentHome oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile != widget.profile) {
      setState(() {
        profile = widget.profile;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/images/labbook-logo.svg',
                width: 26,
                height: 26,
              ),
              const SizedBox(width: 8),
              const Text(
                'LabBook',
                style: TextStyle(
                  color: AppTheme.deep,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton(
                tooltip: 'Profil',
                onPressed: () => setState(() => selected = _profileTab),
                icon: const Icon(Icons.account_circle_outlined),
              ),
            ),
          ],
        ),
        body: PageWidth(
          maxWidth: 680,
          child: IndexedStack(
            index: selected,
            children: [
              StudentDashboard(
                profile: profile,
                openCatalog: () => setState(() => selected = 1),
              ),
              const LaboratoryCatalog(),
              // Dibuat saat tab Kalender pertama kali dibuka (hemat query).
              if (_scheduleOpened || selected == _scheduleTab)
                StudentSchedulePage(
                  profile: profile,
                  onCompleteProfile: () =>
                      setState(() => selected = _profileTab),
                )
              else
                const SizedBox.shrink(),
              StudentProfile(
                profile: profile,
                onUpdated: (updated) => setState(() => profile = updated),
              ),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: selected,
          onDestinationSelected: (i) => setState(() {
            selected = i;
            if (i == _scheduleTab) _scheduleOpened = true;
          }),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: Icon(Icons.apartment_outlined),
              selectedIcon: Icon(Icons.apartment),
              label: 'Laboratorium',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'Kalender',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      );
}

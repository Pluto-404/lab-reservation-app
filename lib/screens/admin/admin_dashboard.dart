import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app_theme.dart';
import '../../models/laboratory_model.dart';
import '../../models/reservation_model.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/info_state.dart';
import '../../widgets/reservation_status_chip.dart';
import '../../widgets/summary_stat_card.dart';
import 'admin_report_page.dart';
import 'booking_approval_page.dart';
import 'laboratory_form_page.dart';
import 'laboratory_management_page.dart';
import 'schedule_block_page.dart';
import 'walk_in_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({
    super.key,
    this.initialTab = 0,
  });

  final int initialTab;

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  late int _selectedTab = widget.initialTab;
  final FirestoreService _firestoreService = FirestoreService();
  late final Stream<List<LaboratoryModel>> _laboratoriesStream;
  late final Stream<List<ReservationModel>> _reservationsStream;

  @override
  void initState() {
    super.initState();
    _laboratoriesStream = _firestoreService.getAllLaboratories();
    _reservationsStream = _firestoreService.getAllReservations();
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar dari Akun?'),
        content: const Text(
          'Apakah kamu yakin ingin keluar dari sesi administrasi LabBook?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.danger,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await AuthService().signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 850;

        final tabs = [
          _AdminOverviewView(
            laboratoriesStream: _laboratoriesStream,
            reservationsStream: _reservationsStream,
            onSelectTab: (index) => setState(() => _selectedTab = index),
            onOpenScheduleBlock: () {
              if (isWide) {
                setState(() => _selectedTab = 4);
              } else {
                Navigator.pushNamed(context, AppRoutes.adminScheduleBlock);
              }
            },
            onOpenReports: () {
              if (isWide) {
                setState(() => _selectedTab = 5);
              } else {
                Navigator.pushNamed(context, AppRoutes.adminReports);
              }
            },
          ),
          const LaboratoryManagementPage(showAppBar: false),
          const BookingApprovalPage(showAppBar: false),
          const WalkInPage(showAppBar: false),
          const ScheduleBlockPage(showAppBar: false),
          const AdminReportPage(showAppBar: false),
        ];

        return Scaffold(
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
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.soft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Admin',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Keluar',
                onPressed: _confirmSignOut,
                icon: const Icon(Icons.logout),
              ),
              const SizedBox(width: 12),
            ],
          ),
          body: isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AdminSidebar(
                      selectedIndex: _selectedTab,
                      onDestinationSelected: (i) =>
                          setState(() => _selectedTab = i),
                    ),
                    const VerticalDivider(width: 1, color: AppTheme.outline),
                    Expanded(
                      child: IndexedStack(
                        index: _selectedTab,
                        children: tabs,
                      ),
                    ),
                  ],
                )
              : IndexedStack(
                  index: _selectedTab,
                  children: tabs,
                ),
          bottomNavigationBar: isWide
              ? null
              : NavigationBar(
                  selectedIndex: _selectedTab.clamp(0, 3),
                  onDestinationSelected: (i) =>
                      setState(() => _selectedTab = i),
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
                      icon: Icon(Icons.fact_check_outlined),
                      selectedIcon: Icon(Icons.fact_check),
                      label: 'Persetujuan',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.meeting_room_outlined),
                      selectedIcon: Icon(Icons.meeting_room),
                      label: 'Walk-in',
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _AdminOverviewView extends StatelessWidget {
  const _AdminOverviewView({
    required this.laboratoriesStream,
    required this.reservationsStream,
    required this.onSelectTab,
    required this.onOpenScheduleBlock,
    required this.onOpenReports,
  });

  final Stream<List<LaboratoryModel>> laboratoriesStream;
  final Stream<List<ReservationModel>> reservationsStream;
  final ValueChanged<int> onSelectTab;
  final VoidCallback onOpenScheduleBlock;
  final VoidCallback onOpenReports;

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return PageWidth(
      maxWidth: 850,
      child: StreamBuilder<List<LaboratoryModel>>(
        stream: laboratoriesStream,
        builder: (context, labSnapshot) {
          if (labSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (labSnapshot.hasError) {
            return InfoState(
              icon: Icons.error_outline,
              text: 'Gagal memuat data laboratorium.',
              subtext: '${labSnapshot.error}',
            );
          }

          final laboratories = labSnapshot.data ?? [];

          return StreamBuilder<List<ReservationModel>>(
            stream: reservationsStream,
            builder: (context, reservationSnapshot) {
              if (reservationSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (reservationSnapshot.hasError) {
                return InfoState(
                  icon: Icons.error_outline,
                  text: 'Gagal memuat data reservasi.',
                  subtext: '${reservationSnapshot.error}',
                );
              }

              final reservations = reservationSnapshot.data ?? [];

              final normalReservations = reservations
                  .where((item) => item.type != 'maintenance_block')
                  .toList();

              final today = DateUtils.dateOnly(DateTime.now());

              final todayReservations = normalReservations.where((item) {
                return DateUtils.isSameDay(item.startTime, today);
              }).length;

              final pendingReservations = normalReservations
                  .where((item) => item.status == 'pending')
                  .length;

              final activeLaboratories =
                  laboratories.where((lab) => lab.isActive).length;

              final recentReservations =
                  normalReservations.take(5).toList();

              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Text(
                    'Halo, Administrator!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Kelola ketersediaan laboratorium dan pantau reservasi kampus.',
                    style: TextStyle(color: AppTheme.muted),
                  ),
                  const SizedBox(height: 24),

                  // Statistik Grid
                  LayoutBuilder(
                    builder: (context, box) {
                      final columns = box.maxWidth >= 700
                          ? 4
                          : box.maxWidth >= 450
                              ? 2
                              : 1;

                      return GridView.count(
                        crossAxisCount: columns,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: columns >= 4
                            ? 1.9
                            : columns == 2
                                ? 2.5
                                : 3.8,
                        children: [
                          SummaryStatCard(
                            title: 'Total Lab',
                            value: '${laboratories.length}',
                            icon: Icons.science_outlined,
                            iconColor: AppTheme.primary,
                            backgroundColor: AppTheme.soft,
                            onTap: () => onSelectTab(1),
                          ),
                          SummaryStatCard(
                            title: 'Reservasi Hari Ini',
                            value: '$todayReservations',
                            icon: Icons.calendar_today_outlined,
                            iconColor: AppTheme.deep,
                            backgroundColor: AppTheme.soft,
                            onTap: () => onSelectTab(2),
                          ),
                          SummaryStatCard(
                            title: 'Menunggu Review',
                            value: '$pendingReservations',
                            icon: Icons.pending_actions_outlined,
                            iconColor: AppTheme.warning,
                            backgroundColor: AppTheme.warningSoft,
                            onTap: () => onSelectTab(2),
                          ),
                          SummaryStatCard(
                            title: 'Lab Aktif',
                            value: '$activeLaboratories',
                            icon: Icons.check_circle_outline,
                            iconColor: AppTheme.success,
                            backgroundColor: AppTheme.successSoft,
                            onTap: () => onSelectTab(1),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  // Aksi Cepat
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Aksi Cepat',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.ink,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const LaboratoryFormPage(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Tambah Lab'),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(0, 42),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => onSelectTab(2),
                                icon: const Icon(
                                  Icons.pending_actions_outlined,
                                  size: 18,
                                ),
                                label: Text(
                                  'Review Pengajuan ($pendingReservations)',
                                ),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 42),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => onSelectTab(3),
                                icon: const Icon(
                                  Icons.meeting_room_outlined,
                                  size: 18,
                                ),
                                label: const Text('Catat Walk-in'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 42),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: onOpenScheduleBlock,
                                icon: const Icon(
                                  Icons.event_busy_outlined,
                                  size: 18,
                                ),
                                label: const Text('Blokir Jadwal'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 42),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: onOpenReports,
                                icon: const Icon(
                                  Icons.bar_chart_outlined,
                                  size: 18,
                                ),
                                label: const Text('Laporan Utilisasi'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 42),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Reservasi Terbaru
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Reservasi Terbaru',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.ink,
                        ),
                      ),
                      TextButton(
                        onPressed: () => onSelectTab(2),
                        child: const Text('Lihat Semua'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (recentReservations.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: InfoState(
                          icon: Icons.event_available_outlined,
                          text: 'Belum ada reservasi masuk.',
                          subtext: 'Pengajuan dari mahasiswa akan ditampilkan di sini.',
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    )
                  else
                    Card(
                      child: Column(
                        children: [
                          for (int i = 0;
                              i < recentReservations.length;
                              i++) ...[
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 6,
                              ),
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppTheme.soft,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.person_outline,
                                  color: AppTheme.deep,
                                  size: 22,
                                ),
                              ),
                              title: Text(
                                recentReservations[i].studentName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppTheme.ink,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Text(
                                  '${recentReservations[i].labName} • '
                                  '${_formatDate(recentReservations[i].startTime)} '
                                  '(${_formatTime(recentReservations[i].startTime)} - '
                                  '${_formatTime(recentReservations[i].endTime)})',
                                  style: const TextStyle(
                                    color: AppTheme.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              trailing: ReservationStatusChip(
                                status: recentReservations[i].status,
                                compact: true,
                              ),
                              onTap: () => onSelectTab(2),
                            ),
                            if (i < recentReservations.length - 1)
                              const Divider(
                                height: 1,
                                color: AppTheme.outline,
                              ),
                          ],
                        ],
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: Colors.white,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MENU ADMINISTRASI',
            style: TextStyle(
              color: AppTheme.muted,
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          _SidebarItem(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            title: 'Beranda',
            selected: selectedIndex == 0,
            onTap: () => onDestinationSelected(0),
          ),
          _SidebarItem(
            icon: Icons.apartment_outlined,
            selectedIcon: Icons.apartment,
            title: 'Kelola Laboratorium',
            selected: selectedIndex == 1,
            onTap: () => onDestinationSelected(1),
          ),
          _SidebarItem(
            icon: Icons.fact_check_outlined,
            selectedIcon: Icons.fact_check,
            title: 'Persetujuan Peminjaman',
            selected: selectedIndex == 2,
            onTap: () => onDestinationSelected(2),
          ),
          _SidebarItem(
            icon: Icons.meeting_room_outlined,
            selectedIcon: Icons.meeting_room,
            title: 'Peminjaman Langsung',
            selected: selectedIndex == 3,
            onTap: () => onDestinationSelected(3),
          ),
          _SidebarItem(
            icon: Icons.event_busy_outlined,
            selectedIcon: Icons.event_busy,
            title: 'Blokir Jadwal',
            selected: selectedIndex == 4,
            onTap: () => onDestinationSelected(4),
          ),
          _SidebarItem(
            icon: Icons.bar_chart_outlined,
            selectedIcon: Icons.bar_chart,
            title: 'Laporan & Utilisasi',
            selected: selectedIndex == 5,
            onTap: () => onDestinationSelected(5),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.selectedIcon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        selected: selected,
        selectedTileColor: AppTheme.soft,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        leading: Icon(
          selected ? selectedIcon : icon,
          color: selected ? AppTheme.primary : AppTheme.muted,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
            color: selected ? AppTheme.primary : AppTheme.ink,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

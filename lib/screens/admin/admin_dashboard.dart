
import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../models/laboratory_model.dart';
import '../../models/reservation_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import 'laboratory_management_page.dart';
import 'booking_approval_page.dart';
import 'walk_in_page.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  static final FirestoreService _firestoreService =
      FirestoreService();

  void _openPage(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => page,
      ),
    );
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(
              Icons.science_outlined,
              color: AppTheme.primary,
            ),
            const SizedBox(width: 10),
            const Text('LabBook Admin'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            onPressed: () async {
              await AuthService().signOut();
            },
            icon: const Icon(Icons.logout),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: StreamBuilder<List<LaboratoryModel>>(
        stream: _firestoreService.getAllLaboratories(),
        builder: (context, labSnapshot) {
          if (labSnapshot.hasError) {
            return Center(
              child: Text(
                'Gagal memuat data laboratorium: ${labSnapshot.error}',
              ),
            );
          }

          if (!labSnapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final laboratories = labSnapshot.data!;

          return StreamBuilder<List<ReservationModel>>(
            stream: _firestoreService.getAllReservations(),
            builder: (context, reservationSnapshot) {
              if (reservationSnapshot.hasError) {
                return Center(
                  child: Text(
                    'Gagal memuat data reservasi: '
                    '${reservationSnapshot.error}',
                  ),
                );
              }

              if (!reservationSnapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final reservations = reservationSnapshot.data!;

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

              final activeLaboratories = laboratories
                  .where((lab) => lab.isActive)
                  .length;

              final recentReservations =
                  normalReservations.take(5).toList();

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 850;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isWide) const _AdminSidebar(),

                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Dashboard',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.ink,
                                ),
                              ),

                              const SizedBox(height: 8),

                              const Text(
                                'Selamat datang di halaman administrasi LabBook.',
                                style: TextStyle(
                                  color: AppTheme.muted,
                                ),
                              ),

                              const SizedBox(height: 28),

                              // Statistik Dashboard
                              LayoutBuilder(
                                builder: (context, box) {
                                  final columns = box.maxWidth >= 700
                                      ? 4
                                      : box.maxWidth >= 450
                                          ? 2
                                          : 1;

                                  final stats = [
                                    _StatData(
                                      title: 'Total Laboratorium',
                                      value: '${laboratories.length}',
                                      icon: Icons.science_outlined,
                                      color: AppTheme.primary,
                                    ),
                                    _StatData(
                                      title: 'Reservasi Hari Ini',
                                      value: '$todayReservations',
                                      icon: Icons.calendar_today_outlined,
                                      color: Colors.orange,
                                    ),
                                    _StatData(
                                      title: 'Menunggu Persetujuan',
                                      value: '$pendingReservations',
                                      icon: Icons.pending_actions_outlined,
                                      color: Colors.deepOrange,
                                    ),
                                    _StatData(
                                      title: 'Laboratorium Aktif',
                                      value: '$activeLaboratories',
                                      icon: Icons.check_circle_outline,
                                      color: AppTheme.success,
                                    ),
                                  ];

                                  return GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: stats.length,
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: columns,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                      mainAxisExtent: 125,
                                    ),
                                    itemBuilder: (context, index) {
                                      return _StatCard(
                                        data: stats[index],
                                      );
                                    },
                                  );
                                },
                              ),

                              const SizedBox(height: 32),

                              // Reservasi Terbaru
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Reservasi Terbaru',
                                    style: TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.ink,
                                    ),
                                  ),

                                  TextButton(
                                    onPressed: () {
                                      _openPage(
                                        context,
                                        const BookingApprovalPage(),
                                      );
                                    },
                                    child: const Text('Lihat Semua'),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 14),

                              Card(
                                child: recentReservations.isEmpty
                                    ? const Padding(
                                        padding: EdgeInsets.all(28),
                                        child: Center(
                                          child: Text(
                                            'Belum ada reservasi.',
                                            style: TextStyle(
                                              color: AppTheme.muted,
                                            ),
                                          ),
                                        ),
                                      )
                                    : Column(
                                        children: [
                                          for (int i = 0;
                                              i < recentReservations.length;
                                              i++) ...[
                                            _BookingTile(
                                              name: recentReservations[i]
                                                  .studentName,
                                              laboratory: recentReservations[i]
                                                  .labName,
                                              date: _formatDate(
                                                recentReservations[i]
                                                    .startTime,
                                              ),
                                              status: _getStatus(
                                                recentReservations[i].status,
                                              ),
                                            ),
                                            if (i <
                                                recentReservations.length - 1)
                                              const Divider(
                                                height: 1,
                                                color: AppTheme.outline,
                                              ),
                                          ],
                                        ],
                                      ),
                              ),

                              const SizedBox(height: 28),

                              // Informasi Sistem
                              const Text(
                                'Informasi Sistem',
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.ink,
                                ),
                              ),

                              const SizedBox(height: 14),

                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(18),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.info_outline,
                                        color: AppTheme.primary,
                                        size: 30,
                                      ),

                                      const SizedBox(width: 14),

                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Sistem LabBook',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.ink,
                                              ),
                                            ),

                                            SizedBox(height: 5),

                                            Text(
                                              'Kelola informasi laboratorium dan '
                                              'pantau aktivitas reservasi kampus.',
                                              style: TextStyle(
                                                color: AppTheme.muted,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),

      // Navigasi bawah untuk layar HP
      bottomNavigationBar:
          MediaQuery.of(context).size.width < 850
              ? const _AdminBottomNavigation()
              : null,
    );
  }

  String _getStatus(String status) {
    switch (status) {
      case 'pending':
        return 'Menunggu';
      case 'approved':
        return 'Disetujui';
      case 'rejected':
        return 'Ditolak';
      case 'cancelled':
        return 'Dibatalkan';
      case 'completed':
        return 'Selesai';
      default:
        return status;
    }
  }
}

// =====================================================
// NAVIGASI BAWAH UNTUK HP
// =====================================================

class _AdminBottomNavigation extends StatelessWidget {
  const _AdminBottomNavigation();

  void _openPage(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => page,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            tooltip: 'Dashboard',
            onPressed: () {},
            icon: const Icon(
              Icons.dashboard_outlined,
              color: AppTheme.primary,
            ),
          ),

          IconButton(
            tooltip: 'Laboratorium',
            onPressed: () {
              _openPage(
                context,
                const LaboratoryManagementPage(),
              );
            },
            icon: const Icon(Icons.science_outlined),
          ),

          IconButton(
            tooltip: 'Persetujuan',
            onPressed: () {
              _openPage(
                context,
                const BookingApprovalPage(),
              );
            },
            icon: const Icon(Icons.pending_actions_outlined),
          ),

          IconButton(
            tooltip: 'Peminjaman Langsung',
            onPressed: () {
              _openPage(
                context,
                const WalkInPage(),
              );
            },
            icon: const Icon(Icons.meeting_room_outlined),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// SIDEBAR UNTUK DESKTOP
// =====================================================

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar();

  void _openPage(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => page,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      height: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MENU ADMIN',
            style: TextStyle(
              color: AppTheme.muted,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 18),

          const _SidebarItem(
            icon: Icons.dashboard_outlined,
            title: 'Dashboard',
            selected: true,
          ),

          _SidebarItem(
            icon: Icons.science_outlined,
            title: 'Kelola Laboratorium',
            onTap: () {
              _openPage(
                context,
                const LaboratoryManagementPage(),
              );
            },
          ),

          _SidebarItem(
            icon: Icons.pending_actions_outlined,
            title: 'Persetujuan Peminjaman',
            onTap: () {
              _openPage(
                context,
                const BookingApprovalPage(),
              );
            },
          ),

          _SidebarItem(
            icon: Icons.meeting_room_outlined,
            title: 'Peminjaman Langsung',
            onTap: () {
              _openPage(
                context,
                const WalkInPage(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// =====================================================
// ITEM SIDEBAR
// =====================================================

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback? onTap;

  const _SidebarItem({
    required this.icon,
    required this.title,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        selected: selected,
        selectedTileColor: AppTheme.soft,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        leading: Icon(
          icon,
          color: selected ? AppTheme.primary : AppTheme.muted,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight:
                selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? AppTheme.primary : AppTheme.ink,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

// =====================================================
// DATA STATISTIK
// =====================================================

class _StatData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}

// =====================================================
// KARTU STATISTIK
// =====================================================

class _StatCard extends StatelessWidget {
  final _StatData data;

  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(
              data.icon,
              color: data.color,
              size: 26,
            ),

            Text(
              data.value,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: AppTheme.ink,
              ),
            ),

            Text(
              data.title,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// ITEM RESERVASI
// =====================================================

class _BookingTile extends StatelessWidget {
  final String name;
  final String laboratory;
  final String date;
  final String status;

  const _BookingTile({
    required this.name,
    required this.laboratory,
    required this.date,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final Color statusColor;
    final Color statusBackground;

    switch (status) {
      case 'Disetujui':
      case 'Selesai':
        statusColor = AppTheme.success;
        statusBackground = AppTheme.successSoft;
        break;
      case 'Ditolak':
      case 'Dibatalkan':
        statusColor = AppTheme.danger;
        statusBackground = AppTheme.dangerSoft;
        break;
      default:
        statusColor = AppTheme.warning;
        statusBackground = AppTheme.warningSoft;
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 8,
      ),

      leading: CircleAvatar(
        backgroundColor: AppTheme.soft,
        child: const Icon(
          Icons.person_outline,
          color: AppTheme.primary,
        ),
      ),

      title: Text(
        name,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppTheme.ink,
        ),
      ),

      subtitle: Text('$laboratory\n$date'),

      isThreeLine: true,

      trailing: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: statusBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          status,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: statusColor,
          ),
        ),
      ),
    );
  }
}

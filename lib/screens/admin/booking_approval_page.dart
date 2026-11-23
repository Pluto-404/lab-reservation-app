
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../models/reservation_model.dart';
import '../../services/firestore_service.dart';

class BookingApprovalPage extends StatefulWidget {
  const BookingApprovalPage({super.key});

  @override
  State<BookingApprovalPage> createState() =>
      _BookingApprovalPageState();
}

class _BookingApprovalPageState extends State<BookingApprovalPage> {
  final FirestoreService _firestoreService = FirestoreService();

  String _selectedFilter = 'Semua';

  String _displayStatus(String status) {
    switch (status) {
      case 'pending':
        return 'Menunggu';
      case 'approved':
        return 'Disetujui';
      case 'rejected':
        return 'Ditolak';
      default:
        return status;
    }
  }

  List<ReservationModel> _filterBookings(
    List<ReservationModel> reservations,
  ) {
    // Reservasi maintenance bukan pengajuan mahasiswa.
    final bookings = reservations
        .where((item) => item.type != 'maintenance_block')
        .toList();

    if (_selectedFilter == 'Semua') {
      return bookings;
    }

    return bookings.where((booking) {
      return _displayStatus(booking.status) == _selectedFilter;
    }).toList();
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;

    return '$day/$month/$year';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour.$minute';
  }

  Future<String?> _askRejectionReason() async {
    final controller = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Alasan Penolakan'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Masukkan alasan penolakan...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();

              if (value.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Alasan penolakan wajib diisi.'),
                  ),
                );
                return;
              }

              Navigator.pop(dialogContext, value);
            },
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );

    controller.dispose();
    return reason;
  }

  Future<void> _confirmAction(
    ReservationModel booking,
    String status,
  ) async {
    final isApprove = status == 'approved';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          isApprove ? 'Setujui Peminjaman?' : 'Tolak Peminjaman?',
        ),
        content: Text(
          'Apakah kamu yakin ingin '
          '${isApprove ? 'menyetujui' : 'menolak'} '
          'pengajuan dari ${booking.studentName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor:
                  isApprove ? AppTheme.success : AppTheme.danger,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(isApprove ? 'Setujui' : 'Tolak'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    String? rejectionReason;

    if (!isApprove) {
      rejectionReason = await _askRejectionReason();

      if (rejectionReason == null || rejectionReason.trim().isEmpty) {
        return;
      }
    }

    try {
      final adminId = FirebaseAuth.instance.currentUser?.uid;

      if (adminId == null) {
        throw Exception('Akun Admin belum login.');
      }

      if (isApprove) {
        await _firestoreService.approveReservation(
          reservationId: booking.reservationId,
          adminId: adminId,
        );
      } else {
        await _firestoreService.rejectReservation(
          reservationId: booking.reservationId,
          adminId: adminId,
          rejectionReason: rejectionReason!,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pengajuan ${booking.reservationId} berhasil '
            '${isApprove ? 'disetujui' : 'ditolak'}.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui pengajuan: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Persetujuan Peminjaman'),
      ),
      body: StreamBuilder<List<ReservationModel>>(
        stream: _firestoreService.getAllReservations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Gagal mengambil data reservasi:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final allReservations =
              snapshot.data ?? <ReservationModel>[];

          final allBookings = allReservations
              .where((item) => item.type != 'maintenance_block')
              .toList();

          final bookings = _filterBookings(allReservations);

          final waiting = allBookings
              .where((item) => item.status == 'pending')
              .length;

          final approved = allBookings
              .where((item) => item.status == 'approved')
              .length;

          final rejected = allBookings
              .where((item) => item.status == 'rejected')
              .length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Persetujuan Peminjaman',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.ink,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Periksa dan kelola pengajuan peminjaman laboratorium.',
                      style: TextStyle(color: AppTheme.muted),
                    ),

                    const SizedBox(height: 24),

                    // Statistik dari Firestore
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns =
                            constraints.maxWidth >= 600 ? 3 : 1;

                        return GridView.count(
                          crossAxisCount: columns,
                          shrinkWrap: true,
                          physics:
                              const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio:
                              columns == 3 ? 2.8 : 4,
                          children: [
                            _SummaryCard(
                              title: 'Menunggu',
                              value: '$waiting',
                              icon: Icons.pending_actions,
                              color: AppTheme.warning,
                            ),
                            _SummaryCard(
                              title: 'Disetujui',
                              value: '$approved',
                              icon: Icons.check_circle_outline,
                              color: AppTheme.success,
                            ),
                            _SummaryCard(
                              title: 'Ditolak',
                              value: '$rejected',
                              icon: Icons.cancel_outlined,
                              color: AppTheme.danger,
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 28),

                    const Text(
                      'Daftar Pengajuan',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.ink,
                      ),
                    ),

                    const SizedBox(height: 14),

                    Wrap(
                      spacing: 8,
                      children: [
                        'Semua',
                        'Menunggu',
                        'Disetujui',
                        'Ditolak',
                      ].map((filter) {
                        return ChoiceChip(
                          label: Text(filter),
                          selected: _selectedFilter == filter,
                          onSelected: (_) {
                            setState(() {
                              _selectedFilter = filter;
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    if (bookings.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: Text(
                              'Tidak ada pengajuan pada kategori ini.',
                              style: TextStyle(
                                color: AppTheme.muted,
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      ...bookings.map(
                        (booking) => _BookingCard(
                          booking: booking,
                          formatDate: _formatDate,
                          formatTime: _formatTime,
                          onApprove: () =>
                              _confirmAction(booking, 'approved'),
                          onReject: () =>
                              _confirmAction(booking, 'rejected'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(width: 14),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.ink,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.muted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final ReservationModel booking;
  final String Function(DateTime) formatDate;
  final String Function(DateTime) formatTime;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _BookingCard({
    required this.booking,
    required this.formatDate,
    required this.formatTime,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final status = switch (booking.status) {
      'approved' => 'Disetujui',
      'rejected' => 'Ditolak',
      _ => 'Menunggu',
    };

    final isWaiting = booking.status == 'pending';

    final statusColor = switch (booking.status) {
      'approved' => AppTheme.success,
      'rejected' => AppTheme.danger,
      _ => AppTheme.warning,
    };

    final statusBackground = switch (booking.status) {
      'approved' => AppTheme.successSoft,
      'rejected' => AppTheme.dangerSoft,
      _ => AppTheme.warningSoft,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    booking.reservationId,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusBackground,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            Text(
              booking.studentName,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppTheme.ink,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              'NIM: ${booking.studentNim}',
              style: const TextStyle(color: AppTheme.muted),
            ),

            const SizedBox(height: 16),

            _InfoItem(
              icon: Icons.science_outlined,
              text: booking.labName,
            ),

            const SizedBox(height: 10),

            _InfoItem(
              icon: Icons.calendar_today_outlined,
              text: formatDate(booking.startTime),
            ),

            const SizedBox(height: 10),

            _InfoItem(
              icon: Icons.access_time,
              text: '${formatTime(booking.startTime)} - '
                  '${formatTime(booking.endTime)}',
            ),

            const SizedBox(height: 10),

            _InfoItem(
              icon: Icons.description_outlined,
              text: booking.purpose,
            ),

            if (booking.rejectionReason != null &&
                booking.rejectionReason!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _InfoItem(
                icon: Icons.info_outline,
                text: 'Alasan penolakan: ${booking.rejectionReason}',
              ),
            ],

            if (isWaiting) ...[
              const Divider(height: 28),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.danger,
                      ),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Tolak'),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onApprove,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.success,
                      ),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Setujui'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 17,
          color: AppTheme.muted,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.muted,
            ),
          ),
        ),
      ],
    );
  }
}

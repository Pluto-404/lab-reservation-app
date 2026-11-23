import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../models/reservation_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/info_state.dart';
import '../../widgets/reservation_status_chip.dart';
import '../../widgets/summary_stat_card.dart';

class BookingApprovalPage extends StatefulWidget {
  const BookingApprovalPage({
    super.key,
    this.showAppBar = true,
  });

  final bool showAppBar;

  @override
  State<BookingApprovalPage> createState() => _BookingApprovalPageState();
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
    final bodyContent = StreamBuilder<List<ReservationModel>>(
      stream: _firestoreService.getAllReservations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(48),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return InfoState(
            icon: Icons.error_outline,
            text: 'Gagal mengambil data reservasi.',
            subtext: '${snapshot.error}',
          );
        }

        final allReservations = snapshot.data ?? <ReservationModel>[];

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

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Persetujuan Peminjaman',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Periksa dan verifikasi pengajuan peminjaman laboratorium.',
              style: TextStyle(color: AppTheme.muted),
            ),
            const SizedBox(height: 24),

            // Statistik dari Firestore
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 600 ? 3 : 1;

                return GridView.count(
                  crossAxisCount: columns,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: columns == 3 ? 2.5 : 4.0,
                  children: [
                    SummaryStatCard(
                      title: 'Menunggu',
                      value: '$waiting',
                      icon: Icons.pending_actions_outlined,
                      iconColor: AppTheme.warning,
                      backgroundColor: AppTheme.warningSoft,
                    ),
                    SummaryStatCard(
                      title: 'Disetujui',
                      value: '$approved',
                      icon: Icons.check_circle_outline,
                      iconColor: AppTheme.success,
                      backgroundColor: AppTheme.successSoft,
                    ),
                    SummaryStatCard(
                      title: 'Ditolak',
                      value: '$rejected',
                      icon: Icons.cancel_outlined,
                      iconColor: AppTheme.danger,
                      backgroundColor: AppTheme.dangerSoft,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 28),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Daftar Pengajuan',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
                Text(
                  '${bookings.length} pengajuan',
                  style: const TextStyle(
                    color: AppTheme.muted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

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
              const InfoState(
                icon: Icons.inbox_outlined,
                text: 'Tidak ada pengajuan pada kategori ini.',
                subtext: 'Pilih filter lain atau tunggu pengajuan masuk dari mahasiswa.',
              )
            else
              ...bookings.map(
                (booking) => _BookingCard(
                  booking: booking,
                  formatDate: _formatDate,
                  formatTime: _formatTime,
                  onApprove: () => _confirmAction(booking, 'approved'),
                  onReject: () => _confirmAction(booking, 'rejected'),
                ),
              ),
          ],
        );
      },
    );

    if (!widget.showAppBar) {
      return PageWidth(maxWidth: 800, child: bodyContent);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Persetujuan Peminjaman'),
      ),
      body: PageWidth(maxWidth: 800, child: bodyContent),
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
    final isWaiting = booking.status == 'pending';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.reservationId,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.deep,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          booking.studentName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.ink,
                          ),
                        ),
                        Text(
                          'NIM: ${booking.studentNim.isEmpty ? '-' : booking.studentNim}',
                          style: const TextStyle(
                            color: AppTheme.muted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ReservationStatusChip(status: booking.status),
                ],
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Divider(height: 1, color: AppTheme.outline),
              ),

              _InfoItem(
                icon: Icons.apartment_outlined,
                text: booking.labName,
              ),
              const SizedBox(height: 8),
              _InfoItem(
                icon: Icons.calendar_today_outlined,
                text: formatDate(booking.startTime),
              ),
              const SizedBox(height: 8),
              _InfoItem(
                icon: Icons.access_time_outlined,
                text:
                    '${formatTime(booking.startTime)} - ${formatTime(booking.endTime)} WIB',
              ),
              const SizedBox(height: 8),
              _InfoItem(
                icon: Icons.description_outlined,
                text: booking.purpose.isEmpty
                    ? 'Keperluan tidak dicantumkan'
                    : booking.purpose,
              ),

              if (booking.rejectionReason != null &&
                  booking.rejectionReason!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _InfoItem(
                  icon: Icons.info_outline,
                  text: 'Catatan penolakan: ${booking.rejectionReason}',
                  iconColor: AppTheme.danger,
                  textColor: AppTheme.danger,
                ),
              ],

              if (isWaiting) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(height: 1, color: AppTheme.outline),
                ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onReject,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.danger,
                          side: const BorderSide(color: AppTheme.danger),
                        ),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Tolak'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onApprove,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.success,
                          foregroundColor: Colors.white,
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
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? iconColor;
  final Color? textColor;

  const _InfoItem({
    required this.icon,
    required this.text,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 17,
          color: iconColor ?? AppTheme.muted,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: textColor ?? AppTheme.muted,
            ),
          ),
        ),
      ],
    );
  }
}

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
  late final Stream<List<ReservationModel>> _reservationsStream;

  String _selectedFilter = 'Semua';
  final Set<String> _processingIds = {};

  @override
  void initState() {
    super.initState();
    _reservationsStream = _firestoreService.getAllReservations();
  }

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

  Future<void> _approveBooking(ReservationModel booking) async {
    if (_processingIds.contains(booking.reservationId)) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Setujui Peminjaman?'),
        content: Text(
          'Apakah kamu yakin ingin menyetujui pengajuan dari ${booking.studentName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.success,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Setujui'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    if (_processingIds.contains(booking.reservationId)) return;

    setState(() {
      _processingIds.add(booking.reservationId);
    });

    try {
      final adminId = FirebaseAuth.instance.currentUser?.uid;

      if (adminId == null) {
        throw Exception('Akun Admin belum login.');
      }

      await _firestoreService.approveReservation(
        reservationId: booking.reservationId,
        adminId: adminId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pengajuan ${booking.reservationId} berhasil disetujui.',
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
    } finally {
      if (mounted) {
        setState(() {
          _processingIds.remove(booking.reservationId);
        });
      }
    }
  }

  Future<void> _rejectBooking(ReservationModel booking) async {
    if (_processingIds.contains(booking.reservationId)) return;

    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => RejectReservationDialog(
        studentName: booking.studentName,
      ),
    );

    if (reason == null || reason.trim().isEmpty || !mounted) return;
    if (_processingIds.contains(booking.reservationId)) return;

    setState(() {
      _processingIds.add(booking.reservationId);
    });

    try {
      final adminId = FirebaseAuth.instance.currentUser?.uid;

      if (adminId == null) {
        throw Exception('Akun Admin belum login.');
      }

      await _firestoreService.rejectReservation(
        reservationId: booking.reservationId,
        adminId: adminId,
        rejectionReason: reason.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pengajuan ${booking.reservationId} berhasil ditolak.',
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
    } finally {
      if (mounted) {
        setState(() {
          _processingIds.remove(booking.reservationId);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bodyContent = StreamBuilder<List<ReservationModel>>(
      stream: _reservationsStream,
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
                  key: ValueKey(booking.reservationId),
                  booking: booking,
                  formatDate: _formatDate,
                  formatTime: _formatTime,
                  isProcessing:
                      _processingIds.contains(booking.reservationId),
                  onApprove: () => _approveBooking(booking),
                  onReject: () => _rejectBooking(booking),
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

class BookingApprovalCard extends StatelessWidget {
  final ReservationModel booking;
  final String Function(DateTime) formatDate;
  final String Function(DateTime) formatTime;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final bool isProcessing;

  const BookingApprovalCard({
    super.key,
    required this.booking,
    required this.formatDate,
    required this.formatTime,
    required this.onApprove,
    required this.onReject,
    this.isProcessing = false,
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
                if (isProcessing)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Memproses pembaruan...',
                            style: TextStyle(
                              color: AppTheme.muted,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onReject,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.danger,
                            foregroundColor: Colors.white,
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

typedef _BookingCard = BookingApprovalCard;

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

class RejectReservationDialog extends StatefulWidget {
  final String studentName;

  const RejectReservationDialog({
    super.key,
    required this.studentName,
  });

  @override
  State<RejectReservationDialog> createState() =>
      _RejectReservationDialogState();
}

class _RejectReservationDialogState extends State<RejectReservationDialog> {
  late final TextEditingController _controller;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() {
        _errorMessage = 'Alasan penolakan wajib diisi.';
      });
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tolak Peminjaman'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Masukkan alasan penolakan untuk pengajuan dari ${widget.studentName}:',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 3,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Masukkan alasan penolakan...',
                errorText: _errorMessage,
              ),
              onChanged: (text) {
                if (_errorMessage != null && text.trim().isNotEmpty) {
                  setState(() {
                    _errorMessage = null;
                  });
                }
              },
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.danger,
          ),
          onPressed: _submit,
          child: const Text('Tolak'),
        ),
      ],
    );
  }
}

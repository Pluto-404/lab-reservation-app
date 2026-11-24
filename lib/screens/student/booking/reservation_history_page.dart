import 'package:flutter/material.dart';

import '../../../app_theme.dart';
import '../../../models/reservation_model.dart';
import '../../../services/booking_service.dart';
import '../../../widgets/reservation_status_chip.dart';

/// Riwayat pengajuan milik mahasiswa yang sedang login.
class ReservationHistoryPage extends StatefulWidget {
  const ReservationHistoryPage({super.key, required this.userId});

  final String userId;

  @override
  State<ReservationHistoryPage> createState() => _ReservationHistoryPageState();
}

class _ReservationHistoryPageState extends State<ReservationHistoryPage> {
  final BookingService _bookingService = BookingService();
  late Stream<List<ReservationModel>> _reservations;
  String _filter = 'semua';
  String? _cancellingId;

  @override
  void initState() {
    super.initState();
    _reservations = _bookingService.watchMyReservations(widget.userId);
  }

  @override
  void didUpdateWidget(covariant ReservationHistoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _reservations = _bookingService.watchMyReservations(widget.userId);
      _filter = 'semua';
    }
  }

  static String _date(DateTime value) {
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
    return '${value.day} ${months[value.month - 1]} ${value.year}';
  }

  static String _time(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}.${value.minute.toString().padLeft(2, '0')}';

  bool _canCancel(ReservationModel booking) =>
      booking.userId == widget.userId &&
      booking.type == 'student_booking' &&
      (booking.status == 'pending' || booking.status == 'approved') &&
      booking.startTime.isAfter(DateTime.now());

  void _showDetails(ReservationModel booking) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        titlePadding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        title: const Row(
          children: [
            Icon(Icons.receipt_long_outlined, color: AppTheme.deep, size: 23),
            SizedBox(width: 10),
            Expanded(
              child: Text('Detail pesanan', style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
        content: SizedBox(
          width: 390,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ReservationStatusChip(status: booking.status),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: AppTheme.canvas,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.outline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _detailLine('Laboratorium', booking.labName),
                      const Divider(height: 19, color: AppTheme.outline),
                      _detailLine('Kegiatan', booking.title),
                      const Divider(height: 19, color: AppTheme.outline),
                      _detailLine('Keperluan', booking.purpose),
                      const Divider(height: 19, color: AppTheme.outline),
                      _detailLine('Tanggal', _date(booking.startTime)),
                      const Divider(height: 19, color: AppTheme.outline),
                      _detailLine(
                        'Waktu',
                        '${_time(booking.startTime)} – ${_time(booking.endTime)}',
                      ),
                      if (booking.participants > 0) ...[
                        const Divider(height: 19, color: AppTheme.outline),
                        _detailLine('Peserta', '${booking.participants} orang'),
                      ],
                    ],
                  ),
                ),
                if (booking.status == 'rejected') ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.dangerSoft,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.danger.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 18,
                              color: AppTheme.danger,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Alasan penolakan',
                              style: TextStyle(
                                color: AppTheme.danger,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          booking.rejectionReason?.trim().isNotEmpty == true
                              ? booking.rejectionReason!.trim()
                              : 'Admin belum memberikan keterangan.',
                          style: const TextStyle(fontSize: 13, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _detailLine(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
      const SizedBox(height: 4),
      Text(value.isEmpty ? '—' : value, style: const TextStyle(height: 1.35)),
    ],
  );

  Future<void> _cancel(ReservationModel booking) async {
    if (!_canCancel(booking) || _cancellingId != null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 10),
        contentPadding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 25),
            SizedBox(width: 9),
            Expanded(
              child: Text(
                'Batalkan peminjaman?',
                style: TextStyle(fontSize: 19),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 390,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Periksa kembali pengajuan yang akan dibatalkan.',
                style: TextStyle(color: AppTheme.muted, fontSize: 13),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.canvas,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.labName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_date(booking.startTime)} · ${_time(booking.startTime)}–${_time(booking.endTime)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Tindakan ini tidak dapat dibatalkan.',
                style: TextStyle(color: AppTheme.danger, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Kembali'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Ya, batalkan'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _cancellingId = booking.reservationId);
    try {
      await _bookingService.cancelMyReservation(
        reservationId: booking.reservationId,
        userId: widget.userId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Peminjaman berhasil dibatalkan.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak dapat membatalkan: $error')),
      );
    } finally {
      if (mounted) setState(() => _cancellingId = null);
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<List<ReservationModel>>(
    stream: _reservations,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting &&
          !snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return _message(
          Icons.cloud_off_outlined,
          'Gagal memuat pesanan',
          'Periksa koneksi internet atau izin akses Firestore.',
        );
      }

      final all = [...?snapshot.data]
        ..removeWhere((item) => item.type == 'maintenance_block')
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final visible = _filter == 'semua'
          ? all
          : all.where((item) => item.status == _filter).toList();

      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 26),
        children: [
          const Text(
            'Pesanan saya',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Pantau pengajuan dan status peminjaman laboratorium.',
            style: TextStyle(color: AppTheme.muted),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _filterChip('Semua', 'semua'),
                _filterChip('Menunggu', 'pending'),
                _filterChip('Disetujui', 'approved'),
                _filterChip('Ditolak', 'rejected'),
                _filterChip('Dibatalkan', 'cancelled'),
                _filterChip('Selesai', 'completed'),
              ],
            ),
          ),
          const SizedBox(height: 15),
          if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 85),
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 50,
                    color: AppTheme.muted.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    all.isEmpty
                        ? 'Belum ada pesanan'
                        : 'Tidak ada pesanan pada status ini',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Ajukan peminjaman melalui menu Kalender atau Laboratorium.',
                    style: TextStyle(color: AppTheme.muted, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...visible.map(_reservationCard),
        ],
      );
    },
  );

  Widget _filterChip(String label, String value) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: _filter == value,
      onSelected: (_) => setState(() => _filter = value),
      selectedColor: AppTheme.soft,
      side: BorderSide(
        color: _filter == value ? AppTheme.primary : AppTheme.outline,
      ),
      labelStyle: TextStyle(
        color: _filter == value ? AppTheme.deep : AppTheme.ink,
        fontWeight: _filter == value ? FontWeight.w600 : FontWeight.w400,
        fontSize: 12,
      ),
      showCheckmark: false,
    ),
  );

  Widget _reservationCard(ReservationModel booking) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    booking.labName.isEmpty ? 'Laboratorium' : booking.labName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ReservationStatusChip(status: booking.status, compact: true),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              booking.title.isEmpty ? 'Pengajuan peminjaman' : booking.title,
              style: const TextStyle(color: AppTheme.muted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: AppTheme.deep,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_date(booking.startTime)}  ·  ${_time(booking.startTime)}–${_time(booking.endTime)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            if (booking.status == 'rejected') ...[
              const SizedBox(height: 10),
              Text(
                'Alasan: ${booking.rejectionReason?.trim().isNotEmpty == true ? booking.rejectionReason!.trim() : 'Belum ada keterangan'}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppTheme.danger, fontSize: 12),
              ),
            ],
            const Divider(height: 24),
            Row(
              children: [
                TextButton(
                  onPressed: () => _showDetails(booking),
                  child: const Text('Lihat detail'),
                ),
                const Spacer(),
                if (_canCancel(booking))
                  TextButton(
                    onPressed: _cancellingId == null
                        ? () => _cancel(booking)
                        : null,
                    child: _cancellingId == booking.reservationId
                        ? const SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Batalkan',
                            style: TextStyle(color: AppTheme.danger),
                          ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Widget _message(IconData icon, String title, String body) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppTheme.muted),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(body, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

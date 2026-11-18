import 'package:flutter/material.dart';

import '../../../app_theme.dart';
import '../../../models/laboratory_model.dart';
import '../../../models/reservation_model.dart';
import '../../../models/user_model.dart';
import '../../../routes/app_routes.dart';
import '../../../services/auth_service.dart';
import '../../../services/booking_service.dart';
import '../../../services/firestore_service.dart';
import '../../../utils/booking_validator.dart';
import '../../../utils/date_id.dart';
import '../booking/booking_form_page.dart';
import '../booking/reservation_status_chip.dart';
import '../widgets/info_state.dart';
import 'weekly_calendar.dart';

/// Kalender mingguan ketersediaan laboratorium + tombol pengajuan booking.
/// Dipakai sebagai tab "Kalender" di StudentHome dan sebagai halaman penuh
/// (dari detail laboratorium) lewat [AppRoutes.studentSchedule].
class StudentSchedulePage extends StatefulWidget {
  const StudentSchedulePage({
    super.key,
    this.profile,
    this.initialLab,
    this.onCompleteProfile,
    this.showAppBar = false,
  });

  /// Bila null, profil dimuat dari AuthService.
  final UserModel? profile;
  final LaboratoryModel? initialLab;
  final VoidCallback? onCompleteProfile;
  final bool showAppBar;

  @override
  State<StudentSchedulePage> createState() => _StudentSchedulePageState();
}

class _StudentSchedulePageState extends State<StudentSchedulePage> {
  final _labService = FirestoreService();
  final _booking = BookingService();
  late final Stream<List<LaboratoryModel>> _labsStream = _labService
      .getActiveLaboratories();

  UserModel? _loadedProfile;
  bool _profileFailed = false;

  String? _labId;
  late DateTime _weekStart = DateId.startOfWeek(DateTime.now());

  String? _boundKey;
  Stream<List<ReservationModel>>? _scheduleStream;
  Stream<List<ReservationModel>>? _mineStream;

  UserModel? get _profile => widget.profile ?? _loadedProfile;

  @override
  void initState() {
    super.initState();
    _labId = widget.initialLab?.labId;
    if (widget.profile == null) _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final p = await AuthService().getCurrentUserProfile();
      if (!mounted) return;
      setState(() {
        _loadedProfile = p;
        _profileFailed = p == null;
      });
    } catch (_) {
      if (mounted) setState(() => _profileFailed = true);
    }
  }

  void _bind(String labId) {
    final key = '$labId|${_profile?.uid ?? ''}';
    if (_boundKey == key) return;
    _boundKey = key;
    _scheduleStream = _booking.watchLabSchedule(labId);
    _mineStream = _booking.watchMyReservations(_profile?.uid ?? '');
  }

  void _retry() => setState(() => _boundKey = null);

  List<ReservationModel> _merge(
    List<ReservationModel> lab,
    List<ReservationModel> mine,
    String labId,
  ) {
    final map = {for (final r in lab) r.reservationId: r};
    for (final r in mine) {
      if (r.labId == labId && r.status == 'pending') map[r.reservationId] = r;
    }
    return map.values.toList();
  }

  Future<void> _pickLab(List<LaboratoryModel> labs, String currentId) async {
    final picked = await showModalBottomSheet<LaboratoryModel>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 8, 24, 12),
              child: Text(
                'Pilih laboratorium',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
            for (final lab in labs)
              ListTile(
                title: Text(lab.name),
                subtitle: Text(lab.building),
                trailing: lab.labId == currentId
                    ? const Icon(Icons.check, color: AppTheme.primary)
                    : null,
                onTap: () => Navigator.pop(ctx, lab),
              ),
          ],
        ),
      ),
    );
    if (picked != null && mounted) setState(() => _labId = picked.labId);
  }

  void _changeWeek(int deltaWeeks) =>
      setState(() => _weekStart = DateId.addDays(_weekStart, deltaWeeks * 7));

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openBooking(LaboratoryModel lab, [DateTime? start]) async {
    final profile = _profile;
    if (profile == null) {
      _toast('Profil belum termuat. Coba lagi sebentar.');
      return;
    }
    if (profile.nim.isEmpty ||
        profile.className.isEmpty ||
        profile.cohort.isEmpty) {
      await _showIncompleteProfile();
      return;
    }
    final booked = await Navigator.pushNamed<DateTime>(
      context,
      AppRoutes.studentBooking,
      arguments: BookingFormArgs(
        lab: lab,
        profile: profile,
        initialStart: start,
      ),
    );
    if (booked != null && mounted) {
      setState(() => _weekStart = DateId.startOfWeek(booked));
      _toast('Pengajuan terkirim. Menunggu persetujuan asisten laboratorium.');
    }
  }

  Future<void> _showIncompleteProfile() async {
    final canOpenProfile = widget.onCompleteProfile != null;
    final goToProfile = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Lengkapi profil dulu'),
        content: Text(
          canOpenProfile
              ? 'Pengajuan peminjaman memerlukan NIM, kelas, dan angkatan pada profilmu.'
              : 'Pengajuan peminjaman memerlukan NIM, kelas, dan angkatan. Lengkapi dulu di tab Profil.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(canOpenProfile ? 'Nanti' : 'Mengerti'),
          ),
          if (canOpenProfile)
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Lengkapi Profil'),
            ),
        ],
      ),
    );
    if (goToProfile == true) widget.onCompleteProfile?.call();
  }

  void _showReservation(ReservationModel r) {
    final profile = _profile;
    final isMine = profile != null && r.userId == profile.uid;
    final isBlock = r.type == 'maintenance_block';
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      r.title.isEmpty ? 'Jadwal terisi' : r.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ReservationStatusChip(
                    status: isBlock ? 'maintenance_block' : r.status,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _InfoLine(icon: Icons.apartment_outlined, text: r.labName),
              _InfoLine(
                icon: Icons.event_outlined,
                text: DateId.full(r.startTime),
              ),
              _InfoLine(
                icon: Icons.schedule_outlined,
                text: DateId.range(r.startTime, r.endTime),
              ),
              if (isMine && r.purpose.isNotEmpty)
                _InfoLine(icon: Icons.notes_outlined, text: r.purpose),
              if (isBlock)
                const _InfoLine(
                  icon: Icons.lock_outline,
                  text:
                      'Diblokir laboran untuk kelas reguler atau pemeliharaan.',
                )
              else if (isMine && r.status == 'pending')
                const _InfoLine(
                  icon: Icons.hourglass_empty,
                  text:
                      'Pengajuanmu menunggu persetujuan asisten laboratorium.',
                )
              else if (isMine)
                const _InfoLine(
                  icon: Icons.person_outline,
                  text: 'Ini pengajuanmu.',
                ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Tutup'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody();
    if (!widget.showAppBar) return body;
    return Scaffold(
      appBar: AppBar(title: const Text('Jadwal laboratorium')),
      body: SafeArea(child: PageWidth(maxWidth: 680, child: body)),
    );
  }

  Widget _buildBody() {
    if (widget.profile == null && _loadedProfile == null) {
      if (_profileFailed) {
        return const InfoState(
          icon: Icons.person_off_outlined,
          text: 'Gagal memuat profil. Periksa koneksi lalu buka kembali halaman ini.',
        );
      }
      return const Center(child: CircularProgressIndicator());
    }
    return StreamBuilder<List<LaboratoryModel>>(
      stream: _labsStream,
      builder: (context, labsSnapshot) {
        if (labsSnapshot.hasError) {
          return const InfoState(
            icon: Icons.wifi_off_rounded,
            text: 'Gagal memuat laboratorium. Periksa koneksi atau izin Firestore.',
          );
        }
        if (!labsSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final labs = [...labsSnapshot.data!]
          ..sort((a, b) => a.name.compareTo(b.name));
        if (labs.isEmpty) {
          return const InfoState(
            icon: Icons.apartment_outlined,
            text: 'Belum ada laboratorium aktif untuk dijadwalkan.',
          );
        }
        final lab = labs.firstWhere(
          (l) => l.labId == _labId,
          orElse: () => labs.first,
        );
        _bind(lab.labId);
        return _buildCalendarArea(labs, lab);
      },
    );
  }

  Widget _buildCalendarArea(List<LaboratoryModel> labs, LaboratoryModel lab) {
    final hours = OperationalHours.parse(lab.operationalHours);
    final isCurrentWeek = _weekStart == DateId.startOfWeek(DateTime.now());
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.showAppBar) ...[
                const Text(
                  'Kalender',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Lihat jadwal laboratorium, lalu ketuk area kosong untuk mengajukan.',
                  style: TextStyle(color: AppTheme.muted),
                ),
                const SizedBox(height: 14),
              ],
              _LabPicker(
                lab: lab,
                hours: hours,
                onTap: () => _pickLab(labs, lab.labId),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Minggu sebelumnya',
                    onPressed: () => _changeWeek(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Text(
                      DateId.weekLabel(_weekStart),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  if (!isCurrentWeek)
                    TextButton(
                      onPressed: () => setState(
                        () => _weekStart = DateId.startOfWeek(DateTime.now()),
                      ),
                      child: const Text('Hari ini'),
                    ),
                  IconButton(
                    tooltip: 'Minggu berikutnya',
                    onPressed: () => _changeWeek(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              const _Legend(),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.outline),
        Expanded(child: _buildCalendar(lab, hours)),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
            child: ElevatedButton.icon(
              onPressed: () => _openBooking(lab),
              icon: const Icon(Icons.edit_calendar_outlined),
              label: const Text('Ajukan Peminjaman'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendar(LaboratoryModel lab, OperationalHours hours) =>
      StreamBuilder<List<ReservationModel>>(
        stream: _scheduleStream,
        builder: (context, scheduleSnapshot) {
          return StreamBuilder<List<ReservationModel>>(
            stream: _mineStream,
            builder: (context, mineSnapshot) {
              if (scheduleSnapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const InfoState(
                        icon: Icons.wifi_off_rounded,
                        text: 'Gagal memuat jadwal. Periksa koneksi atau izin Firestore.',
                      ),
                      OutlinedButton(
                        onPressed: _retry,
                        child: const Text('Coba lagi'),
                      ),
                    ],
                  ),
                );
              }
              if (!scheduleSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final reservations = _merge(
                scheduleSnapshot.data!,
                mineSnapshot.data ?? const [],
                lab.labId,
              );
              return WeeklyCalendar(
                weekStart: _weekStart,
                hours: hours,
                reservations: reservations,
                onSlotTap: (start) => _openBooking(lab, start),
                onReservationTap: _showReservation,
                onBlockedTap: _toast,
              );
            },
          );
        },
      );
}

class _LabPicker extends StatelessWidget {
  const _LabPicker({
    required this.lab,
    required this.hours,
    required this.onTap,
  });

  final LaboratoryModel lab;
  final OperationalHours hours;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(13),
    child: InkWell(
      borderRadius: BorderRadius.circular(13),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppTheme.outline),
        ),
        child: Row(
          children: [
            const Icon(Icons.apartment_rounded, color: AppTheme.deep),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lab.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      lab.building,
                      if (hours.isDefined) hours.label,
                    ].where((e) => e.isNotEmpty).join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.expand_more, color: AppTheme.muted),
          ],
        ),
      ),
    ),
  );
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) => const Wrap(
    spacing: 14,
    runSpacing: 6,
    children: [
      _LegendItem(
        fill: AppTheme.successSoft,
        border: AppTheme.success,
        label: 'Disetujui',
      ),
      _LegendItem(
        fill: AppTheme.warningSoft,
        border: AppTheme.warning,
        label: 'Pengajuanmu (menunggu)',
      ),
      _LegendItem(
        fill: Color(0xFFE2E8F0),
        border: AppTheme.muted,
        label: 'Diblokir lab',
      ),
      _LegendItem(
        fill: Color(0xFFEEF2F6),
        border: AppTheme.outline,
        label: 'Tidak tersedia',
      ),
    ],
  );
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.fill,
    required this.border,
    required this.label,
  });

  final Color fill;
  final Color border;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: border),
        ),
      ),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
    ],
  );
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.deep),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
      ],
    ),
  );
}

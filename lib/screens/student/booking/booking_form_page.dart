import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' show FirebaseException;
import 'package:flutter/material.dart';

import '../../../app_theme.dart';
import '../../../models/laboratory_model.dart';
import '../../../models/reservation_model.dart';
import '../../../models/user_model.dart';
import '../../../services/booking_service.dart';
import '../../../utils/booking_validator.dart';
import '../../../utils/date_id.dart';
import 'reservation_status_chip.dart';

/// Argumen untuk rute [AppRoutes.studentBooking].
class BookingFormArgs {
  const BookingFormArgs({
    required this.lab,
    required this.profile,
    this.initialStart,
  });

  final LaboratoryModel lab;
  final UserModel profile;

  /// Jam mulai awal (misalnya dari ketukan slot di kalender).
  final DateTime? initialStart;
}

/// Form pengajuan booking + validasi jadwal bentrok secara realtime.
/// Menutup dengan hasil [DateTime] (jam mulai) bila pengajuan terkirim.
class BookingFormPage extends StatefulWidget {
  const BookingFormPage({super.key, required this.args});

  final BookingFormArgs args;

  @override
  State<BookingFormPage> createState() => _BookingFormPageState();
}

class _BookingFormPageState extends State<BookingFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _booking = BookingService();

  final _dateC = TextEditingController();
  final _startC = TextEditingController();
  final _endC = TextEditingController();
  final _titleC = TextEditingController();
  final _purposeC = TextEditingController();
  final _participantsC = TextEditingController();

  DateTime? _date;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  List<ReservationModel> _labSchedule = const [];
  List<ReservationModel> _mine = const [];
  StreamSubscription<List<ReservationModel>>? _labSub;
  StreamSubscription<List<ReservationModel>>? _mineSub;
  bool _scheduleLoaded = false;
  bool _scheduleFailed = false;

  bool _submitting = false;
  String? _submitError;

  LaboratoryModel get _lab => widget.args.lab;
  UserModel get _profile => widget.args.profile;
  OperationalHours get _hours => OperationalHours.parse(_lab.operationalHours);

  @override
  void initState() {
    super.initState();
    _applyInitialStart(widget.args.initialStart);
    _labSub = _booking
        .watchLabSchedule(_lab.labId)
        .listen(
          (items) {
            if (!mounted) return;
            setState(() {
              _labSchedule = items;
              _scheduleLoaded = true;
              _scheduleFailed = false;
            });
          },
          onError: (_) {
            if (!mounted) return;
            setState(() => _scheduleFailed = true);
          },
        );
    _mineSub = _booking.watchMyReservations(_profile.uid).listen((items) {
      if (!mounted) return;
      setState(() => _mine = items);
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _labSub?.cancel();
    _mineSub?.cancel();
    _dateC.dispose();
    _startC.dispose();
    _endC.dispose();
    _titleC.dispose();
    _purposeC.dispose();
    _participantsC.dispose();
    super.dispose();
  }

  void _applyInitialStart(DateTime? start) {
    if (start == null) return;
    _date = DateId.dateOnly(start);
    _startTime = TimeOfDay(hour: start.hour, minute: start.minute);
    var endMin = start.hour * 60 + start.minute + 60;
    final hours = _hours;
    if (hours.isDefined) endMin = endMin.clamp(0, hours.endMinute).toInt();
    endMin = endMin.clamp(0, 23 * 60 + 59).toInt();
    if (endMin > start.hour * 60 + start.minute) {
      _endTime = TimeOfDay(hour: endMin ~/ 60, minute: endMin % 60);
    }
    _syncControllers();
  }

  void _syncControllers() {
    _dateC.text = _date == null ? '' : DateId.full(_date!);
    _startC.text = _startTime == null ? '' : _fmt(_startTime!);
    _endC.text = _endTime == null ? '' : _fmt(_endTime!);
  }

  static String _fmt(TimeOfDay t) => DateId.hm(t.hour, t.minute);

  DateTime? _compose(TimeOfDay? t) {
    final d = _date;
    if (d == null || t == null) return null;
    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  DateTime? get _start => _compose(_startTime);
  DateTime? get _end => _compose(_endTime);

  String? get _scheduleIssue => BookingValidator.validateSchedule(
    lab: _lab,
    start: _start,
    end: _end,
    labSchedule: _labSchedule,
    myReservations: _mine,
  );

  Future<void> _pickDate() async {
    final today = DateId.dateOnly(DateTime.now());
    final initial = (_date != null && !_date!.isBefore(today)) ? _date! : today;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today,
      lastDate: today.add(const Duration(days: 180)),
      helpText: 'Pilih Tanggal',
    );
    if (picked == null) return;
    setState(() {
      _date = picked;
      _submitError = null;
      _syncControllers();
    });
  }

  Future<TimeOfDay?> _pickTime(TimeOfDay? initial, String help) {
    final hours = _hours;
    return showTimePicker(
      context: context,
      initialTime:
          initial ??
          TimeOfDay(hour: hours.firstHour.clamp(0, 23).toInt(), minute: 0),
      helpText: help,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
  }

  Future<void> _pickStart() async {
    final picked = await _pickTime(_startTime, 'Waktu Mulai');
    if (picked == null) return;
    setState(() {
      _startTime = picked;
      _submitError = null;
      final startMin = picked.hour * 60 + picked.minute;
      final endMin = _endTime == null
          ? -1
          : _endTime!.hour * 60 + _endTime!.minute;
      if (endMin <= startMin && startMin + 60 <= 23 * 60 + 59) {
        final next = startMin + 60;
        _endTime = TimeOfDay(hour: next ~/ 60, minute: next % 60);
      }
      _syncControllers();
    });
  }

  Future<void> _pickEnd() async {
    final picked = await _pickTime(_endTime, 'Waktu Selesai');
    if (picked == null) return;
    setState(() {
      _endTime = picked;
      _submitError = null;
      _syncControllers();
    });
  }

  Future<void> _review() async {
    FocusScope.of(context).unfocus();
    final fieldsValid = _formKey.currentState!.validate();
    if (!fieldsValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pengajuan belum dapat dikirim. Periksa kembali kolom yang wajib diisi.',
          ),
        ),
      );
      return;
    }
    final issue = _scheduleIssue;
    if (issue != null) {
      setState(() => _submitError = issue);
      return;
    }
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ReviewSheet(
        lab: _lab,
        profile: _profile,
        start: _start!,
        end: _end!,
        title: _titleC.text.trim(),
        purpose: _purposeC.text.trim(),
        participants: int.parse(_participantsC.text.trim()),
      ),
    );
    if (confirmed != true || !mounted) return;
    await _submit();
  }

  Future<void> _submit() async {
    final start = _start!;
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      await _booking.submit(
        lab: _lab,
        profile: _profile,
        title: _titleC.text.trim(),
        purpose: _purposeC.text.trim(),
        participants: int.parse(_participantsC.text.trim()),
        start: start,
        end: _end!,
      );
      if (!mounted) return;
      Navigator.pop(context, start);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = _readableError(e);
      });
    }
  }

  String _readableError(Object e) {
    if (e is FirebaseException && e.code == 'permission-denied') {
      return 'Pengajuan ditolak oleh Firestore (izin akses). '
          'Periksa Security Rules koleksi reservations.';
    }
    final text = e.toString();
    return text.startsWith('Exception: ')
        ? text.substring('Exception: '.length)
        : 'Pengajuan gagal dikirim. Periksa koneksi lalu coba lagi.';
  }

  /// Jadwal yang sudah terpakai pada tanggal terpilih (disetujui/blokir) +
  /// pengajuan milik sendiri yang masih menunggu.
  List<ReservationModel> get _daySchedule {
    final d = _date;
    if (d == null) return const [];
    final map = <String, ReservationModel>{};
    for (final r in _labSchedule) {
      if (BookingValidator.isBlocking(r)) map[r.reservationId] = r;
    }
    for (final r in _mine) {
      if (r.labId == _lab.labId && r.status == 'pending') {
        map[r.reservationId] = r;
      }
    }
    final dayStart = DateId.dateOnly(d);
    final dayEnd = DateId.addDays(dayStart, 1);
    final list =
        map.values
            .where(
              (r) => BookingValidator.overlaps(
                r.startTime,
                r.endTime,
                dayStart,
                dayEnd,
              ),
            )
            .toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final issue = _scheduleIssue;
    final hours = _hours;
    return Scaffold(
      appBar: AppBar(title: const Text('Ajukan Peminjaman')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _LabSummary(lab: _lab, hours: hours),
                  const SizedBox(height: 24),
                  const _SectionTitle('Jadwal'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _dateC,
                    readOnly: true,
                    onTap: _pickDate,
                    decoration: const InputDecoration(
                      labelText: 'Pilih Tanggal *',
                      hintText: 'Ketuk untuk memilih tanggal',
                      prefixIcon: Icon(Icons.event_outlined),
                    ),
                    validator: (_) =>
                        _date == null ? 'Pilih tanggal peminjaman.' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _startC,
                          readOnly: true,
                          onTap: _pickStart,
                          decoration: const InputDecoration(
                            labelText: 'Waktu Mulai *',
                            prefixIcon: Icon(Icons.schedule_outlined),
                          ),
                          validator: (_) =>
                              _startTime == null ? 'Pilih jam mulai.' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _endC,
                          readOnly: true,
                          onTap: _pickEnd,
                          decoration: const InputDecoration(
                            labelText: 'Waktu Selesai *',
                            prefixIcon: Icon(Icons.schedule_outlined),
                          ),
                          validator: (_) =>
                              _endTime == null ? 'Pilih jam selesai.' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _ScheduleFeedback(
                    date: _date,
                    daySchedule: _daySchedule,
                    issue: issue,
                    ready: _start != null && _end != null,
                    loaded: _scheduleLoaded,
                    failed: _scheduleFailed,
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle('Detail kegiatan'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _titleC,
                    textCapitalization: TextCapitalization.sentences,
                    maxLength: 60,
                    decoration: const InputDecoration(
                      labelText: 'Mata Kuliah / Kegiatan *',
                      hintText: 'Contoh: Praktikum Basis Data',
                      prefixIcon: Icon(Icons.school_outlined),
                    ),
                    validator: (v) => (v ?? '').trim().length < 3
                        ? 'Isi nama mata kuliah atau kegiatan (min. 3 huruf).'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _purposeC,
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Tujuan Penggunaan *',
                      hintText: 'Jelaskan singkat apa yang akan dikerjakan',
                      alignLabelWithHint: true,
                    ),
                    validator: (v) => (v ?? '').trim().length < 10
                        ? 'Jelaskan tujuan penggunaan (min. 10 karakter).'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _participantsC,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() => _submitError = null),
                    decoration: InputDecoration(
                      labelText: 'Jumlah Peserta *',
                      helperText: _lab.capacity > 0
                          ? 'Kapasitas laboratorium ${_lab.capacity} orang'
                          : null,
                      prefixIcon: const Icon(Icons.groups_outlined),
                    ),
                    validator: (v) => BookingValidator.validateParticipants(
                      raw: v ?? '',
                      lab: _lab,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle('Data pemohon'),
                  const SizedBox(height: 12),
                  _ApplicantCard(profile: _profile),
                  const SizedBox(height: 24),
                  if (_submitError != null) ...[
                    _Banner(
                      icon: Icons.error_outline,
                      text: _submitError!,
                      background: AppTheme.dangerSoft,
                      foreground: AppTheme.danger,
                    ),
                    const SizedBox(height: 16),
                  ],
                  ElevatedButton(
                    onPressed: _submitting ? null : _review,
                    child: _submitting
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text('Mengirim...'),
                            ],
                          )
                        : const Text('Tinjau Pengajuan'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '* wajib diisi. Pengajuan baru berlaku setelah disetujui asisten laboratorium.',
                    style: TextStyle(color: AppTheme.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
  );
}

class _LabSummary extends StatelessWidget {
  const _LabSummary({required this.lab, required this.hours});
  final LaboratoryModel lab;
  final OperationalHours hours;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.soft,
      borderRadius: BorderRadius.circular(13),
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
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                lab.building,
                style: const TextStyle(color: AppTheme.muted, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                hours.isDefined
                    ? 'Jam operasional ${hours.label}'
                    : 'Jam operasional belum ditentukan',
                style: const TextStyle(color: AppTheme.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ScheduleFeedback extends StatelessWidget {
  const _ScheduleFeedback({
    required this.date,
    required this.daySchedule,
    required this.issue,
    required this.ready,
    required this.loaded,
    required this.failed,
  });

  final DateTime? date;
  final List<ReservationModel> daySchedule;
  final String? issue;
  final bool ready;
  final bool loaded;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    if (date == null) {
      return const Text(
        'Pilih tanggal untuk melihat jadwal yang sudah terpakai.',
        style: TextStyle(color: AppTheme.muted, fontSize: 13),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jadwal ${DateId.full(date!)}',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        if (failed)
          const _Banner(
            icon: Icons.wifi_off_rounded,
            text: 'Jadwal terbaru belum dapat dimuat. Bentrok tetap diperiksa saat pengajuan dikirim.',
            background: AppTheme.warningSoft,
            foreground: AppTheme.warning,
          )
        else if (!loaded)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Memuat jadwal...',
              style: TextStyle(color: AppTheme.muted, fontSize: 13),
            ),
          )
        else if (daySchedule.isEmpty)
          const Text(
            'Belum ada jadwal pada tanggal ini.',
            style: TextStyle(color: AppTheme.muted, fontSize: 13),
          )
        else
          for (final r in daySchedule)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 104,
                    child: Text(
                      DateId.range(r.startTime, r.endTime),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      r.title.isEmpty ? 'Terisi' : r.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ReservationStatusChip(status: r.status),
                ],
              ),
            ),
        if (issue != null) ...[
          const SizedBox(height: 10),
          _Banner(
            icon: Icons.error_outline,
            text: issue!,
            background: AppTheme.dangerSoft,
            foreground: AppTheme.danger,
          ),
        ] else if (ready && loaded && !failed) ...[
          const SizedBox(height: 10),
          const _Banner(
            icon: Icons.check_circle_outline,
            text: 'Tidak bentrok dengan jadwal yang sudah disetujui.',
            background: AppTheme.successSoft,
            foreground: Color(0xFF16845B),
          ),
        ],
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.text,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(13),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: foreground, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: TextStyle(color: foreground, fontSize: 13)),
        ),
      ],
    ),
  );
}

class _ApplicantCard extends StatelessWidget {
  const _ApplicantCard({required this.profile});
  final UserModel profile;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _SummaryRow(label: 'Nama', value: profile.name),
          _SummaryRow(label: 'NIM', value: profile.nim),
          _SummaryRow(label: 'Kelas', value: profile.className),
          _SummaryRow(label: 'Email', value: profile.email),
          const SizedBox(height: 4),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Diambil otomatis dari profilmu.',
              style: TextStyle(color: AppTheme.muted, fontSize: 12),
            ),
          ),
        ],
      ),
    ),
  );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: const TextStyle(color: AppTheme.muted, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '-' : value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ],
    ),
  );
}

class _ReviewSheet extends StatelessWidget {
  const _ReviewSheet({
    required this.lab,
    required this.profile,
    required this.start,
    required this.end,
    required this.title,
    required this.purpose,
    required this.participants,
  });

  final LaboratoryModel lab;
  final UserModel profile;
  final DateTime start;
  final DateTime end;
  final String title;
  final String purpose;
  final int participants;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tinjau Pengajuan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'Pastikan data sudah benar. Pengajuan akan diperiksa asisten laboratorium.',
            style: TextStyle(color: AppTheme.muted, fontSize: 13),
          ),
          const SizedBox(height: 18),
          _SummaryRow(label: 'Laboratorium', value: lab.name),
          _SummaryRow(label: 'Tanggal', value: DateId.full(start)),
          _SummaryRow(label: 'Jam', value: DateId.range(start, end)),
          _SummaryRow(label: 'Kegiatan', value: title),
          _SummaryRow(label: 'Tujuan', value: purpose),
          _SummaryRow(label: 'Peserta', value: '$participants orang'),
          _SummaryRow(
            label: 'Pemohon',
            value: '${profile.name} (${profile.nim})',
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    foregroundColor: AppTheme.deep,
                    side: const BorderSide(color: AppTheme.outline),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Kembali'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Kirim Pengajuan'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

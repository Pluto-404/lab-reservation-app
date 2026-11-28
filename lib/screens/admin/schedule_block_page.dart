import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../models/laboratory_model.dart';
import '../../models/reservation_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/booking_validator.dart';
import '../../utils/date_id.dart';
import '../../utils/schedule_block_helper.dart';
import '../../widgets/info_state.dart';
import '../../widgets/reservation_status_chip.dart';

/// Halaman Admin untuk memblokir jadwal laboratorium
/// (praktikum mata kuliah reguler atau pemeliharaan berkala).
class ScheduleBlockPage extends StatefulWidget {
  const ScheduleBlockPage({
    super.key,
    this.showAppBar = true,
  });

  final bool showAppBar;

  @override
  State<ScheduleBlockPage> createState() => _ScheduleBlockPageState();
}

class _ScheduleBlockPageState extends State<ScheduleBlockPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _purposeController = TextEditingController();
  final _searchController = TextEditingController();

  final FirestoreService _firestoreService = FirestoreService();
  late final Stream<List<LaboratoryModel>> _laboratoriesStream;
  late final Stream<List<ReservationModel>> _reservationsStream;

  int _selectedTab = 0; // 0 = Buat Blokir, 1 = Jadwal Diblokir

  // Form state
  String? _selectedLabId;
  String _category = 'Kelas Reguler';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  bool _isRecurring = false;
  int _repeatWeeks = 4;
  bool _isSaving = false;

  // List filter & pagination state
  BlockTimeFilter _timeFilter = BlockTimeFilter.upcoming;
  String? _filterLabId;
  int _visibleLimit = 10;
  final Set<String> _deletingIds = {};
  final Set<String> _deletingGroups = {};

  @override
  void initState() {
    super.initState();
    _laboratoriesStream = _firestoreService.getActiveLaboratories();
    _reservationsStream = _firestoreService.getAllReservations();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _purposeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _chooseDate() async {
    final today = DateId.dateOnly(DateTime.now());
    final initial = _selectedDate.isBefore(today) ? today : _selectedDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _chooseTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.danger),
    );
  }

  Future<void> _saveBlock(List<LaboratoryModel> laboratories) async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    final adminId = FirebaseAuth.instance.currentUser?.uid;
    if (adminId == null) {
      _showError('Admin belum login. Silakan login kembali.');
      return;
    }

    final matched = laboratories.where((l) => l.labId == _selectedLabId);
    if (matched.isEmpty) {
      _showError('Pilih laboratorium terlebih dahulu.');
      return;
    }
    final lab = matched.first;

    final startDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    final endDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    if (!endDateTime.isAfter(startDateTime)) {
      _showError('Jam selesai harus setelah jam mulai.');
      return;
    }
    if (startDateTime.isBefore(DateTime.now())) {
      _showError('Waktu blokir tidak boleh di masa lalu.');
      return;
    }

    final hours = OperationalHours.parse(lab.operationalHours);
    if (hours.isDefined) {
      final startMin = startDateTime.hour * 60 + startDateTime.minute;
      final endMin = endDateTime.hour * 60 + endDateTime.minute;
      if (startMin < hours.startMinute || endMin > hours.endMinute) {
        _showError(
          'Jadwal di luar jam operasional laboratorium (${hours.label}).',
        );
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      final purposeText = _purposeController.text.trim();
      final fullPurpose =
          purposeText.isEmpty ? _category : '$_category: $purposeText';

      final int createdCount = _isRecurring
          ? await _firestoreService.blockRecurringMaintenanceSchedule(
              labId: lab.labId,
              labName: lab.name,
              adminId: adminId,
              title: _titleController.text.trim(),
              purpose: fullPurpose,
              firstStartTime: startDateTime,
              firstEndTime: endDateTime,
              repeatWeeks: _repeatWeeks,
            )
          : await () async {
              await _firestoreService.blockMaintenanceSchedule(
                labId: lab.labId,
                labName: lab.name,
                adminId: adminId,
                title: _titleController.text.trim(),
                purpose: fullPurpose,
                startTime: startDateTime,
                endTime: endDateTime,
              );
              return 1;
            }();

      if (!mounted) return;
      _titleController.clear();
      _purposeController.clear();
      setState(() {
        _selectedLabId = null;
        _selectedDate = DateTime.now();
        _startTime = const TimeOfDay(hour: 8, minute: 0);
        _endTime = const TimeOfDay(hour: 10, minute: 0);
        _isRecurring = false;
        _repeatWeeks = 4;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            createdCount > 1
                ? '$createdCount jadwal rutin mingguan berhasil diblokir.'
                : 'Jadwal berhasil diblokir.',
          ),
          backgroundColor: AppTheme.success,
          action: SnackBarAction(
            label: 'Lihat Daftar',
            textColor: Colors.white,
            onPressed: () {
              if (mounted) setState(() => _selectedTab = 1);
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmDeleteSingle(ReservationModel block) async {
    if (_deletingIds.contains(block.reservationId)) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Blokir Jadwal?'),
        content: Text(
          'Slot "${block.title}" pada ${block.labName} '
          '(${DateId.short(block.startTime)}, '
          '${DateId.range(block.startTime, block.endTime)}) '
          'akan dibuka kembali untuk peminjaman.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus Blokir'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _deletingIds.add(block.reservationId));
    try {
      await _firestoreService.deleteMaintenanceBlock(block.reservationId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Blokir jadwal berhasil dihapus.')),
      );
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _deletingIds.remove(block.reservationId));
      }
    }
  }

  Future<void> _confirmDeleteGroup(ScheduleBlockGroup group) async {
    if (_deletingGroups.contains(group.groupKey)) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Semua Jadwal Seri?'),
        content: Text(
          'Sebanyak ${group.count} pertemuan untuk "${group.title}" di '
          '${group.labName} (${group.dateRangeLabel}) akan dihapus dan dibuka kembali.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Hapus ${group.count} Jadwal'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _deletingGroups.add(group.groupKey));
    try {
      final ids = group.items.map((e) => e.reservationId).toList();
      final deleted = await _firestoreService.deleteMaintenanceBlocks(ids);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$deleted jadwal blokir berhasil dihapus.')),
      );
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _deletingGroups.remove(group.groupKey));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bodyContent = StreamBuilder<List<LaboratoryModel>>(
      stream: _laboratoriesStream,
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
            text: 'Gagal memuat daftar laboratorium.',
            subtext: '${labSnapshot.error}',
          );
        }

        final laboratories = labSnapshot.data ?? [];

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Blokir Jadwal Laboratorium',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Kunci slot waktu untuk kelas praktikum reguler atau pemeliharaan rutin.',
              style: TextStyle(color: AppTheme.muted),
            ),
            const SizedBox(height: 20),

            SegmentedButton<int>(
              segments: const [
                ButtonSegment<int>(
                  value: 0,
                  icon: Icon(Icons.add_circle_outline, size: 18),
                  label: Text('Buat Blokir'),
                ),
                ButtonSegment<int>(
                  value: 1,
                  icon: Icon(Icons.event_busy_outlined, size: 18),
                  label: Text('Jadwal Diblokir'),
                ),
              ],
              selected: {_selectedTab},
              onSelectionChanged: (selection) {
                setState(() => _selectedTab = selection.first);
              },
            ),
            const SizedBox(height: 20),

            if (_selectedTab == 0)
              _buildFormCard(laboratories)
            else
              _buildBlockListSection(laboratories),
          ],
        );
      },
    );

    if (!widget.showAppBar) {
      return PageWidth(maxWidth: 800, child: bodyContent);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Blokir Jadwal')),
      body: PageWidth(maxWidth: 800, child: bodyContent),
    );
  }

  Widget _buildFormCard(List<LaboratoryModel> laboratories) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Form Blokir Jadwal',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Kategori Blokir',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['Kelas Reguler', 'Pemeliharaan / Maintenance']
                    .map((cat) {
                  return ChoiceChip(
                    label: Text(cat),
                    selected: _category == cat,
                    onSelected: (_) => setState(() => _category = cat),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text(
                'Laboratorium',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedLabId,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.apartment_outlined),
                  hintText: 'Pilih laboratorium',
                ),
                items: laboratories.map((lab) {
                  return DropdownMenuItem<String>(
                    value: lab.labId,
                    child: Text(lab.name),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedLabId = value),
                validator: (value) =>
                    value == null ? 'Pilih laboratorium terlebih dahulu.' : null,
              ),
              const SizedBox(height: 16),
              _field(
                controller: _titleController,
                label: 'Judul Agenda / Blokir',
                hint: _category == 'Kelas Reguler'
                    ? 'Contoh: Praktikum Pemrograman Web'
                    : 'Contoh: Pemeliharaan Jaringan & PC',
                icon: Icons.event_busy_outlined,
              ),
              const SizedBox(height: 16),
              const Text(
                'Tanggal Blokir',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: _chooseDate,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                icon: const Icon(Icons.calendar_today_outlined, size: 20),
                label: Text(
                  DateId.full(_selectedDate),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: AppTheme.ink,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Waktu Blokir',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _chooseTime(isStart: true),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      icon: const Icon(Icons.access_time, size: 18),
                      label: Text(
                        DateId.hm(_startTime.hour, _startTime.minute),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.ink,
                        ),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('s/d', style: TextStyle(color: AppTheme.muted)),
                  ),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _chooseTime(isStart: false),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      icon: const Icon(Icons.access_time, size: 18),
                      label: Text(
                        DateId.hm(_endTime.hour, _endTime.minute),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.ink,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _field(
                controller: _purposeController,
                label: 'Keterangan Tambahan',
                hint: 'Contoh: Kelas PTIK A atau servis rutin unit PC',
                icon: Icons.description_outlined,
                maxLines: 2,
                requiredField: false,
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.canvas,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: AppTheme.outline),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      value: _isRecurring,
                      onChanged: (value) =>
                          setState(() => _isRecurring = value),
                      title: const Text(
                        'Ulangi rutin setiap minggu',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppTheme.ink,
                        ),
                      ),
                      subtitle: const Text(
                        'Cocok untuk jadwal praktikum mata kuliah reguler.',
                        style: TextStyle(fontSize: 12, color: AppTheme.muted),
                      ),
                    ),
                    if (_isRecurring)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownButtonFormField<int>(
                              initialValue: _repeatWeeks,
                              decoration: const InputDecoration(
                                labelText: 'Durasi Perulangan',
                                prefixIcon: Icon(Icons.repeat_outlined),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 2,
                                  child: Text('2 Minggu'),
                                ),
                                DropdownMenuItem(
                                  value: 4,
                                  child: Text('4 Minggu (1 Bulan)'),
                                ),
                                DropdownMenuItem(
                                  value: 8,
                                  child: Text('8 Minggu (2 Bulan)'),
                                ),
                                DropdownMenuItem(
                                  value: 12,
                                  child: Text('12 Minggu (3 Bulan)'),
                                ),
                                DropdownMenuItem(
                                  value: 16,
                                  child: Text('16 Minggu (1 Semester)'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _repeatWeeks = value);
                                }
                              },
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Akan memblokir $_repeatWeeks slot mingguan mulai '
                              '${DateId.short(_selectedDate)} hingga '
                              '${DateId.short(DateId.addDays(_selectedDate, (_repeatWeeks - 1) * 7))}.',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.deep,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : () => _saveBlock(laboratories),
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.lock_clock_outlined),
                label: Text(
                  _isSaving ? 'Menyimpan...' : 'Simpan Blokir Jadwal',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlockListSection(List<LaboratoryModel> laboratories) {
    return StreamBuilder<List<ReservationModel>>(
      stream: _reservationsStream,
      builder: (context, resSnapshot) {
        if (resSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (resSnapshot.hasError) {
          return InfoState(
            icon: Icons.error_outline,
            text: 'Gagal memuat daftar blokir jadwal.',
            subtext: '${resSnapshot.error}',
          );
        }

        final filtered = ScheduleBlockHelper.filterBlocks(
          reservations: resSnapshot.data ?? [],
          timeFilter: _timeFilter,
          labId: _filterLabId,
          query: _searchController.text,
        );
        final groups = ScheduleBlockHelper.groupBlocks(filtered);
        final visibleGroups = groups.take(_visibleLimit).toList();
        final remainingCount = groups.length - visibleGroups.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: BlockTimeFilter.values.map((filter) {
                return ChoiceChip(
                  label: Text(filter.label),
                  selected: _timeFilter == filter,
                  onSelected: (_) => setState(() {
                    _timeFilter = filter;
                    _visibleLimit = 10;
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() => _visibleLimit = 10),
              decoration: InputDecoration(
                hintText: 'Cari judul agenda atau keterangan...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _visibleLimit = 10);
                        },
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _filterLabId,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.apartment_outlined),
                labelText: 'Filter Laboratorium',
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Semua Laboratorium'),
                ),
                ...laboratories.map(
                  (lab) => DropdownMenuItem<String?>(
                    value: lab.labId,
                    child: Text(lab.name),
                  ),
                ),
              ],
              onChanged: (value) => setState(() {
                _filterLabId = value;
                _visibleLimit = 10;
              }),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Daftar Jadwal Diblokir',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
                Text(
                  '${groups.length} grup (${filtered.length} slot)',
                  style: const TextStyle(color: AppTheme.muted, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (groups.isEmpty)
              const InfoState(
                icon: Icons.event_available_outlined,
                text: 'Tidak ada jadwal blokir pada filter ini.',
                subtext:
                    'Ubah filter waktu, laboratorium, atau buat blokir baru.',
              )
            else ...[
              for (final group in visibleGroups)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: group.isRecurring
                      ? _buildRecurringGroupCard(group)
                      : _buildSingleBlockCard(group.first),
                ),
              if (remainingCount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _visibleLimit += 10),
                    icon: const Icon(Icons.expand_more),
                    label: Text(
                      'Tampilkan lebih banyak (sisa $remainingCount)',
                    ),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildRecurringGroupCard(ScheduleBlockGroup group) {
    final deletingGroup = _deletingGroups.contains(group.groupKey);

    return Card(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.soft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.repeat, color: AppTheme.deep, size: 22),
          ),
          title: Text(
            group.title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppTheme.ink,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${group.labName} • ${group.recurringScheduleLabel}',
                  style: const TextStyle(
                    color: AppTheme.deep,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2F6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${group.count} jadwal',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.ink,
                        ),
                      ),
                    ),
                    Text(
                      group.dateRangeLabel,
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          children: [
            if (group.purpose.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  group.purpose,
                  style: const TextStyle(color: AppTheme.muted, fontSize: 12),
                ),
              ),
              const SizedBox(height: 10),
            ],
            const Divider(height: 1, color: AppTheme.outline),
            for (final item in group.items) ...[
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: AppTheme.muted,
                ),
                title: Text(
                  DateId.full(item.startTime),
                  style: const TextStyle(fontSize: 13, color: AppTheme.ink),
                ),
                subtitle: Text(
                  '${DateId.range(item.startTime, item.endTime)} WIB',
                  style: const TextStyle(fontSize: 12, color: AppTheme.muted),
                ),
                trailing: _deletingIds.contains(item.reservationId)
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        tooltip: 'Hapus tanggal ini',
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: AppTheme.danger,
                        ),
                        onPressed: deletingGroup
                            ? null
                            : () => _confirmDeleteSingle(item),
                      ),
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed:
                    deletingGroup ? null : () => _confirmDeleteGroup(group),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.danger,
                  side: const BorderSide(color: AppTheme.danger),
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                icon: deletingGroup
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_sweep_outlined, size: 16),
                label: Text(
                  deletingGroup
                      ? 'Menghapus...'
                      : 'Hapus Semua (${group.count})',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleBlockCard(ReservationModel block) {
    final deleting = _deletingIds.contains(block.reservationId);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    color: AppTheme.muted,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        block.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppTheme.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${block.labName} • ${DateId.short(block.startTime)}',
                        style: const TextStyle(
                          color: AppTheme.deep,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${DateId.range(block.startTime, block.endTime)} WIB',
                        style: const TextStyle(
                          color: AppTheme.muted,
                          fontSize: 12,
                        ),
                      ),
                      if (block.purpose.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          block.purpose,
                          style: const TextStyle(
                            color: AppTheme.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const ReservationStatusChip(
                  status: 'maintenance_block',
                  compact: true,
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1, color: AppTheme.outline),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: deleting ? null : () => _confirmDeleteSingle(block),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.danger,
                  side: const BorderSide(color: AppTheme.danger),
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                icon: deleting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline, size: 16),
                label: Text(
                  deleting ? 'Menghapus...' : 'Hapus Blokir',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    bool requiredField = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: AppTheme.ink,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
          ),
          validator: requiredField
              ? (value) => value == null || value.trim().isEmpty
                  ? '$label wajib diisi.'
                  : null
              : null,
        ),
      ],
    );
  }
}

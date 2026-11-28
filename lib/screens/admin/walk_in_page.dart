import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../models/laboratory_model.dart';
import '../../models/reservation_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/booking_validator.dart';
import '../../widgets/info_state.dart';
import '../../widgets/reservation_status_chip.dart';

class WalkInPage extends StatefulWidget {
  const WalkInPage({
    super.key,
    this.showAppBar = true,
  });

  final bool showAppBar;

  @override
  State<WalkInPage> createState() => _WalkInPageState();
}

class _WalkInPageState extends State<WalkInPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _nimController = TextEditingController();
  final _purposeController = TextEditingController();

  final FirestoreService _firestoreService = FirestoreService();
  late final Stream<List<LaboratoryModel>> _laboratoriesStream;
  late final Stream<List<ReservationModel>> _reservationsStream;

  String? _selectedLaboratoryId;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _laboratoriesStream = _firestoreService.getActiveLaboratories();
    _reservationsStream = _firestoreService.getAllReservations();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nimController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} • '
        '${_formatTime(TimeOfDay.fromDateTime(dateTime))}';
  }

  Future<void> _chooseDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateUtils.dateOnly(DateTime.now()),
      lastDate: DateTime(2035),
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _chooseTime({required bool isStart}) async {
    final time = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );

    if (time != null) {
      setState(() {
        if (isStart) {
          _startTime = time;
        } else {
          _endTime = time;
        }
      });
    }
  }

  Future<void> _saveBooking(
    List<LaboratoryModel> laboratories,
  ) async {
    if (!_formKey.currentState!.validate()) return;

    final adminId = FirebaseAuth.instance.currentUser?.uid;

    if (adminId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin belum login. Silakan login kembali.'),
        ),
      );
      return;
    }

    final selectedLabs = laboratories.where(
      (lab) => lab.labId == _selectedLaboratoryId,
    );

    if (selectedLabs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Laboratorium belum dipilih.'),
        ),
      );
      return;
    }

    final laboratory = selectedLabs.first;

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jam selesai harus setelah jam mulai.'),
        ),
      );
      return;
    }

    if (startDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Waktu penggunaan tidak boleh di masa lalu.'),
        ),
      );
      return;
    }

    final hours = OperationalHours.parse(laboratory.operationalHours);
    if (hours.isDefined) {
      final startMin = startDateTime.hour * 60 + startDateTime.minute;
      final endMin = endDateTime.hour * 60 + endDateTime.minute;
      if (startMin < hours.startMinute || endMin > hours.endMinute) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Jadwal di luar jam operasional laboratorium (${hours.label}).',
            ),
            backgroundColor: AppTheme.danger,
          ),
        );
        return;
      }
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final reservation = ReservationModel(
        reservationId: '',
        labId: laboratory.labId,
        labName: laboratory.name,
        userId: adminId,
        studentName: _nameController.text.trim(),
        studentNim: _nimController.text.trim(),
        studentClass: '-',
        title: 'Peminjaman Langsung',
        purpose: _purposeController.text.trim(),
        participants: 1,
        startTime: startDateTime,
        endTime: endDateTime,
        type: 'walk_in',
        status: 'approved',
        adminId: adminId,
        createdAt: DateTime.now(),
      );

      final reservationId = await _firestoreService.createReservation(reservation);

      if (!mounted) return;

      _nameController.clear();
      _nimController.clear();
      _purposeController.clear();

      setState(() {
        _selectedLaboratoryId = null;
        _selectedDate = DateTime.now();
        _startTime = const TimeOfDay(hour: 8, minute: 0);
        _endTime = const TimeOfDay(hour: 10, minute: 0);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Peminjaman langsung berhasil disimpan ($reservationId).'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: AppTheme.danger,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
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
            text: 'Gagal memuat laboratorium.',
            subtext: '${labSnapshot.error}',
          );
        }

        final laboratories = labSnapshot.data ?? [];

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Peminjaman Langsung (Walk-in)',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Catat penggunaan laboratorium secara langsung di tempat oleh admin.',
              style: TextStyle(color: AppTheme.muted),
            ),
            const SizedBox(height: 24),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Form Peminjaman',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.ink,
                        ),
                      ),
                      const SizedBox(height: 18),

                      _buildTextField(
                        controller: _nameController,
                        label: 'Nama Peminjam',
                        hint: 'Masukkan nama peminjam',
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _nimController,
                        label: 'NIM Mahasiswa',
                        hint: 'Masukkan NIM peminjam',
                        icon: Icons.badge_outlined,
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
                        initialValue: _selectedLaboratoryId,
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
                        onChanged: (value) {
                          setState(() {
                            _selectedLaboratoryId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Pilih laboratorium terlebih dahulu.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Tanggal Penggunaan',
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
                          _formatDate(_selectedDate),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                            color: AppTheme.ink,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Waktu Penggunaan',
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
                                _formatTime(_startTime),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.ink,
                                ),
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              's/d',
                              style: TextStyle(color: AppTheme.muted),
                            ),
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
                                _formatTime(_endTime),
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

                      _buildTextField(
                        controller: _purposeController,
                        label: 'Keperluan',
                        hint: 'Masukkan tujuan atau kegiatan di lab...',
                        icon: Icons.description_outlined,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 24),

                      ElevatedButton.icon(
                        onPressed: _isSaving
                            ? null
                            : () => _saveBooking(laboratories),
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          _isSaving
                              ? 'Menyimpan...'
                              : 'Simpan Peminjaman Langsung',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            const Text(
              'Riwayat Peminjaman Langsung',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(height: 12),

            StreamBuilder<List<ReservationModel>>(
              stream: _reservationsStream,
              builder: (context, reservationSnapshot) {
                if (reservationSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (reservationSnapshot.hasError) {
                  return InfoState(
                    icon: Icons.error_outline,
                    text: 'Gagal memuat riwayat.',
                    subtext: '${reservationSnapshot.error}',
                  );
                }

                final history = (reservationSnapshot.data ?? [])
                    .where((booking) => booking.type == 'walk_in')
                    .toList();

                if (history.isEmpty) {
                  return const InfoState(
                    icon: Icons.history_outlined,
                    text: 'Belum ada riwayat peminjaman langsung.',
                    subtext: 'Peminjaman langsung yang dicatat akan muncul di sini.',
                  );
                }

                return Column(
                  children: history.map((booking) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppTheme.soft,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.meeting_room_outlined,
                                  color: AppTheme.deep,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            booking.studentName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                              color: AppTheme.ink,
                                            ),
                                          ),
                                        ),
                                        ReservationStatusChip(
                                          status: booking.status,
                                          compact: true,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${booking.labName} • ${_formatDateTime(booking.startTime)}',
                                      style: const TextStyle(
                                        color: AppTheme.deep,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'NIM: ${booking.studentNim} | Keperluan: ${booking.purpose}',
                                      style: const TextStyle(
                                        color: AppTheme.muted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
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
        title: const Text('Peminjaman Langsung'),
      ),
      body: PageWidth(maxWidth: 800, child: bodyContent),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
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
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '$label wajib diisi.';
            }
            return null;
          },
        ),
      ],
    );
  }
}

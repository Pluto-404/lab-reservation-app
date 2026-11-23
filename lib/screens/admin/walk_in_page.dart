
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../models/laboratory_model.dart';
import '../../models/reservation_model.dart';
import '../../services/firestore_service.dart';

class WalkInPage extends StatefulWidget {
  const WalkInPage({super.key});

  @override
  State<WalkInPage> createState() => _WalkInPageState();
}

class _WalkInPageState extends State<WalkInPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _nimController = TextEditingController();
  final _purposeController = TextEditingController();

  final FirestoreService _firestoreService = FirestoreService();

  String? _selectedLaboratoryId;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);

  bool _isSaving = false;

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
    return '${time.hour.toString().padLeft(2, '0')}.'
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
          content: Text('Laboratorium tidak ditemukan.'),
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

      await _firestoreService.createReservation(reservation);

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
        const SnackBar(
          content: Text('Peminjaman langsung berhasil disimpan.'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Peminjaman Langsung'),
      ),
      body: StreamBuilder<List<LaboratoryModel>>(
        stream: _firestoreService.getActiveLaboratories(),
        builder: (context, labSnapshot) {
          if (labSnapshot.hasError) {
            return Center(
              child: Text(
                'Gagal memuat laboratorium: ${labSnapshot.error}',
              ),
            );
          }

          if (!labSnapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final laboratories = labSnapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 850),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pencatatan Peminjaman Langsung',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.ink,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Catat penggunaan laboratorium secara langsung oleh admin.',
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
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.ink,
                                ),
                              ),

                              const SizedBox(height: 20),

                              _buildTextField(
                                controller: _nameController,
                                label: 'Nama Peminjam',
                                hint: 'Masukkan nama peminjam',
                                icon: Icons.person_outline,
                              ),

                              const SizedBox(height: 16),

                              _buildTextField(
                                controller: _nimController,
                                label: 'NIM',
                                hint: 'Masukkan NIM peminjam',
                                icon: Icons.badge_outlined,
                              ),

                              const SizedBox(height: 16),

                              const Text(
                                'Laboratorium',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.ink,
                                ),
                              ),

                              const SizedBox(height: 8),

                              DropdownButtonFormField<String>(
                                initialValue: _selectedLaboratoryId,
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.science_outlined,
                                  ),
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
                                    return 'Pilih laboratorium.';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 16),

                              const Text(
                                'Tanggal Penggunaan',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.ink,
                                ),
                              ),

                              const SizedBox(height: 8),

                              OutlinedButton.icon(
                                onPressed: _chooseDate,
                                icon: const Icon(Icons.calendar_today),
                                label: Text(_formatDate(_selectedDate)),
                              ),

                              const SizedBox(height: 16),

                              const Text(
                                'Waktu Penggunaan',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.ink,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () =>
                                          _chooseTime(isStart: true),
                                      icon: const Icon(
                                        Icons.access_time,
                                      ),
                                      label: Text(
                                        _formatTime(_startTime),
                                      ),
                                    ),
                                  ),

                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    child: Text('sampai'),
                                  ),

                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () =>
                                          _chooseTime(isStart: false),
                                      icon: const Icon(
                                        Icons.access_time,
                                      ),
                                      label: Text(
                                        _formatTime(_endTime),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              _buildTextField(
                                controller: _purposeController,
                                label: 'Keperluan',
                                hint: 'Masukkan keperluan penggunaan lab',
                                icon: Icons.description_outlined,
                                maxLines: 3,
                              ),

                              const SizedBox(height: 24),

                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: _isSaving
                                      ? null
                                      : () => _saveBooking(laboratories),
                                  icon: _isSaving
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.save_outlined),
                                  label: Text(
                                    _isSaving
                                        ? 'Menyimpan...'
                                        : 'Simpan Peminjaman',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    const Text(
                      'Riwayat Peminjaman Langsung',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.ink,
                      ),
                    ),

                    const SizedBox(height: 14),

                    StreamBuilder<List<ReservationModel>>(
                      stream: _firestoreService.getAllReservations(),
                      builder: (context, reservationSnapshot) {
                        if (reservationSnapshot.hasError) {
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                'Gagal memuat riwayat: '
                                '${reservationSnapshot.error}',
                              ),
                            ),
                          );
                        }

                        if (!reservationSnapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final history = reservationSnapshot.data!
                            .where((booking) => booking.type == 'walk_in')
                            .toList();

                        if (history.isEmpty) {
                          return const Card(
                            child: Padding(
                              padding: EdgeInsets.all(28),
                              child: Center(
                                child: Text(
                                  'Belum ada riwayat peminjaman langsung.',
                                  style: TextStyle(
                                    color: AppTheme.muted,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: history.map((booking) {
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: AppTheme.soft,
                                  child: Icon(
                                    Icons.science_outlined,
                                    color: AppTheme.primary,
                                  ),
                                ),
                                title: Text(
                                  booking.studentName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    '${booking.labName}\n'
                                    '${_formatDateTime(booking.startTime)}'
                                    ' - ${_formatTime(TimeOfDay.fromDateTime(booking.endTime))}\n'
                                    'NIM: ${booking.studentNim}\n'
                                    'Keperluan: ${booking.purpose}',
                                  ),
                                ),
                                isThreeLine: true,
                              ),
                            );
                          }).toList(),
                        );
                      },
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
            color: AppTheme.ink,
          ),
        ),

        const SizedBox(height: 8),

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

import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../models/laboratory_model.dart';

class LaboratoryFormPage extends StatefulWidget {
  final LaboratoryModel? laboratory;

  const LaboratoryFormPage({
    super.key,
    this.laboratory,
  });

  @override
  State<LaboratoryFormPage> createState() =>
      _LaboratoryFormPageState();
}

class _LaboratoryFormPageState
    extends State<LaboratoryFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _buildingController;
  late final TextEditingController _capacityController;
  late final TextEditingController _facilitiesController;
  late final TextEditingController _hoursController;

  bool _isActive = true;

  bool get _isEditing => widget.laboratory != null;

  @override
  void initState() {
    super.initState();

    final lab = widget.laboratory;

    _nameController = TextEditingController(
      text: lab?.name ?? '',
    );

    _buildingController = TextEditingController(
      text: lab?.building ?? '',
    );

    _capacityController = TextEditingController(
      text: lab?.capacity.toString() ?? '',
    );

    _facilitiesController = TextEditingController(
      text: lab?.facilities.join(', ') ?? '',
    );

    _hoursController = TextEditingController(
      text: lab?.operationalHours ?? '',
    );

    _isActive = lab?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _buildingController.dispose();
    _capacityController.dispose();
    _facilitiesController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  void _saveLaboratory() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final oldLab = widget.laboratory;

    final laboratory = LaboratoryModel(
      labId: oldLab?.labId ??
          'LAB${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      building: _buildingController.text.trim(),
      capacity: int.parse(_capacityController.text.trim()),
      facilities: _facilitiesController.text
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(),
      operationalHours: _hoursController.text.trim(),
      isActive: _isActive,
      imageUrl: oldLab?.imageUrl,
    );

    Navigator.pop(context, laboratory);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing
              ? 'Edit Laboratorium'
              : 'Tambah Laboratorium',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 650,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isEditing
                        ? 'Perbarui Data Laboratorium'
                        : 'Form Laboratorium Baru',
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.ink,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Lengkapi informasi laboratorium berikut.',
                    style: TextStyle(
                      color: AppTheme.muted,
                    ),
                  ),

                  const SizedBox(height: 28),

                  _buildField(
                    controller: _nameController,
                    label: 'Nama Laboratorium',
                    hint: 'Contoh: Laboratorium Komputer A',
                    icon: Icons.science_outlined,
                  ),

                  const SizedBox(height: 18),

                  _buildField(
                    controller: _buildingController,
                    label: 'Lokasi Gedung',
                    hint: 'Contoh: Gedung E Lantai 2',
                    icon: Icons.location_on_outlined,
                  ),

                  const SizedBox(height: 18),

                  _buildField(
                    controller: _capacityController,
                    label: 'Kapasitas',
                    hint: 'Contoh: 35',
                    icon: Icons.people_outline,
                    isNumber: true,
                  ),

                  const SizedBox(height: 18),

                  _buildField(
                    controller: _facilitiesController,
                    label: 'Fasilitas Laboratorium',
                    hint: 'Komputer, Proyektor, AC, Wi-Fi',
                    icon: Icons.devices_outlined,
                    maxLines: 2,
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Pisahkan setiap fasilitas menggunakan koma.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.muted,
                    ),
                  ),

                  const SizedBox(height: 18),

                  _buildField(
                    controller: _hoursController,
                    label: 'Jam Operasional',
                    hint: 'Contoh: 08.00 - 16.00',
                    icon: Icons.access_time,
                  ),

                  const SizedBox(height: 22),

                  const Text(
                    'Status Laboratorium',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.ink,
                    ),
                  ),

                  const SizedBox(height: 8),

                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      _isActive ? 'Aktif' : 'Nonaktif',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      _isActive
                          ? 'Laboratorium dapat digunakan.'
                          : 'Laboratorium tidak dapat digunakan.',
                    ),
                    value: _isActive,
                    activeTrackColor: AppTheme.success,
                    onChanged: (value) {
                      setState(() {
                        _isActive = value;
                      });
                    },
                  ),

                  const SizedBox(height: 30),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Batal'),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _saveLaboratory,
                          icon: const Icon(Icons.save_outlined),
                          label: Text(
                            _isEditing ? 'Simpan Perubahan' : 'Simpan',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isNumber = false,
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
          keyboardType: isNumber
              ? TextInputType.number
              : TextInputType.text,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '$label wajib diisi.';
            }

            if (isNumber) {
              final number = int.tryParse(value.trim());

              if (number == null || number <= 0) {
                return 'Masukkan kapasitas berupa angka lebih dari 0.';
              }
            }

            return null;
          },
        ),
      ],
    );
  }
}

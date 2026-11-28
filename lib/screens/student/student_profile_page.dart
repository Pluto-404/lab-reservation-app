import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';

class StudentProfile extends StatefulWidget {
  const StudentProfile({
    super.key,
    required this.profile,
    required this.onUpdated,
  });

  final UserModel profile;
  final ValueChanged<UserModel> onUpdated;

  @override
  State<StudentProfile> createState() => _StudentProfileState();
}

class _StudentProfileState extends State<StudentProfile> {
  late final name = TextEditingController(text: widget.profile.name);
  late final nim = TextEditingController(text: widget.profile.nim);
  late final className = TextEditingController(text: widget.profile.className);
  late final cohort = TextEditingController(text: widget.profile.cohort);
  final form = GlobalKey<FormState>();
  bool editing = false;
  bool saving = false;

  @override
  void dispose() {
    name.dispose();
    nim.dispose();
    className.dispose();
    cohort.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate() || saving) return;
    setState(() => saving = true);
    try {
      await AuthService().updateAcademicProfile(
        name: name.text.trim(),
        nim: nim.text.trim(),
        className: className.text.trim(),
        cohort: cohort.text.trim(),
      );
      final updated = await AuthService().getCurrentUserProfile();
      if (updated != null) widget.onUpdated(updated);
      if (mounted) {
        setState(() => editing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menyimpan profil. Periksa akses Firestore.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget editor(String title, TextEditingController controller,
          {bool year = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: TextFormField(
          controller: controller,
          keyboardType: year ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(labelText: title),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return '$title wajib diisi';
            if (year && !RegExp(r'^\d{4}$').hasMatch(v.trim())) {
              return 'Masukkan tahun 4 digit';
            }
            return null;
          },
        ),
      );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 680;
          final veryCompact = constraints.maxHeight < 490;
          final horizontal = compact ? 20.0 : 24.0;
          final outerGap = compact ? 12.0 : 24.0;
          final lineGap = compact ? 6.0 : 10.0;
          final cardPadding = compact ? 12.0 : 19.0;

          final content = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Profil Mahasiswa',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 24),
              ),
              SizedBox(height: compact ? 3 : 7),
              const Text(
                'Identitas akademik untuk reservasi lab.',
                style: TextStyle(color: AppTheme.muted),
              ),
              SizedBox(height: outerGap),
              Container(
                padding: EdgeInsets.all(cardPadding),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7FC),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: compact ? 25 : 31,
                      backgroundColor: Colors.white,
                      backgroundImage: widget.profile.photoUrl != null &&
                              widget.profile.photoUrl!.isNotEmpty
                          ? NetworkImage(widget.profile.photoUrl!)
                          : null,
                      child: widget.profile.photoUrl == null ||
                              widget.profile.photoUrl!.isEmpty
                          ? Icon(
                              Icons.person_outline_rounded,
                              color: AppTheme.deep,
                              size: compact ? 29 : 34,
                            )
                          : null,
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.profile.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            widget.profile.email,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
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
              SizedBox(height: compact ? 15 : 27),
              if (!editing) ...[
                _ProfileLine('NIM', widget.profile.nim,
                    compact: compact, bottomGap: lineGap),
                _ProfileLine('Kelas', widget.profile.className,
                    compact: compact, bottomGap: lineGap),
                _ProfileLine('Angkatan', widget.profile.cohort,
                    compact: compact, bottomGap: lineGap),
                SizedBox(height: compact ? 7 : 16),
                OutlinedButton.icon(
                  onPressed: () => setState(() => editing = true),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit profil'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size.fromHeight(compact ? 44 : 50),
                  ),
                ),
              ] else
                Form(
                  key: form,
                  child: Column(
                    children: [
                      editor('Nama lengkap', name),
                      editor('NIM', nim),
                      editor('Kelas', className),
                      editor('Angkatan', cohort, year: true),
                      ElevatedButton(
                        onPressed: saving ? null : save,
                        child: Text(saving ? 'Menyimpan...' : 'Simpan perubahan'),
                      ),
                      TextButton(
                        onPressed: saving
                            ? null
                            : () {
                                setState(() {
                                  name.text = widget.profile.name;
                                  nim.text = widget.profile.nim;
                                  className.text = widget.profile.className;
                                  cohort.text = widget.profile.cohort;
                                  editing = false;
                                });
                              },
                        child: const Text('Batal'),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: compact ? 10 : 25),
              TextButton.icon(
                onPressed: () async {
                  await AuthService().signOut();
                },
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                label: const Text(
                  'Keluar dari akun',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          );

          final scrollable = editing ||
              veryCompact ||
              MediaQuery.viewInsetsOf(context).bottom > 0;
          return scrollable
              ? SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontal,
                    compact ? 8 : 24,
                    horizontal,
                    20,
                  ),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: content,
                )
              : Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontal,
                    vertical: compact ? 8 : 24,
                  ),
                  child: Align(alignment: Alignment.topCenter, child: content),
                );
        },
      );
}

class _ProfileLine extends StatelessWidget {
  const _ProfileLine(this.label, this.value,
      {this.compact = false, this.bottomGap = 10});
  final String label;
  final String value;
  final bool compact;
  final double bottomGap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: bottomGap),
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 17,
              vertical: compact ? 12 : 17,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 110,
                  child: Text(
                    label,
                    style: const TextStyle(color: AppTheme.muted),
                  ),
                ),
                Expanded(
                  child: Text(
                    value.isEmpty ? 'Belum diisi' : value,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

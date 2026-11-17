import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../models/laboratory_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class StudentHome extends StatefulWidget {
  const StudentHome({super.key, required this.profile});
  final UserModel profile;

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  late int selected = widget.profile.nim.isEmpty || widget.profile.className.isEmpty || widget.profile.cohort.isEmpty ? 2 : 0;
  late UserModel profile = widget.profile;

  @override
  void didUpdateWidget(covariant StudentHome oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile != widget.profile) {
      setState(() {
        profile = widget.profile;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('LabBook', style: TextStyle(color: AppTheme.deep, fontWeight: FontWeight.w800)),
      actions: [Padding(padding: const EdgeInsets.only(right: 12), child: IconButton(tooltip: 'Profil', onPressed: () => setState(() => selected = 2), icon: const Icon(Icons.account_circle_outlined)))],
    ),
    body: PageWidth(maxWidth: 680, child: IndexedStack(index: selected, children: [
      StudentDashboard(profile: profile, openCatalog: () => setState(() => selected = 1)),
      const LaboratoryCatalog(),
      StudentProfile(profile: profile, onUpdated: (updated) => setState(() => profile = updated)),
    ])),
    bottomNavigationBar: NavigationBar(
      selectedIndex: selected,
      onDestinationSelected: (i) => setState(() => selected = i),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Beranda'),
        NavigationDestination(icon: Icon(Icons.apartment_outlined), selectedIcon: Icon(Icons.apartment), label: 'Laboratorium'),
        NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
      ],
    ),
  );
}

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key, required this.profile, required this.openCatalog});
  final UserModel profile;
  final VoidCallback openCatalog;

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(24), children: [
    Text('Halo, ${profile.name.isEmpty ? 'Mahasiswa' : profile.name.split(' ').first}!', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
    const SizedBox(height: 7),
    const Text('Temukan laboratorium yang cocok untuk kegiatanmu.', style: TextStyle(color: AppTheme.muted)),
    const SizedBox(height: 24),
    Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: const Color(0xFFEAF7FC), borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.event_available_outlined, color: AppTheme.deep, size: 32),
        const SizedBox(height: 12),
        const Text('Butuh laboratorium?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        const Text('Lihat fasilitas dan pilih lab sebelum mengajukan reservasi.', style: TextStyle(color: AppTheme.muted)),
        const SizedBox(height: 16),
        ElevatedButton.icon(onPressed: openCatalog, icon: const Icon(Icons.search), label: const Text('Jelajahi laboratorium')),
      ]),
    ),
    const SizedBox(height: 28),
    const Text('Cara menggunakan LabBook', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
    const SizedBox(height: 14),
    const _Instruction(icon: Icons.apartment_outlined, number: '01', title: 'Temukan laboratorium', detail: 'Cari berdasarkan nama, lokasi, dan fasilitas.'),
    const _Instruction(icon: Icons.calendar_month_outlined, number: '02', title: 'Periksa jadwal', detail: 'Pilih tanggal dan jam melalui fitur reservasi.'),
    const _Instruction(icon: Icons.verified_outlined, number: '03', title: 'Tunggu persetujuan', detail: 'Pengajuan akan diperiksa asisten laboratorium.'),
  ]);
}

class _Instruction extends StatelessWidget {
  const _Instruction({required this.icon, required this.number, required this.title, required this.detail});
  final IconData icon;
  final String number;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFEAF7FC), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: AppTheme.deep)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$number · $title', style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 3),
        Text(detail, style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
      ])),
    ]))),
  );
}

class LaboratoryCatalog extends StatefulWidget {
  const LaboratoryCatalog({super.key});
  @override
  State<LaboratoryCatalog> createState() => _LaboratoryCatalogState();
}

class _LaboratoryCatalogState extends State<LaboratoryCatalog> {
  final search = TextEditingController();
  final labs = FirestoreService();

  @override
  void dispose() { search.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => StreamBuilder<List<LaboratoryModel>>(
    stream: labs.getActiveLaboratories(),
    builder: (context, snapshot) {
      return ListView(padding: const EdgeInsets.all(24), children: [
        const Text('Laboratorium', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        const Text('Lihat informasi dan fasilitas laboratorium kampus.', style: TextStyle(color: AppTheme.muted)),
        const SizedBox(height: 22),
        TextField(controller: search, onChanged: (_) => setState(() {}), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Cari nama, lokasi, atau fasilitas')),
        const SizedBox(height: 22),
        if (snapshot.hasError) const _InfoState(icon: Icons.wifi_off_rounded, text: 'Gagal memuat laboratorium. Periksa koneksi atau izin Firestore.'),
        if (!snapshot.hasError && !snapshot.hasData) const Center(child: Padding(padding: EdgeInsets.all(36), child: CircularProgressIndicator())),
        if (snapshot.hasData) ...[
          Builder(builder: (_) {
            final q = search.text.toLowerCase().trim();
            final items = snapshot.data!.where((lab) => '${lab.name} ${lab.building} ${lab.facilities.join(' ')}'.toLowerCase().contains(q)).toList()
              ..sort((a, b) => a.name.compareTo(b.name));
            if (items.isEmpty) return const _InfoState(icon: Icons.search_off, text: 'Belum ada laboratorium yang cocok.');
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${items.length} laboratorium', style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              for (final lab in items) Padding(padding: const EdgeInsets.only(bottom: 14), child: _LabCard(lab: lab)),
            ]);
          }),
        ],
      ]);
    },
  );
}

class _LabCard extends StatelessWidget {
  const _LabCard({required this.lab});
  final LaboratoryModel lab;

  @override
  Widget build(BuildContext context) => Card(child: InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => LaboratoryDetail(lab: lab))),
    child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
      Container(width: 88, height: 100, decoration: BoxDecoration(color: const Color(0xFFEAF7FC), borderRadius: BorderRadius.circular(12)), child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: lab.imageUrl != null && lab.imageUrl!.isNotEmpty
            ? Image.network(lab.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, _, _) => const Icon(Icons.computer_rounded, color: AppTheme.deep, size: 36))
            : const Icon(Icons.computer_rounded, color: AppTheme.deep, size: 36),
      )),
      const SizedBox(width: 15),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(lab.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15), maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 9),
        Text(lab.building, style: const TextStyle(color: AppTheme.muted, fontSize: 12), maxLines: 2),
        const SizedBox(height: 5),
        Text('Kapasitas ${lab.capacity} orang', style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
        const SizedBox(height: 10),
        const Text('Lihat detail  ›', style: TextStyle(color: AppTheme.deep, fontSize: 12, fontWeight: FontWeight.w700)),
      ])),
    ])),
  ));
}

class LaboratoryDetail extends StatelessWidget {
  const LaboratoryDetail({super.key, required this.lab});
  final LaboratoryModel lab;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Detail laboratorium')),
    body: SafeArea(child: PageWidth(maxWidth: 680, child: ListView(padding: const EdgeInsets.all(24), children: [
      Container(height: 184, decoration: BoxDecoration(color: const Color(0xFFEAF7FC), borderRadius: BorderRadius.circular(16)), child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: lab.imageUrl != null && lab.imageUrl!.isNotEmpty
            ? Image.network(lab.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, _, _) => const Icon(Icons.apartment_rounded, color: AppTheme.deep, size: 56))
            : const Icon(Icons.apartment_rounded, color: AppTheme.deep, size: 56),
      )),
      const SizedBox(height: 22),
      Text(lab.name, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w700)),
      const SizedBox(height: 9),
      Row(children: [const Icon(Icons.location_on_outlined, color: AppTheme.muted, size: 18), const SizedBox(width: 6), Expanded(child: Text(lab.building, style: const TextStyle(color: AppTheme.muted)))]),
      const SizedBox(height: 26),
      const Text('Informasi laboratorium', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      const SizedBox(height: 15),
      _DetailRow(icon: Icons.groups_outlined, label: 'Kapasitas', value: '${lab.capacity} orang'),
      _DetailRow(icon: Icons.schedule_outlined, label: 'Jam operasional', value: lab.operationalHours.isEmpty ? 'Belum ditentukan' : lab.operationalHours),
      const SizedBox(height: 20),
      const Text('Fasilitas tersedia', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      if (lab.facilities.isEmpty) const Text('Fasilitas belum didata.', style: TextStyle(color: AppTheme.muted)),
      for (final item in lab.facilities) Padding(padding: const EdgeInsets.only(bottom: 9), child: Row(children: [const Icon(Icons.check_circle_outline, size: 18, color: AppTheme.success), const SizedBox(width: 9), Expanded(child: Text(item))])),
      const SizedBox(height: 24),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF7FC),
          borderRadius: BorderRadius.circular(13),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: AppTheme.deep, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Reservasi memerlukan persetujuan asisten lab.',
                style: TextStyle(color: AppTheme.deep, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      ElevatedButton.icon(
        onPressed: () {
          showModalBottomSheet<void>(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (ctx) => SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.event_available_outlined,
                      size: 48,
                      color: AppTheme.deep,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Reservasi ${lab.name}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Formulir jadwal dan kalender interaktif sedang dihubungkan oleh tim booking (Minggu 3).',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.muted, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Tutup'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        icon: const Icon(Icons.calendar_today_outlined),
        label: const Text('Ajukan Reservasi'),
      ),
    ]))),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 15), child: Row(children: [
    Icon(icon, color: AppTheme.deep, size: 20),
    const SizedBox(width: 10),
    SizedBox(width: 111, child: Text(label, style: const TextStyle(color: AppTheme.muted, fontSize: 12))),
    Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
  ]));
}

class StudentProfile extends StatefulWidget {
  const StudentProfile({super.key, required this.profile, required this.onUpdated});
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil berhasil diperbarui.')));
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menyimpan profil. Periksa akses Firestore.')));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget editor(String title, TextEditingController controller, {bool year = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: TextFormField(controller: controller, keyboardType: year ? TextInputType.number : TextInputType.text, decoration: InputDecoration(labelText: title), validator: (v) {
      if (v == null || v.trim().isEmpty) return '$title wajib diisi';
      if (year && !RegExp(r'^\d{4}$').hasMatch(v.trim())) return 'Masukkan tahun 4 digit';
      return null;
    }),
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
          const Text('Profil mahasiswa', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 24)),
          SizedBox(height: compact ? 3 : 7),
          const Text('Identitas akademik untuk reservasi lab.', style: TextStyle(color: AppTheme.muted)),
          SizedBox(height: outerGap),
          Container(
            padding: EdgeInsets.all(cardPadding),
            decoration: BoxDecoration(color: const Color(0xFFEAF7FC), borderRadius: BorderRadius.circular(18)),
            child: Row(children: [
              CircleAvatar(
                radius: compact ? 25 : 31,
                backgroundColor: Colors.white,
                backgroundImage: widget.profile.photoUrl != null && widget.profile.photoUrl!.isNotEmpty
                    ? NetworkImage(widget.profile.photoUrl!)
                    : null,
                child: widget.profile.photoUrl == null || widget.profile.photoUrl!.isEmpty
                    ? Icon(Icons.person_outline_rounded, color: AppTheme.deep, size: compact ? 29 : 34)
                    : null,
              ),
              const SizedBox(width: 15),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.profile.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 5),
                Text(widget.profile.email, overflow: TextOverflow.ellipsis, maxLines: 1, style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
              ])),
            ]),
          ),
          SizedBox(height: compact ? 15 : 27),
          if (!editing) ...[
            _ProfileLine('NIM', widget.profile.nim, compact: compact, bottomGap: lineGap),
            _ProfileLine('Kelas', widget.profile.className, compact: compact, bottomGap: lineGap),
            _ProfileLine('Angkatan', widget.profile.cohort, compact: compact, bottomGap: lineGap),
            SizedBox(height: compact ? 7 : 16),
            OutlinedButton.icon(
              onPressed: () => setState(() => editing = true),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit profil'),
              style: OutlinedButton.styleFrom(minimumSize: Size.fromHeight(compact ? 44 : 50)),
            ),
          ] else Form(key: form, child: Column(children: [
            editor('Nama lengkap', name),
            editor('NIM', nim),
            editor('Kelas', className),
            editor('Angkatan', cohort, year: true),
            ElevatedButton(onPressed: saving ? null : save, child: Text(saving ? 'Menyimpan...' : 'Simpan perubahan')),
            TextButton(
              onPressed: saving ? null : () {
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
          ])),
          SizedBox(height: compact ? 10 : 25),
          TextButton.icon(
            onPressed: () async { await AuthService().signOut(); },
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            label: const Text('Keluar dari akun', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      );

      // Profil ringkas harus muat dalam satu layar; saat edit/keyboard,
      // scroll tetap tersedia agar semua kolom dapat dijangkau.
      final scrollable = editing || veryCompact || MediaQuery.viewInsetsOf(context).bottom > 0;
      return scrollable
          ? SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(horizontal, compact ? 8 : 24, horizontal, 20),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: content,
            )
          : Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: compact ? 8 : 24),
              child: Align(alignment: Alignment.topCenter, child: content),
            );
    },
  );

}

class _ProfileLine extends StatelessWidget {
  const _ProfileLine(this.label, this.value, {this.compact = false, this.bottomGap = 10});
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
        padding: EdgeInsets.symmetric(horizontal: 17, vertical: compact ? 12 : 17),
        child: Row(children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(color: AppTheme.muted))),
          Expanded(child: Text(
            value.isEmpty ? 'Belum diisi' : value,
            style: const TextStyle(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )),
        ]),
      ),
    ),
  );
}

class _InfoState extends StatelessWidget {
  const _InfoState({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 15), child: Column(children: [
    Icon(icon, size: 40, color: AppTheme.muted),
    const SizedBox(height: 12),
    Text(text, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.muted)),
  ]));
}

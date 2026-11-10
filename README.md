# 🔬 LabBook — Campus Laboratory Reservation App

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Firestore](https://img.shields.io/badge/Cloud_Firestore-FFA611?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com/docs/firestore)

Aplikasi mobile berbasis **Flutter** untuk memfasilitasi peminjaman dan reservasi laboratorium di lingkungan kampus secara transparan, terintegrasi, dan *real-time*. Proyek ini dikembangkan untuk menyelesaikan permasalahan bentrok jadwal praktikum, birokrasi manual berbasis kertas, dan ketiadaan informasi ketersediaan fasilitas laboratorium.

---

## 📌 Latar Belakang & Permasalahan

Laboratorium kampus memiliki tingkat utilisasi tinggi untuk kegiatan praktikum berkala, riset tugas akhir mahasiswa, penelitian dosen, maupun workshop organisasi mahasiswa. Namun, operasional saat ini kerap menemui kendala:
1. **Jadwal Bentrok & Tumpang Tindih:** Belum adanya visualisasi ketersediaan ruangan secara *real-time* berbasis kalender interaktif.
2. **Proses Pengajuan Konvensional:** Pengajuan masih mengandalkan formulir fisik atau pesan personal yang rentan terlewat.
3. **Ketidakterbukaan Informasi Fasilitas:** Mahasiswa kesulitan mengetahui spesifikasi perangkat (PC, proyektor, alat uji), kapasitas lab, dan jam operasional aktif.

**LabBook** hadir sebagai solusi terpadu dengan menyediakan kalender interaktif ala *Google Calendar*, sistem booking mandiri dengan pencegahan bentrok otomatis, serta panel pengelolaan persetujuan (*approval*) untuk asisten laboratorium.

---

## 🚀 Fitur Utama Aplikasi

Sistem LabBook dirancang dengan **Role-Based Access Control (RBAC)** yang membagi pengguna menjadi dua peran:

### 🎓 A. Fitur Mahasiswa (Student)
- [x] **Autentikasi & Registrasi Akun:** Login dan registrasi terintegrasi dengan Firebase Authentication.
- [x] **Kelengkapan Profil Akademik:** Pengisian data diri mahasiswa (NIM, Nama Lengkap, Kelas, dan Angkatan).
- [x] **Katalog & Detail Laboratorium:** Menampilkan daftar lab aktif, kapasitas, daftar fasilitas/perangkat, dan foto laboratorium.
- [x] **Kalender Jadwal Interaktif:** Visualisasi ketersediaan slot waktu lab ala *Google Calendar* secara *real-time*.
- [x] **Pengajuan Reservasi (Booking):** Memilih tanggal dan rentang jam dengan validasi pencegahan jadwal bentrok secara otomatis.
- [x] **Manajemen & Riwayat Reservasi:** Memantau status peminjaman (`Pending`, `Approved`, `Rejected`, `Cancelled`).
- [x] **Pembatalan Mandiri:** Mahasiswa dapat membatalkan reservasi miliknya yang belum berlangsung.
- [x] **Transparansi Penolakan:** Mengetahui alasan penolakan secara jelas jika pengajuan ditolak oleh laboran.

### 🛡️ B. Fitur Admin / Asisten Laboratorium
- [x] **Dashboard Operasional:** Ringkasan statistik harian (pengajuan menunggu persetujuan, lab aktif, peminjaman hari ini).
- [x] **Pusat Persetujuan (Approval Center):** Menyetujui atau menolak permohonan reservasi dengan catatan alasan penolakan.
- [x] **Reservasi Manual (Walk-in Booking):** Menginputkan peminjaman langsung di tempat untuk mahasiswa yang datang ke meja asisten lab.
- [x] **Manajemen Laboratorium (CRUD Lab):** Menambah, memperbarui fasilitas/kapasitas, dan menonaktifkan status laboratorium.
- [x] **Blokir Jadwal (Maintenance & Kelas Reguler):** Mengunci slot waktu di kalender untuk jadwal praktikum berkala atau perawatan lab.
- [x] **Laporan & Riwayat Peminjaman:** Arsip lengkap riwayat peminjaman laboratorium kampus.

---

## 🛠️ Arsitektur Teknologi & Database

### Tech Stack
- **Framework:** Flutter (Channel Stable)
- **Language:** Dart
- **Backend as a Service:** Firebase
  - **Firebase Authentication:** Manajemen sesi & login pengguna
  - **Cloud Firestore:** Database NoSQL *real-time* untuk data lab, pengguna, dan reservasi
  - **Firebase Storage:** Penyimpanan berkas dan foto laboratorium
- **State Management:** Provider / Riverpod

### Skema Cloud Firestore
Aplikasi mengelola 3 koleksi data utama:
1. `users` — Data profil mahasiswa dan akun admin/asisten lab (`uid`, `name`, `nim`, `class_name`, `cohort`, `role`).
2. `laboratories` — Informasi ruangan lab (`lab_id`, `name`, `building`, `capacity`, `facilities`, `operational_hours`, `is_active`).
3. `reservations` — Data transaksi peminjaman & blokir jadwal (`reservation_id`, `lab_id`, `user_id`, `start_time`, `end_time`, `status`, `rejection_reason`, `admin_id`).

---

## 👥 Anggota Kelompok & Pembagian Tugas

| No | Foto / Avatar | Nama Mahasiswa | NIM | Username GitHub | Peran & Tanggung Jawab Utama |
|:--:|:--:|---|:---:|:---:|---|
| 1 | 👤 | **[Muhammad Dava Syahputra]** | [NIM K3524058] | [@Davyrann](https://github.com/Davyrann) | **Backend & Architecture Lead** |
| 2 | 👤 | **[Fatih Nur Faiq]** | [NIM K3524052] | [@Fatih-faiq](https://github.com/Pluto-404) | **Student Experience Lead** |
| 3 | 👤 | **[Muhammad Raihan Faza]** | [NIM K3524060] | [@raihan-23-git](https://github.com/raihan-23-git) | **Core Booking & Calendar Lead** |
| 4 | 👤 | **[Nama Mahasiswa 4]** | [NIM K3524054] | [@ghaliishiddiq12](https://github.com/ghaliishiddiq12/) | **Admin & Management Lead** |


## 💻 Panduan Instalasi & Menjalankan Proyek

Bagi anggota kelompok yang ingin menjalankan proyek ini di perangkat lokal:

### 1. Prasyarat
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (versi 3.19 ke atas)
- [Dart SDK](https://dart.dev/get-dart)
- Android Studio / VS Code dengan ekstensi Flutter & Dart
- Akun Google / Firebase yang telah diundang sebagai Collaborator project

### 2. Kloning Repositori
```bash
git clone https://github.com/Pluto-404/lab-reservation-app.git
cd lab-reservation-app
```

### 3. Mengambil Dependensi
```bash
flutter pub get
```

### 4. Konfigurasi Firebase (Khusus Anggota Baru)
Pastikan FlutterFire CLI terinstal, lalu jalankan konfigurasi:
```bash
flutterfire configure
```
Pilih project Firebase kelompok yang telah dibuat.

### 5. Menjalankan Aplikasi
```bash
flutter run
```

---

## 📅 Roadmap Perkembangan Proyek (4 Minggu)

Jadwal kerja proyek LabBook dibagi menjadi 4 minggu dengan pembagian tugas dan target commit GitHub untuk setiap anggota kelompok.

### Minggu 1 – Persiapan dan Perancangan

| Anggota | Tugas Pokok | Target Commit GitHub |
|---|---|---|
| Muhammad Dava Syahputra | Setup Firebase (Auth, Firestore), menyusun skema data dan hak akses. | `docs: inisialisasi skema firestore dan konfigurasi backend` |
| Fatih Nur Faiq | Membuat wireframe UI Mahasiswa (Login, Register, Profil, Katalog Lab). | `docs: wireframe antarmuka mahasiswa dan katalog` |
| Muhammad Raihan Faza | Inisialisasi proyek Flutter, wireframe kalender dan form booking. | `chore: inisialisasi flutter dan struktur navigasi awal` |
| Ghali Shiddiq Fatullah | Membuat wireframe UI Admin, Dashboard dan laporan pengumpulan SPADA Minggu 1. | `docs: panduan kontribusi dan mockup admin dashboard` |

### Minggu 2 – Implementasi Fitur Dasar

| Anggota | Tugas Pokok | Target Commit GitHub |
|---|---|---|
| Muhammad Dava Syahputra | Implementasi AuthService, UserModel, LabModel, dan FirestoreService. | `feat(auth): implementasi AuthService dan UserModel` |
| Fatih Nur Faiq | Implementasi halaman Register, Login, Profil, dan Katalog Lab. | `feat(ui): antarmuka login, profil mahasiswa, dan katalog lab` |
| Muhammad Raihan Faza | Implementasi navigasi BottomBar dan integrasi kalender mingguan. | `feat(calendar): implementasi antarmuka kalender mingguan` |
| Ghali Shiddiq Fatullah | Implementasi Dashboard Admin dan form Tambah/Edit Lab (CRUD Lab). | `feat(admin): antarmuka kelola lab dan integrasi crud` |

### Minggu 3 – Implementasi Fitur Lanjutan

| Anggota | Tugas Pokok | Target Commit GitHub |
|---|---|---|
| Muhammad Dava Syahputra | Query realtime kalender Firestore dan Security Rules. | `feat(backend): query realtime kalender dan security rules` |
| Fatih Nur Faiq | Membuat halaman Riwayat Booking Mahasiswa, fitur pembatalan, dan dialog alasan penolakan. | `feat(booking): riwayat peminjaman mahasiswa dan pembatalan` |
| Muhammad Raihan Faza | Membuat form pengajuan booking dan logika validasi jadwal bentrok. | `feat(booking): form booking dan validasi jadwal bentrok` |
| Ghali Shiddiq Fatullah | Membuat Pusat Persetujuan (Approval Center) untuk menyetujui dan menolak booking. | `feat(admin): sistem approval dan penolakan booking` |

### Minggu 4 – Pengujian dan Finalisasi

| Anggota | Tugas Pokok | Target Commit GitHub |
|---|---|---|
| Muhammad Dava Syahputra | Optimasi query Firestore, offline support, dan seeder data demo. | `perf: optimasi query firestore dan penyusunan seeder data` |
| Fatih Nur Faiq | Polishing UI mahasiswa, dokumentasi screenshot, serta penyusunan Bab 1 dan 2 Laporan Akhir. | `docs: dokumentasi screenshot dan penyusunan bab 1 2` |
| Muhammad Raihan Faza | Pengujian fungsional (Black-box) dan penyusunan Bab 5 Laporan Akhir. | `test: skenario pengujian kalender dan validasi booking` |
| Ghali Shiddiq Fatullah | Implementasi fitur Walk-in Booking, blokir maintenance, dan finalisasi slide presentasi serta laporan. | `feat(admin): fitur walk-in booking dan finalisasi laporan` |

---

## 🎥 Rencana Demonstrasi Aplikasi

Demonstrasi dilakukan untuk memperlihatkan cara kerja aplikasi LabBook, mulai dari proses login mahasiswa hingga pengelolaan reservasi oleh admin.

### 1. Persiapan Demonstrasi

Sebelum demonstrasi dimulai, tim menyiapkan:
- Aplikasi LabBook yang sudah dapat dijalankan.
- Akun mahasiswa dan akun admin untuk pengujian.
- Data laboratorium beserta informasi fasilitas dan kapasitas.
- Data jadwal laboratorium untuk simulasi reservasi.
- Koneksi internet untuk mengakses Firebase.

### 2. Skenario Demonstrasi

| No. | Skenario | Aktivitas Demonstrasi |
|---|---|---|
| 1 | Login Mahasiswa | Menunjukkan proses login dan registrasi menggunakan Firebase Authentication. |
| 2 | Profil Mahasiswa | Menampilkan informasi identitas mahasiswa. |
| 3 | Katalog Laboratorium | Menampilkan daftar laboratorium, fasilitas, kapasitas, dan jam operasional. |
| 4 | Kalender Laboratorium | Menunjukkan jadwal ketersediaan laboratorium. |
| 5 | Pengajuan Reservasi | Mahasiswa memilih laboratorium, tanggal, waktu, dan mengirim pengajuan booking. |
| 6 | Validasi Jadwal | Menunjukkan proses pencegahan jadwal reservasi yang bentrok. |
| 7 | Persetujuan Admin | Admin melihat pengajuan dan melakukan persetujuan atau penolakan reservasi. |
| 8 | Riwayat Reservasi | Menampilkan status dan riwayat booking mahasiswa. |
| 9 | Fitur Admin | Menunjukkan pengelolaan data laboratorium, walk-in booking, dan blokir jadwal maintenance. |

### 3. Pembagian Tugas Demonstrasi

| Anggota | Tanggung Jawab |
|---|---|
| Muhammad Dava Syahputra | Menjelaskan integrasi Firebase, Authentication, Firestore, dan pengelolaan data backend. |
| Fatih Nur Faiq | Mendemonstrasikan tampilan dan fitur mahasiswa. |
| Muhammad Raihan Faza | Mendemonstrasikan kalender, pengajuan booking, dan validasi jadwal. |
| Ghali Shiddiq Fatullah | Mendemonstrasikan dashboard admin, persetujuan booking, dan pengelolaan laboratorium. |

### 4. Target Hasil Demonstrasi

- Seluruh fitur utama aplikasi dapat diperlihatkan.
- Proses reservasi mahasiswa dapat berjalan.
- Admin dapat mengelola dan memproses pengajuan reservasi.
- Integrasi Firebase dapat ditunjukkan.
- Tim dapat menjelaskan fungsi dan alur kerja aplikasi LabBook.

### 5. Penutup

Demonstrasi diakhiri dengan penyampaian kesimpulan mengenai fungsi aplikasi LabBook, manfaat sistem reservasi laboratorium, serta hasil pengembangan proyek oleh seluruh anggota kelompok.

---

## 📄 Dokumen Terkait
- [Panduan dan Ketentuan Resmi Proyek](PANDUAN_PROYEK.md)
- [Dokumen Perancangan Teknis & Skema Database](DOKUMEN_PERANCANGAN_LABBOOK.md)

---
*Dikembangkan untuk memenuhi Tugas Proyek Mata Kuliah Pengembangan Aplikasi Mobile.*

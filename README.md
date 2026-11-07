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
| 1 | 👤 | **[Nama Mahasiswa 1]** | [NIM] | [@username1](https://github.com/username1) | **Project Lead & Backend** (Firebase Auth, Firestore, Skema Data) |
| 2 | 👤 | **[Nama Mahasiswa 2]** | [NIM] | [@username2](https://github.com/username2) | **UI/UX & Frontend** (Katalog Lab, Detail Lab, Profil) |
| 3 | 👤 | **[Nama Mahasiswa 3]** | [NIM] | [@username3](https://github.com/username3) | **Core Feature Lead** (Kalender Jadwal Interaktif & Form Booking) |
| 4 | 👤 | **[Nama Mahasiswa 4]** | [NIM] | [@username4](https://github.com/username4) | **Admin Module Lead** (Panel Approval, Walk-in Booking, Blokir Jadwal) |
| 5 | 👤 | **[Nama Mahasiswa 5]** | [NIM] | [@username5](https://github.com/username5) | **QA & Documentation** (Pengujian Fungsional, Laporan Mingguan) |

*(Silakan sesuaikan data anggota kelompok di atas)*

---

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

- [x] **Minggu 1 — Identifikasi Masalah, Perancangan, & Setup Repo**
  - [x] Identifikasi masalah dan penentuan topik (LabBook).
  - [x] Perancangan arsitektur, ERD Firestore, dan user flow.
  - [x] Inisialisasi GitHub repository, penyusunan `README.md`, dan pembagian tugas.
- [ ] **Minggu 2 — Implementasi Antarmuka & Integrasi Firebase Dasar**
  - [ ] Implementasi autentikasi & kelengkapan profil mahasiswa.
  - [ ] Pembuatan katalog lab dan navigasi utama.
  - [ ] Setup Cloud Firestore dan integrasi data laboratorium.
- [ ] **Minggu 3 — Penyelesaian Fitur Inti & Pengujian Awal**
  - [ ] Implementasi kalender jadwal interaktif ala Google Calendar.
  - [ ] Form reservasi lab dengan logika pencegahan bentrok (*conflict detection*).
  - [ ] Panel persetujuan (*approval/rejection*) untuk admin/asisten lab.
- [ ] **Minggu 4 — Finalisasi, Walk-in Booking, Pengujian Akhir & Presentasi**
  - [ ] Fitur booking walk-in dan blokir jadwal maintenance.
  - [ ] Pengujian fungsional menyeluruh (*Black-box testing*).
  - [ ] Penyusunan Laporan Akhir (PDF) dan demonstrasi aplikasi.

---

## 📄 Dokumen Terkait
- [Panduan dan Ketentuan Resmi Proyek](PANDUAN_PROYEK.md)
- [Dokumen Perancangan Teknis & Skema Database](DOKUMEN_PERANCANGAN_LABBOOK.md)

---
*Dikembangkan untuk memenuhi Tugas Proyek Mata Kuliah Pengembangan Aplikasi Mobile.*

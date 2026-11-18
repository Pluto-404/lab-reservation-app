# Kalender Mingguan & Form Booking (Core Booking & Calendar)

Fitur ini dikerjakan oleh Muhammad Raihan Faza.

## Alur pengguna
1. Tab **Kalender** (BottomBar) -> pilih laboratorium -> lihat jadwal per minggu.
2. Ketuk area kosong (atau tombol **Ajukan Peminjaman**) -> form pengajuan.
3. Isi tanggal, jam mulai/selesai, kegiatan, tujuan, jumlah peserta -> **Tinjau Pengajuan** -> **Kirim Pengajuan**.
4. Pengajuan muncul langsung di kalender sebagai blok kuning (menunggu).

## Aturan validasi (`lib/utils/booking_validator.dart`)
- Waktu selesai harus setelah waktu mulai, dan dalam hari yang sama.
- Tidak boleh di waktu lampau dan harus dalam jam operasional lab.
- Bentrok: `start < existing.end && end > existing.start` pada lab yang sama,
  status `approved` / `maintenance_block`. Dicek di UI **dan** lagi di
  `FirestoreService.createReservation` saat disimpan.
- Peserta 1..kapasitas lab. Pengajuan sendiri yang beririsan juga ditolak.

## File
- `lib/screens/student/schedule/` kalender mingguan & halaman jadwal
- `lib/screens/student/booking/` form booking & chip status
- `lib/services/booking_service.dart`, `lib/utils/`
- Perubahan kecil: `app_theme.dart` (warna status), `reservation_model.dart` (+`participants`),
  `firestore_service.dart` (+`participants`), `student_home.dart` (tab Kalender),
  `laboratory_detail_page.dart` (tombol), `app_router.dart` (2 rute)

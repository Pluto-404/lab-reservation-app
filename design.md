# Design System --- LABSPACE

## Aplikasi Penyewaan Laboratorium Kampus

> Dokumen ini adalah sumber kebenaran desain untuk coding agent. Ikuti
> spesifikasi ini secara konsisten saat membangun UI Flutter. Jangan
> membuat keputusan visual baru yang bertentangan dengan dokumen ini
> tanpa alasan fungsional yang kuat.

------------------------------------------------------------------------

## 1. Product intent

Bangun aplikasi mobile untuk civitas akademika yang ingin mencari
laboratorium kampus, melihat fasilitas dan ketersediaan jadwal,
mengajukan peminjaman, serta memantau status pengajuan.

**Karakter produk:** profesional, akademis, tenang, jelas, efisien, dan
dapat dipercaya.

**Prioritas UX:** 1. Pengguna dapat menemukan laboratorium yang sesuai
dengan cepat. 2. Informasi lokasi, kapasitas, fasilitas, dan jadwal
mudah dipindai. 3. Proses pengajuan terasa terarah dan tidak
membingungkan. 4. Status pengajuan selalu jelas dan memiliki penjelasan
tekstual. 5. Tampilan konsisten pada seluruh halaman.

Jangan mengubah aplikasi menjadi dashboard analitik yang padat. Ini
adalah aplikasi peminjaman ruang, bukan aplikasi admin enterprise.

## 2. Anti-slop rules --- wajib dipatuhi

Hindari pola desain generik dan dekorasi yang tidak memiliki fungsi.

-   **Jangan** menggunakan gradient sebagai dekorasi default. Gunakan
    warna solid dari token.
-   **Jangan** menggunakan glassmorphism, efek neon, glow, blur
    dekoratif, atau bayangan besar.
-   **Jangan** menambahkan ilustrasi abstrak, blob, bentuk geometris
    acak, atau ornamen hanya untuk mengisi ruang kosong.
-   **Jangan** menggunakan emoji sebagai ikon UI. Gunakan ikon Material
    yang konsisten.
-   **Jangan** menggunakan terlalu banyak kartu bertumpuk. Gunakan
    section, divider, dan whitespace untuk membentuk hierarki.
-   **Jangan** membuat setiap elemen menjadi pill/capsule. Radius harus
    mengikuti spesifikasi komponen.
-   **Jangan** menggunakan warna berbeda-beda untuk elemen yang memiliki
    fungsi sama.
-   **Jangan** menampilkan angka statistik, rating, jumlah peminjaman,
    atau ketersediaan palsu. Data contoh harus diberi label demo/mock
    bila backend belum tersedia.
-   **Jangan** membuat tombol yang terlihat aktif tetapi tidak memiliki
    aksi.
-   **Jangan** membuat navigasi, filter, kalender, pencarian, atau form
    yang hanya dekoratif. Implementasikan interaksi nyata atau tampilkan
    sebagai disabled dengan alasan yang jelas.
-   **Jangan** menambahkan teks placeholder seperti "Lorem ipsum",
    "Welcome to our app", atau copywriting generik.
-   **Jangan** menggunakan font display eksperimental. Gunakan Roboto
    (default Flutter Material) atau Inter jika font tersebut benar-benar
    tersedia di project.
-   **Jangan** memenuhi layar dengan ikon. Ikon hanya digunakan jika
    membantu mengenali tindakan atau kategori.
-   **Jangan** mengubah struktur informasi demi mengejar tampilan yang
    ramai.
-   **Jangan** menambahkan fitur yang tidak diminta, seperti chat,
    pembayaran, rating, peta, atau notifikasi real-time, tanpa kebutuhan
    produk yang jelas.

Jika ragu, pilih solusi yang lebih sederhana, lebih mudah dibaca, dan
lebih mudah dipelihara.

## 3. Color system

Gunakan palet biru terinspirasi identitas UNS. Biru utama harus terasa
tegas dan sedikit gelap, bukan biru neon.

  -----------------------------------------------------------------------
  Token                   Hex                     Penggunaan
  ----------------------- ----------------------- -----------------------
  `primary`               `#1E5AA8`               Tombol utama, link,
                                                  selected state, ikon
                                                  aksi utama

  `primaryDark`           `#123B6D`               Penekanan visual,
                                                  header khusus bila
                                                  dibutuhkan

  `primarySoft`           `#EAF1FA`               Selected background,
                                                  chip netral biru,
                                                  highlight ringan

  `background`            `#F5F7FA`               Latar utama halaman

  `surface`               `#FFFFFF`               Card, dialog, bottom
                                                  sheet, input

  `textPrimary`           `#202124`               Judul, isi, label,
                                                  informasi utama

  `textSecondary`         `#6B7280`               Deskripsi, metadata,
                                                  hint, tanggal

  `border`                `#D8E0EA`               Border input, divider,
                                                  outline

  `success`               `#16845B`               Status
                                                  disetujui/berhasil

  `warning`               `#A66A00`               Status menunggu/perlu
                                                  perhatian

  `error`                 `#C0392B`               Status ditolak, error,
                                                  validasi gagal
  -----------------------------------------------------------------------

### Color rules

-   Latar utama menggunakan `background`, bukan biru.
-   Surface utama berwarna putih.
-   Teks utama selalu `textPrimary`; teks sekunder `textSecondary`.
-   Tombol primary menggunakan `primary` dengan teks putih.
-   Jangan menggunakan `primaryDark` untuk semua tombol; simpan sebagai
    warna penekanan.
-   Warna status hanya untuk status dan feedback terkait. Jangan gunakan
    hijau/merah sebagai dekorasi.
-   Pastikan kontras teks dan latar memadai. Jangan menurunkan opacity
    teks utama hingga sulit dibaca.
-   Jangan memperkenalkan warna brand baru tanpa alasan fungsional.

## 4. Typography

Gunakan Roboto melalui theme Flutter sebagai pilihan default. Skala
berikut menggunakan logical pixels / `sp` secara konseptual.

  -------------------------------------------------------------------------
  Style                            Ukuran Weight           Penggunaan
  ----------------- --------------------- ---------------- ----------------
  `displaySmall`                       28 Bold             Hanya untuk
                                                           judul khusus
                                                           bila benar-benar
                                                           diperlukan

  `headlineSmall`                      24 Bold             Judul halaman
                                                           utama

  `titleLarge`                         20 Semi-bold        Judul section
                                                           penting

  `titleMedium`                        16 Semi-bold        Judul card dan
                                                           subbagian

  `bodyLarge`                          16 Regular          Isi utama

  `bodyMedium`                         14 Regular          Isi standar

  `bodySmall`                          12 Regular          Metadata dan
                                                           keterangan

  `labelLarge`                         14 Semi-bold        Label tombol

  `labelMedium`                        12 Medium           Label chip dan
                                                           field
  -------------------------------------------------------------------------

Rules: - Gunakan maksimal 3 tingkat hierarki yang dominan dalam satu
layar. - Hindari seluruh teks memakai bold. - Jangan gunakan uppercase
untuk kalimat panjang. - Jangan gunakan ukuran di bawah 12 untuk
informasi yang harus dibaca. - Judul harus menjelaskan isi halaman,
bukan slogan pemasaran.

## 5. Layout, spacing, and shape

Gunakan sistem spacing berbasis 4 dp.

  Token        Nilai
  ---------- -------
  `space2`         8
  `space3`        12
  `space4`        16
  `space5`        20
  `space6`        24
  `space8`        32

Ketentuan: - Padding horizontal halaman mobile: 20 dp (boleh 16 dp pada
layar sempit). - Jarak antar-section: 24 dp. - Jarak antar-elemen yang
berhubungan: 8--12 dp. - Tinggi tombol utama: 50 dp (minimum area sentuh
48 dp). - Tinggi input: sekitar 52--56 dp. - Radius tombol: 12 dp. -
Radius input: 12 dp. - Radius card: 14 dp. - Radius dialog/bottom sheet:
16 dp. - Border standar: 1 dp `border`. - Elevation sangat rendah atau
nol. Utamakan border dan perbedaan surface daripada shadow. - Jangan
membuat konten melekat ke tepi layar. - Gunakan safe area dan dukung
keyboard agar field aktif tidak tertutup.

## 6. Component specifications

### Primary button

-   Background `primary`, foreground putih.
-   Tinggi 50 dp, radius 12 dp.
-   Label 14--16 dp semi-bold.
-   Loading state harus menonaktifkan aksi ganda dan menampilkan
    indikator proses.
-   Disabled state harus jelas, bukan sekadar mengubah opacity sedikit.
-   Gunakan satu tombol primary dominan per area tindakan.

### Secondary button

-   Background putih atau transparan.
-   Foreground `primary`.
-   Border `border` atau biru lembut.
-   Tinggi dan radius konsisten dengan primary button.

### Text field

-   Background putih, border `border`.
-   Focus border `primary` dengan ketebalan 1.5 dp.
-   Label field tetap terlihat ketika field terisi.
-   Hint menggunakan `textSecondary`.
-   Error message muncul dekat field terkait dan menjelaskan cara
    memperbaiki.
-   Password field menyediakan kontrol show/hide.
-   Jangan hanya mengandalkan hint sebagai label.

### Laboratory card

Tampilkan informasi dengan urutan: 1. Nama laboratorium. 2.
Gedung/lokasi. 3. Kapasitas. 4. Maksimal 2--3 fasilitas paling relevan.
5. Status ketersediaan atau aksi untuk melihat detail.

Gunakan thumbnail hanya jika aset foto laboratorium tersedia. Jika tidak
ada, gunakan placeholder netral yang rapi dengan ikon laboratorium;
jangan mengambil foto acak dari internet.

### Status chip

-   Bentuk rounded rectangle, bukan kapsul yang terlalu besar.
-   Menampilkan teks status, bukan warna saja.
-   `Menunggu`: latar kuning lembut, teks `warning`.
-   `Disetujui`: latar hijau lembut, teks `success`.
-   `Ditolak`: latar merah lembut, teks `error`.
-   `Dibatalkan`: latar abu muda, teks `textSecondary`.
-   `Selesai`: latar `primarySoft`, teks `primary`.

### Navigation

-   Gunakan Material 3 `NavigationBar` untuk navigasi mahasiswa.
-   Menu: Beranda, Laboratorium, Pesanan, Profil.
-   Label menu harus terlihat; jangan hanya ikon.
-   Selected state menggunakan `primary`.
-   Hindari lebih dari 4 menu utama pada bottom navigation.

### Dialog and bottom sheet

-   Jelaskan konsekuensi tindakan secara singkat.
-   Tombol pembatalan dan konfirmasi harus memiliki label spesifik,
    misalnya "Kembali" dan "Kirim Pengajuan".
-   Jangan menggunakan "OK" untuk tindakan yang penting.

## 7. Information architecture and screens

### A. Authentication

**Login** - Identitas aplikasi: `LABSPACE` atau nama final yang
disepakati tim. - Deskripsi singkat: "Peminjaman Laboratorium Kampus". -
Field NIM/email kampus. - Field kata sandi. - Tombol "Masuk". - Tautan
"Lupa kata sandi?" hanya jika alur reset benar-benar tersedia. -
Keterangan akses civitas akademika. - Jangan menampilkan daftar fitur
atau statistik di halaman login.

### B. Student app

#### Beranda

Urutan konten: 1. Sapaan dan nama pengguna. 2. Search field "Cari
laboratorium atau fasilitas". 3. Ringkasan pengajuan yang benar-benar
berasal dari data. 4. Daftar laboratorium atau shortcut yang relevan. 5.
Bottom navigation.

Jangan menampilkan terlalu banyak kartu statistik. Jika belum ada data,
tampilkan empty state yang informatif.

#### Katalog laboratorium

-   Search field.
-   Filter yang relevan: gedung, kapasitas, fasilitas, ketersediaan.
-   List laboratorium dengan nama, lokasi, kapasitas, fasilitas utama,
    dan status.
-   Filter harus berfungsi.
-   Empty state harus menawarkan tindakan untuk menghapus filter atau
    mengubah pencarian.

#### Detail laboratorium

-   Foto laboratorium jika tersedia.
-   Nama dan lokasi.
-   Status ketersediaan.
-   Kapasitas.
-   Jam operasional.
-   Fasilitas.
-   Aturan penggunaan.
-   Tombol utama "Cek Jadwal & Ajukan".

#### Pilih jadwal

-   Pilih tanggal.
-   Pilih jam mulai dan jam selesai.
-   Tampilkan slot yang tersedia dan tidak tersedia dengan legenda
    tekstual.
-   Cegah tanggal lampau.
-   Cegah waktu selesai sebelum atau sama dengan waktu mulai.
-   Periksa benturan jadwal dari sumber data.
-   Tampilkan ringkasan jadwal sebelum pengguna melanjutkan.

#### Form pengajuan

Field yang disarankan: - Nama dan NIM/email pemohon (otomatis dari
profil bila tersedia). - Tujuan penggunaan. - Mata kuliah/kegiatan. -
Jumlah peserta. - Penanggung jawab dan kontak jika dibutuhkan. - Dokumen
pendukung hanya jika diwajibkan.

Tandai field wajib secara konsisten. Jangan meminta pengguna mengisi
ulang data profil yang sudah tersedia.

#### Tinjau pengajuan

-   Ringkasan laboratorium.
-   Tanggal dan jam.
-   Jumlah peserta.
-   Tujuan penggunaan.
-   Data pemohon.
-   Tombol untuk kembali mengubah data.
-   Tombol "Kirim Pengajuan".

#### Pesanan

-   Tab atau filter "Aktif" dan "Riwayat".
-   Setiap item menunjukkan nama lab, jadwal, kode pengajuan, dan
    status.
-   Detail pengajuan menampilkan catatan admin.
-   Aksi pembatalan hanya tersedia jika aturan mengizinkan.

#### Profil

-   Nama, NIM, program studi, email, dan kontak.
-   Pengaturan akun.
-   Bantuan/FAQ jika kontennya tersedia.
-   Keluar.

### C. Admin (jika termasuk ruang lingkup tugas)

Admin menggunakan akses berbasis role. Jangan mencampur kontrol admin ke
dalam tampilan mahasiswa.

Fitur admin minimum: - Dashboard ringkas untuk jumlah pengajuan
berdasarkan status. - Daftar dan detail pengajuan. - Setujui/tolak
pengajuan dengan catatan. - Kelola data laboratorium. - Kelola jadwal
tidak tersedia. - Riwayat pengajuan.

Jangan membuat dashboard admin penuh grafik jika kebutuhan tugas hanya
memerlukan pengelolaan pengajuan.

## 8. Interaction and state requirements

Setiap halaman harus memiliki state berikut sesuai kebutuhan: -
Loading. - Loaded/content. - Empty. - Error. - Disabled atau
unavailable. - Success feedback setelah aksi berhasil.

Perilaku wajib: - Search memperbarui hasil atau memberi feedback yang
jelas. - Filter dapat diterapkan dan dihapus. - Tombol detail membuka
laboratorium yang dipilih. - Form melakukan validasi sebelum submit. -
Submit mencegah pengiriman ganda. - Status berubah hanya berdasarkan
respons data, bukan karena pengguna menekan tombol secara lokal. - Jika
koneksi gagal, tampilkan pesan yang dapat dipahami dan opsi mencoba
kembali. - Konfirmasi sebelum tindakan yang sulit dibatalkan. - Jangan
menghapus input pengguna ketika validasi gagal.

## 9. Responsive and accessibility

-   Target utama adalah Android mobile.
-   Layout harus tetap baik pada lebar sekitar 360 dp hingga perangkat
    yang lebih besar.
-   Gunakan `SafeArea`, scrollable layout, dan keyboard-aware behavior.
-   Hindari fixed height untuk area konten yang teksnya dapat bertambah.
-   Jangan menggunakan posisi absolut untuk layout utama.
-   Pastikan tombol dan field memiliki area sentuh memadai.
-   Jangan mengandalkan warna sebagai satu-satunya pembeda status.
-   Teks harus memiliki kontras yang baik.
-   Tambahkan semantic label pada ikon yang hanya berupa tombol.
-   Uji dengan ukuran font sistem yang diperbesar.

## 10. Flutter implementation guidance

Gunakan: - Flutter Material 3 (`useMaterial3: true`). - `ThemeData`
terpusat. - Komponen reusable. - `const` constructor jika
memungkinkan. - Pemisahan UI, model, dan service. - State management
yang sudah digunakan project. Jangan menambah package state management
baru tanpa kebutuhan dan persetujuan. - `Navigator` atau routing package
yang sudah ada di project. Jangan mengganti sistem routing tanpa alasan.

Struktur folder yang disarankan:

``` text
lib/
  main.dart
  app/
    app.dart
    theme/
      app_theme.dart
      app_colors.dart
      app_text_styles.dart
  models/
    user.dart
    laboratory.dart
    booking.dart
    schedule.dart
  screens/
    auth/
      login_screen.dart
    home/
      home_screen.dart
    laboratory/
      laboratory_list_screen.dart
      laboratory_detail_screen.dart
    booking/
      schedule_screen.dart
      booking_form_screen.dart
      booking_review_screen.dart
    orders/
      booking_list_screen.dart
      booking_detail_screen.dart
    profile/
      profile_screen.dart
    admin/
      admin_dashboard_screen.dart
      booking_management_screen.dart
      laboratory_management_screen.dart
  widgets/
    primary_button.dart
    secondary_button.dart
    app_text_field.dart
    laboratory_card.dart
    status_chip.dart
    empty_state.dart
  services/
    auth_service.dart
    laboratory_service.dart
    booking_service.dart
```

Jangan membuat semua halaman dalam satu file `main.dart`. Jangan membuat
abstraksi berlebihan untuk komponen yang hanya dipakai sekali.

## 11. Asset and icon policy

-   Gunakan aset lokal dari project jika tersedia.
-   Jangan mengunduh atau menggunakan gambar eksternal tanpa
    izin/kebutuhan.
-   Jika foto lab belum tersedia, gunakan placeholder netral, bukan
    gambar stok yang seolah-olah merupakan fasilitas kampus.
-   Gunakan ikon Material (`Icons.*`) secara konsisten.
-   Hindari emoji, ikon dari banyak library berbeda, dan ikon dekoratif
    yang tidak memiliki fungsi.
-   Jangan membuat logo resmi UNS sendiri atau memodifikasi logo kampus.
    Gunakan aset resmi yang disediakan tim jika memang diperlukan.

## 12. Content and microcopy

Gunakan bahasa Indonesia yang ringkas, sopan, dan langsung.

Contoh label: - "Cari laboratorium atau fasilitas" - "Lihat Detail" -
"Cek Jadwal & Ajukan" - "Pilih Tanggal" - "Waktu Mulai" - "Waktu
Selesai" - "Tujuan Penggunaan" - "Kirim Pengajuan" - "Menunggu
Persetujuan" - "Pengajuan Disetujui" - "Pengajuan Ditolak"

Contoh empty state: - "Belum ada pengajuan." - "Laboratorium tidak
ditemukan. Coba ubah kata kunci atau filter." - "Belum ada jadwal pada
tanggal ini."

Contoh error: - "Jadwal tersebut sudah digunakan. Silakan pilih waktu
lain." - "Jumlah peserta melebihi kapasitas laboratorium." - "Pengajuan
belum dapat dikirim. Periksa kembali kolom yang wajib diisi."

Hindari slogan berlebihan, kalimat pemasaran, dan copywriting yang tidak
membantu tugas pengguna.

## 13. Data integrity and demo content

-   Tandai data dummy secara eksplisit dalam kode atau dokumentasi.
-   Jangan menyajikan data dummy sebagai jadwal kampus yang benar-benar
    tersedia.
-   Jangan mengasumsikan nama, kapasitas, fasilitas, jam operasional,
    atau aturan laboratorium tertentu.
-   Simpan status pengajuan berdasarkan sumber data yang menjadi acuan
    aplikasi.
-   Pemeriksaan konflik jadwal harus dilakukan pada lapisan data/service
    juga, bukan hanya menyembunyikan slot di UI.
-   Jangan menaruh kredensial, API key, atau secret di source code.

## 14. Definition of done

Sebuah layar dianggap selesai jika: - Mengikuti color, typography,
spacing, dan component tokens dalam dokumen ini. - Hierarki informasi
jelas dan konten mudah dipindai. - Tidak ada elemen dekoratif yang tidak
diperlukan. - Semua kontrol interaktif memiliki aksi yang benar. -
Loading, empty, error, dan success state ditangani. - Tidak ada overflow
pada lebar layar target. - Tidak ada teks dummy yang tertinggal. - Tidak
ada warning/error Flutter yang diperkenalkan oleh implementasi. - Kode
menggunakan komponen yang dapat dipakai ulang tanpa abstraksi
berlebihan.

## 15. Instructions to the coding agent

Sebelum mengubah kode: 1. Periksa struktur project dan file yang sudah
ada. 2. Identifikasi package, routing, state management, aset, dan pola
kode yang sudah digunakan. 3. Pertahankan implementasi yang masih
relevan. 4. Jangan menghapus atau mengganti konfigurasi project tanpa
alasan teknis. 5. Implementasikan satu alur pengguna secara utuh sebelum
memperluas fitur.

Saat mengerjakan: - Ikuti dokumen ini sebagai design source of truth. -
Jangan menambahkan fitur atau dekorasi di luar kebutuhan. - Jangan
mengarang data kampus. - Jangan membuat tombol palsu atau interaksi
semu. - Jika ada kebutuhan yang belum jelas, pilih implementasi paling
sederhana dan catat asumsi tersebut. - Gunakan nama file, class, dan
variable yang jelas. - Pisahkan perubahan visual dari perubahan
data/backend bila memungkinkan.

Setelah mengerjakan: 1. Jalankan `dart format` pada file Dart yang
diubah. 2. Jalankan `flutter analyze`. 3. Perbaiki error dan warning
yang disebabkan perubahan. 4. Jalankan aplikasi atau widget test yang
relevan jika tersedia. 5. Laporkan file yang diubah, fitur yang selesai,
asumsi yang dibuat, dan hal yang masih membutuhkan data/keputusan tim.

**Final quality bar:** hasil harus terasa seperti aplikasi layanan
kampus yang benar-benar dapat digunakan: tenang, rapi, konsisten, jelas,
dan fungsional. Jangan mengejar efek visual; utamakan kualitas informasi
dan interaksi.

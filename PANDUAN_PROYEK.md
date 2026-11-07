# Panduan dan Ketentuan Proyek Pengembangan Aplikasi Mobile

**Tema:** Pengembangan Aplikasi Mobile Berbasis Flutter untuk Menyelesaikan Permasalahan Nyata di Lingkungan Kampus

---

## A. Deskripsi Proyek

Mahasiswa diminta mengembangkan aplikasi mobile menggunakan framework Flutter yang bertujuan membantu menyelesaikan permasalahan nyata di lingkungan kampus.

Mahasiswa diberikan kebebasan untuk mengidentifikasi permasalahan, menentukan solusi, dan mengembangkan aplikasi sesuai kebutuhan pengguna. Aplikasi harus memiliki fungsi yang jelas, dapat digunakan, serta memanfaatkan teknologi API atau database berbasis cloud.

Proyek dilaksanakan secara berkelompok selama **4 minggu**, mulai dari:
1. Identifikasi masalah
2. Perancangan aplikasi
3. Implementasi
4. Pengujian
5. Presentasi hasil akhir

> **Catatan Wajib:** Selama pengerjaan proyek, setiap kelompok wajib mendokumentasikan perkembangan melalui **SPADA** dan menggunakan **GitHub** sebagai sarana kolaborasi serta pengelolaan source code.

---

## B. Ketentuan Umum

1. **Kelompok:** Proyek dikerjakan secara berkelompok dengan jumlah anggota **3–5 mahasiswa**.
2. **Durasi:** Waktu pengerjaan proyek adalah **4 minggu**.
3. **Teknologi Utama:** Aplikasi wajib dikembangkan menggunakan **Flutter** dan bahasa pemrograman **Dart**.
4. **Backend / Data:** Aplikasi wajib menggunakan minimal salah satu teknologi berikut:
   - **REST API**, baik API publik maupun API yang dikembangkan sendiri.
   - **Firebase Cloud Firestore** sebagai database untuk menyimpan dan mengelola data aplikasi.
5. **Relevansi Masalah:** Permasalahan yang diangkat harus merupakan masalah nyata di lingkungan kampus dan memiliki target pengguna yang jelas.
6. **Jumlah Fitur:** Setiap kelompok wajib mengembangkan aplikasi dengan **minimal 3 fitur utama yang saling terintegrasi**.
7. **Kualitas Aplikasi:** Aplikasi harus memiliki antarmuka yang mudah digunakan, navigasi yang jelas, dan fitur yang berfungsi dengan baik.
8. **Partisipasi:** Setiap anggota kelompok wajib berkontribusi dalam proses pengembangan aplikasi.
9. **Repository GitHub:**
   - Wajib membuat repository GitHub pada minggu pertama dan melaporkan tautan repository melalui SPADA.
   - Repository GitHub wajib digunakan secara aktif selama proses pengembangan proyek, bukan hanya untuk mengunggah source code pada akhir pengerjaan.
10. **Laporan Mingguan:** Setiap kelompok wajib mengunggah laporan perkembangan proyek setiap minggu melalui SPADA.
11. **Presentasi & Demo:** Pada minggu terakhir, setiap kelompok wajib mempresentasikan dan mendemonstrasikan aplikasi yang dikembangkan.
12. **Pengumpulan Akhir:** Setiap kelompok wajib mengunggah laporan akhir ke SPADA dan memastikan source code lengkap tersedia di repository GitHub.
13. **Orisinalitas:** Proyek harus merupakan hasil pengembangan kelompok sendiri. Penggunaan library, template, atau kode dari sumber lain diperbolehkan dengan mencantumkan sumbernya.

---

## C. Contoh Ide Proyek (Referensi)

| No. | Ide Aplikasi | Permasalahan yang Diselesaikan |
|:---:|---|---|
| 1 | Campus Lost & Found | Membantu mahasiswa melaporkan dan menemukan barang hilang di kampus |
| 2 | Pelaporan Fasilitas Kampus | Memudahkan pelaporan fasilitas rusak seperti AC, proyektor, atau kursi |
| 3 | **Peminjaman Ruangan / Lab** | **Membantu mahasiswa memeriksa dan mengajukan peminjaman ruang kegiatan/laboratorium** *(Dipilih untuk proyek ini: LabBook)* |
| 4 | Informasi Kegiatan Kampus | Memudahkan mahasiswa menemukan informasi seminar, lomba, dan kegiatan organisasi |
| 5 | Kantin Kampus Digital | Membantu mahasiswa melihat menu, harga, dan melakukan pemesanan makanan |
| 6 | Campus Carpool | Memfasilitasi mahasiswa yang ingin berbagi kendaraan menuju kampus |
| 7 | Sistem Antrean Layanan Kampus | Membantu mahasiswa mengambil nomor antrean layanan administrasi |
| 8 | Peminjaman Barang Organisasi | Membantu pengelolaan peminjaman inventaris organisasi mahasiswa |

> *Catatan: Ide proyek harus diajukan pada minggu pertama untuk mendapatkan persetujuan dosen sebelum dilanjutkan ke tahap implementasi.*

---

## D. Tahapan dan Target Pengerjaan Mingguan

### Minggu 1 — Identifikasi Masalah dan Perancangan
#### Kegiatan:
- Mengidentifikasi permasalahan nyata di lingkungan kampus.
- Menentukan target pengguna dan kebutuhan aplikasi.
- Menentukan minimal 3 fitur utama aplikasi.
- Membuat rancangan antarmuka aplikasi (wireframe atau mockup).
- Menentukan API atau struktur database Firestore yang akan digunakan.
- Membagi tugas kepada setiap anggota kelompok.
- Membuat repository GitHub dan menambahkan seluruh anggota sebagai collaborator.
- Melakukan inisialisasi repository, seperti membuat README dan struktur awal proyek Flutter.

#### Pengumpulan SPADA Minggu 1:
- [ ] Deskripsi masalah dan solusi yang diusulkan.
- [ ] Daftar fitur utama aplikasi.
- [ ] Rancangan antarmuka aplikasi.
- [ ] Rencana penggunaan API atau Firestore.
- [ ] Pembagian tugas anggota kelompok.
- [ ] Link repository GitHub.
- [ ] Daftar username GitHub seluruh anggota kelompok.
- [ ] Bukti inisialisasi repository dan commit awal.

---

### Minggu 2 — Implementasi Antarmuka dan Integrasi Data
#### Kegiatan:
- Membuat dan mengembangkan struktur proyek Flutter.
- Mengimplementasikan halaman utama dan navigasi aplikasi.
- Mengembangkan antarmuka fitur utama.
- Mengintegrasikan aplikasi dengan API atau Firebase Firestore.
- Melakukan pengujian awal terhadap fitur yang sudah dikembangkan.
- Melakukan commit dan push perubahan kode secara berkala ke GitHub.

#### Pengumpulan SPADA Minggu 2:
- [ ] Screenshot antarmuka aplikasi yang telah dibuat.
- [ ] Penjelasan fitur yang sudah diimplementasikan.
- [ ] Bukti awal integrasi API atau Firestore.
- [ ] Kendala yang ditemukan dan rencana penyelesaiannya.
- [ ] Link repository GitHub.
- [ ] Ringkasan aktivitas commit selama minggu kedua.
- [ ] Kontribusi masing-masing anggota kelompok.

---

### Minggu 3 — Penyelesaian Fitur dan Pengujian
#### Kegiatan:
- Menyelesaikan implementasi seluruh fitur utama.
- Memastikan proses pengambilan dan penyimpanan data berjalan dengan baik.
- Melakukan pengujian fungsional aplikasi.
- Memperbaiki bug dan meningkatkan kualitas antarmuka.
- Mempersiapkan aplikasi untuk demonstrasi akhir.
- Melanjutkan aktivitas pengembangan dan dokumentasi kode melalui GitHub.

#### Pengumpulan SPADA Minggu 3:
- [ ] Screenshot fitur aplikasi yang telah diselesaikan.
- [ ] Daftar fitur yang sudah berfungsi.
- [ ] Hasil pengujian aplikasi.
- [ ] Daftar bug atau kendala yang ditemukan beserta perbaikannya.
- [ ] Link repository GitHub.
- [ ] Ringkasan aktivitas commit selama minggu ketiga.
- [ ] Kontribusi masing-masing anggota kelompok.

---

### Minggu 4 — Finalisasi, Presentasi, dan Pengumpulan
#### Kegiatan:
- Melakukan pengujian akhir aplikasi.
- Memastikan seluruh fitur utama berjalan dengan baik.
- Memperbaiki bug yang masih ditemukan.
- Menyiapkan presentasi dan demonstrasi aplikasi.
- Menyusun laporan akhir proyek.
- Melengkapi source code dan dokumentasi pada repository GitHub.
- Melakukan presentasi dan demonstrasi langsung aplikasi.

#### Pengumpulan SPADA Minggu 4:
- [ ] Laporan akhir proyek dalam format PDF.
- [ ] File presentasi.
- [ ] Link repository GitHub final yang berisi source code lengkap.
- [ ] Ringkasan kontribusi setiap anggota selama empat minggu.
- [ ] Link video demonstrasi aplikasi (jika diminta oleh dosen).

---

## E. Ketentuan Repository GitHub

1. **Waktu Pembuatan:** Setiap kelompok wajib membuat repository GitHub pada minggu pertama pelaksanaan proyek.
2. **Pelaporan:** Link repository GitHub wajib dilaporkan melalui SPADA pada pengumpulan progress minggu pertama.
3. **Kolaborasi:** Seluruh anggota kelompok wajib memiliki akun GitHub dan ditambahkan sebagai collaborator pada repository kelompok.
4. **Penggunaan Aktif:** Repository wajib digunakan sejak awal hingga akhir proyek sebagai tempat penyimpanan source code dan dokumentasi pengembangan aplikasi.
5. **Aktivitas Berkala:** Setiap kelompok wajib menunjukkan aktivitas pengembangan secara berkala di GitHub selama empat minggu, yang dapat ditelusuri melalui riwayat commit.
6. **Kontribusi Anggota:** Setiap anggota kelompok wajib berkontribusi pada repository sesuai pembagian tugasnya (penambahan fitur, perbaikan kode, pengujian, atau dokumentasi).
7. **Pesan Commit:** Setiap commit harus menggunakan pesan yang jelas dan menggambarkan perubahan yang dilakukan (*descriptive commit message*).
8. **Larangan:** Kelompok **tidak diperbolehkan** hanya mengunggah seluruh source code sekaligus pada akhir proyek tanpa riwayat pengembangan yang dapat ditelusuri.
9. **Laporan Mingguan:** Setiap laporan progress mingguan di SPADA wajib menyertakan ringkasan aktivitas GitHub selama minggu tersebut.
10. **Kelengkapan Repository:** Repository GitHub wajib memuat:
    - Source code lengkap proyek Flutter.
    - File `README.md` yang menjelaskan: nama aplikasi, deskripsi, fitur utama, anggota kelompok, dan cara menjalankan aplikasi.
    - Screenshot aplikasi.
    - Informasi penggunaan API atau Firebase Firestore.
    - Riwayat commit yang menunjukkan perkembangan proyek dari minggu pertama hingga minggu keempat.
11. **Akses Dosen:** Repository harus dapat diakses oleh dosen untuk keperluan pemeriksaan dan penilaian (Public atau Invite dosen jika Private).
12. **Penilaian Git:** Penilaian aktivitas GitHub didasarkan pada:
    - Jumlah commit yang wajar dan konsisten.
    - Kualitas perubahan kode.
    - Relevansi kontribusi terhadap pengembangan aplikasi.
13. **Keamanan Data:** File yang berisi password, token rahasia, atau kredensial layanan **tidak boleh diunggah** ke repository (gunakan `.gitignore` untuk file konfigurasi sensitif seperti kunci API).

---

## F. Format Laporan Akhir

Laporan akhir disusun dengan sistematika berikut:

1. **Pendahuluan**
   - Latar belakang masalah.
   - Tujuan pengembangan aplikasi.
   - Target pengguna aplikasi.
2. **Analisis Kebutuhan**
   - Deskripsi permasalahan yang ditemukan.
   - Kebutuhan pengguna.
   - Daftar fitur utama aplikasi.
3. **Perancangan Aplikasi**
   - Rancangan antarmuka aplikasi.
   - Alur navigasi aplikasi.
   - Arsitektur aplikasi atau struktur data.
4. **Implementasi**
   - Penjelasan implementasi fitur utama.
   - Penggunaan Flutter dan Dart.
   - Integrasi API atau Firebase Firestore.
   - Screenshot hasil implementasi.
5. **Pengujian**
   - Skenario pengujian aplikasi.
   - Hasil pengujian setiap fitur.
   - Bug yang ditemukan dan perbaikannya.
6. **Kesimpulan**
   - Hasil pengembangan aplikasi.
   - Keterbatasan aplikasi.
   - Saran pengembangan selanjutnya.
7. **Pembagian Kontribusi Anggota**
   - Nama dan tugas setiap anggota.
   - Fitur atau bagian aplikasi yang dikerjakan.
   - Ringkasan kontribusi selama proyek.
   - Bukti kontribusi melalui aktivitas GitHub.

---

## G. Kriteria Penilaian

| No. | Komponen Penilaian | Bobot |
|:---:|---|:---:|
| 1 | Relevansi masalah dan kesesuaian solusi | 15% |
| 2 | Fungsionalitas dan kelengkapan fitur aplikasi | 25% |
| 3 | Implementasi Flutter dan integrasi API/Firestore | 20% |
| 4 | Kualitas antarmuka dan kemudahan penggunaan | 10% |
| 5 | Progress mingguan dan aktivitas GitHub | 15% |
| 6 | Pengujian dan laporan akhir | 10% |
| 7 | Presentasi dan demonstrasi aplikasi | 5% |
| **TOTAL** | | **100%** |

> **Catatan Penilaian Individu:** Nilai individu dapat berbeda dalam satu kelompok berdasarkan kontribusi masing-masing anggota yang dibuktikan melalui laporan mingguan, riwayat aktivitas GitHub, dan kemampuan menjelaskan bagian aplikasi yang dikerjakan saat sesi tanya jawab/demo.

---

## H. Ketentuan Tambahan

- Setiap kelompok wajib mengunggah progress pengerjaan ke SPADA pada akhir setiap minggu sesuai tenggat yang ditentukan dosen.
- Setiap laporan progress harus menunjukkan perkembangan nyata dibandingkan minggu sebelumnya.
- Repository GitHub harus menunjukkan aktivitas pengembangan yang konsisten selama periode pengerjaan proyek.
- Aplikasi yang dikumpulkan harus dapat dijalankan dan didemonstrasikan.
- Seluruh anggota kelompok wajib mengikuti presentasi akhir dan memahami aplikasi yang dikembangkan.
- Dosen dapat mengajukan pertanyaan secara individu mengenai kode, fitur, dan kontribusi masing-masing anggota.
- Aplikasi yang hanya menampilkan antarmuka statis tanpa integrasi API atau Firestore **tidak memenuhi persyaratan proyek**.
- Keterlambatan pengumpulan dan pelanggaran integritas akademik ditangani sesuai ketentuan mata kuliah.

---

## I. Hasil Akhir yang Diharapkan

Pada akhir proyek, setiap kelompok diharapkan menghasilkan sebuah aplikasi mobile berbasis Flutter yang:
1. Mampu memberikan solusi terhadap permasalahan nyata di lingkungan kampus.
2. Memiliki minimal **tiga fitur utama** yang berfungsi dengan baik.
3. Terintegrasi dengan **REST API atau Firebase Cloud Firestore**.
4. Memiliki antarmuka yang mudah digunakan (*user-friendly*).
5. Telah melalui proses pengujian fungsional.
6. Memiliki source code dan dokumentasi lengkap pada GitHub.
7. Menunjukkan riwayat pengembangan dan kontribusi anggota melalui aktivitas GitHub selama empat minggu.

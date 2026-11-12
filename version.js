/* ============================================================
   VERSION.JS — Instrumen Penilaian Jabal Rahmah
   JANGAN EDIT MANUAL file ini jika pakai update.bat
   Gunakan: update.bat [patch|minor|major|skip]
   ============================================================ */

window.APP_INFO = {
  version: '1.3.3',
  buildDate: '2026-11-12',

  changelog: [
    {
      version: 'v1.3.3',
      date: '2026-11-12',
      highlights: [
        '\'Satu guru kini bisa mengajar beberapa kelas dan mapel sekaligus (Madrasah maupun Pontren)\',',
        '\'Popup pindah kelas dan mapel dipisah menjadi dua langkah yang jelas dan mudah\',',
        '\'Mapel Pontren mengikuti Struktur Kurikulum TA 2025/2026 (kelas 1–6) lengkap dengan kitab per kelas\',',
        '\'Guru bebas menambah mapel apa pun; mapel utama dari Admin tampil di urutan teratas pilihan\',',
        '\'Daftar penugasan dibuat ringkas dan profesional, dilengkapi filter dan tombol "Rapikan kosong"\',',
        '\'Tampilan Identitas, UTS, dan UAS lebih responsif untuk layar kecil dan HP\',',
        '\'Data siswa dari Admin otomatis tampil saat guru login — tanpa mengubah ID, nilai, dan absensi guru\',',
        '\'Admin dan guru hanya menampilkan kelas dan mapel yang benar-benar dipilih guru (tidak ada lagi mapel atau kelas "nyasar")\',',
        '\'Kolom mapel dan kelas di Admin dibuat rapi untuk guru dengan banyak mapel (ringkas dengan tombol +N)\',',
        '\'Memperbaiki nama siswa yang tampil "[object Object]" saat sinkron dari Admin\',',
        '\'Memperbaiki data absen dan pengamatan yang bisa tertimpa saat Admin menyimpan data siswa\',',
        '\'Memperbaiki halaman Admin yang kadang kosong (blank) saat pertama kali dibuka\',',
        '\'Memperbaiki tulisan merah yang muncul saat berganti kelas\',',
        '\'Akun dengan email lokal (@jabalrahmah.local) kini bisa diganti Admin ke email asli melalui verifikasi saat guru login\',',
        '\'Login bisa menggunakan username atau email asli; lupa sandi terkirim ke email asli\',',
        '\'Lupa sandi sekarang bisa diisi dengan username; akun yang masih email lokal mendapat pesan agar menghubungi Admin\',',
        '\'Edit Akun di Admin tidak lagi menghapus data tambahan akun dan tidak mengubah role akun admin\',',
        '\'Menu "Konfigurasi Firebase" dan "Muat Data Demo" dihapus dari menu guru\''
      ]
    },
    {
      version: 'v1.3.2',
      date: '2026-11-10',
      highlights: [
        '<b>⚡ Sinkronisasi Real-Time &amp; Optimalisasi Data</b>',
        'Mengganti sistem polling (cek data tiap 15 detik) dengan metode Stream API (SSE) di Admin',
        'Menghemat kuota Firebase hingga 99% dan membuat dashboard admin update secara instan',
        'Sinkronisasi dua arah antara Admin dan Guru menggunakan Global Roster',
        '<b>👥 Manajemen Akun &amp; Keamanan (Admin)</b>',
        'Pembuatan akun guru otomatis terdaftar di Firebase Authentication (tanpa input UID manual)',
        'Email opsional (otomatis menggunakan @jabalrahmah.local jika kosong)',
        'Fitur Backup Database untuk mengunduh seluruh data ke format JSON',
        'Fitur Reset Sandi Guru via email langsung dari panel Admin',
        '<b>🏫 Pusat Data Siswa &amp; Kelas (Admin)</b>',
        'Tab baru "Kelola Siswa" untuk memusatkan data siswa (NIS, NISN, JK, TTL)',
        'Fitur Import &amp; Export Excel untuk mempermudah input data siswa',
        'Fitur Pengaturan Kelas &amp; Madrasah Dinamis (Admin bisa menambah/mengubah MTs, MAS, Pontren dan kelasnya)',
        'Data siswa yang diinput Admin otomatis terdistribusi ke semua guru (nilai guru tidak tertimpa)',
        '<b>👨‍🏫 Penyempurnaan Aplikasi Guru (guru.html)</b>',
        'Perbaikan bug perpindahan kelas lintas Madrasah (bisa pindah dari MAS ke Pontren dengan lancar)',
        'Perbaikan bug mapel yang berubah kembali ke default saat di-refresh',
        'Data siswa di guru dikunci (Read-only) - guru hanya bisa mengisi nilai/absen, tidak bisa hapus/tambah',
        'Fitur Ganti Sandi kini memerlukan konfirmasi "Sandi Saat Ini" (Sandi Lama) demi keamanan',
        'Penambahan tombol 👁️ Tampilkan untuk melihat ketiga kolom sandi sekaligus',
        '<b>🎨 Perbaikan Tampilan (UI/UX)</b>',
        'Penyeragaman desain Hero Section (sudut melengkung, margin, dan shadow) di Admin &amp; Guru',
        'Memperbaiki tampilan tabel input data siswa di Admin (garis border transparan, efek fokus biru)',
        'Perbaikan filter data sampah (key invalid) di dashboard Admin agar tampilan lebih bersih'
      ]
    },
    {
      version: 'v1.3.1',
      date: '2026-11-09',
      highlights: [
        '<b>⚡ Sinkronisasi Real-time</b>',
        'Ganti polling ke streaming (hemat kuota 99%)',
        'Update instan dashboard admin dan guru',
        '<b>🔐 Manajemen Akun Cerdas</b>',
        'Auto-create Firebase Auth saat tambah guru',
        'UID terisi otomatis (tanpa input manual)',
        'Email opsional (default @jabalrahmah.local)',
        '<b>🛡️ Perbaikan Bug &amp; Keamanan</b>',
        'Filter data sampah (key invalid) di dashboard admin',
        'Auto-reconnect stream saat koneksi terputus'
      ]
    },
    {
      version: 'v1.3.0',
      date: '2026-11-09',
      highlights: [
        '<b>🔐 Login</b>',
        '📧 Login bisa pakai email atau username',
        '🧠 Smart Mode cek database dulu → cegah error "terlalu banyak percobaan"',
        '🔑 Lupa sandi mandiri via modal + link reset Firebase',
        '🏷️ Brand baru: Yayasan Yusuf Al-Karimi / Pondok Pesantren Jabal Rahmah',
        '<b>🖥️ Admin</b>',
        '🖨️ Tab baru Cetak Rapor ATS &amp; Semester',
        '✏️ Panel edit rapor real-time',
        '📝 Template nasehat walikelas otomatis',
        '📤 Terbitkan daftar siswa',
        '<b>👨‍🏫 Guru</b>',
        '👤 Menu Akun Saya + ganti sandi',
        '🏫 Multi-madrasah: MTs, MAS, Pontren',
        '📚 Kelas Pontren 1–7 otomatis'
      ]
    },
  ]
};
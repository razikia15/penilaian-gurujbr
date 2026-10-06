/* ============================================================
   VERSION.JS — Instrumen Penilaian Jabal Rahmah
   JANGAN EDIT MANUAL file ini jika pakai update.bat
   Gunakan: update.bat [patch|minor|major|skip]
   ============================================================ */

window.APP_INFO = {
  version: '1.1.1',
  buildDate: '2026-10-06',

  changelog: [
    {
      version: 'v1.1.1',
      date: '2026-10-06',
      highlights: [
        'Update project files ^(8 files^)'
      ]
    },
    {
      version: 'v1.1.0',
      date: '2026-10-06',
      highlights: [
        '🔧 Fix input remedial — bisa ketik 2 digit (mis. 70) tanpa kehilangan fokus',
        '🔗 Materi Sumatif jadi master — otomatis tersinkron ke tab UH, UH Manual & Remedial',
        '🔒 Materi UH sekarang readonly (auto dari Sumatif) untuk hindari duplikasi input',
        '🐛 Fix bug input data siswa (variabel "sel" tidak terdefinisi)',
        '✨ Dropdown UH & Remedial menampilkan materi otomatis sebagai subtitle',
        '🛡️ Normalisasi data — sinkron materi Sumatif → UH untuk data lama',
        '📥 Impor Excel: materi dari sheet Sumatif langsung dipakai di UH'
      ]
    },
    {
      version: 'v1.0.0',
      date: '2026-10-04',
      highlights: [
        '🎉 Rilis perdana Instrumen Penilaian Guru MAS Jabal Rahmah',
        '📚 Multi-kelas: VII, VIII, IX, X, XI, XII',
        '📝 Sumatif, Analisis UH, UH Manual, Remedial, UTS, UAS, Nilai Akhir',
        '☁️ Sinkronisasi Firebase Realtime Database (mode personal per guru)',
        '📤 Ekspor & Impor Excel lengkap',
        '🔐 Login multi-role (Guru & Admin)',
        '👨‍💼 Admin Panel: dashboard, rekap, rapor, kelola akun'
      ]
    }
  ]
};
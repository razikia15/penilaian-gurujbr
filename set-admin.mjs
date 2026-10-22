import { initializeApp, cert } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { readFileSync } from 'fs';

// Baca file JSON secara manual agar lebih aman
const serviceAccount = JSON.parse(readFileSync('./service-account.json', 'utf8'));

// Inisialisasi Firebase Admin
initializeApp({
  credential: cert(serviceAccount)
});

// Masukkan UID user yang akan dijadikan admin
const uidAdmin = 'FUYRqaxxRMfD2rIkfJX4wURJxh13'; 

// Set custom claim
getAuth().setCustomUserClaims(uidAdmin, { admin: true })
  .then(() => {
    console.log(`✅ Berhasil! Claim 'admin: true' telah ditambahkan ke UID: ${uidAdmin}`);
    console.log('User tersebut harus login ulang agar claim-nya aktif.');
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ Gagal mengatur claim:', error);
    process.exit(1);
  });
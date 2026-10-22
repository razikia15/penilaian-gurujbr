const admin = require('firebase-admin');

// Ganti path ini jika nama file service account Anda berbeda
const serviceAccount = require('./service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

// Masukkan UID user yang akan dijadikan admin
const uidAdmin = 'MASUKKAN_UID_ADMIN_DI_SINI'; 

admin.auth().setCustomUserClaims(uidAdmin, { admin: true })
  .then(() => {
    console.log(`✅ Berhasil! Claim 'admin: true' telah ditambahkan ke UID: ${uidAdmin}`);
    console.log('User tersebut harus login ulang agar claim-nya aktif.');
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ Gagal mengatur claim:', error);
    process.exit(1);
  });
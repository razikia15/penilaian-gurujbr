const { initializeApp, cert } = require('firebase-admin/app');
const { getDatabase } = require('firebase-admin/database');
const serviceAccount = require('./service-account.json');

initializeApp({
  credential: cert(serviceAccount),
  databaseURL: "https://instrumen-jabal-default-rtdb.asia-southeast1.firebasedatabase.app"
});

const db = getDatabase();

// PENTING: Masukkan UID yang benar di sini
const mapping = {
  'guru_17071998': '125CuHSwOYdZahjG36lpq4TSI52' // ID Lama : UID Baru Arrazi
};

async function migrate() {
  for (const [oldId, newUid] of Object.entries(mapping)) {
    console.log(`Memproses migrasi: ${oldId} -> ${newUid}...`);
    
    // 1. Migrasi Data Nilai (Personal)
    const personalSnap = await db.ref(`instrumen/personal/${oldId}`).get();
    if (personalSnap.exists()) {
      await db.ref(`instrumen/personal/${newUid}`).set(personalSnap.val());
      console.log(`✅ Data nilai (personal) berhasil dipindahkan.`);
    } else {
      console.log(`⚠️ Data personal ${oldId} tidak ditemukan.`);
    }

    // 2. Migrasi Profil Guru (Teachers)
    const teacherSnap = await db.ref(`instrumen/teachers/${oldId}`).get();
    if (teacherSnap.exists()) {
      const data = teacherSnap.val();
      data.uid = newUid; 
      data.teacherId = newUid;
      await db.ref(`instrumen/teachers/${newUid}`).set(data);
      console.log(`✅ Profil guru (teachers) berhasil dipindahkan.`);
    }

    console.log(`--------------------------------------------------`);
  }
  console.log("🎉 SEMUA MIGRASI SELESAI!");
  process.exit(0);
}

migrate().catch(err => {
  console.error("Gagal migrasi:", err);
  process.exit(1);
});
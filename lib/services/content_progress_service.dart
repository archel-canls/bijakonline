import 'package:firebase_database/firebase_database.dart';
import '../models/modul_model.dart';
import 'package:firebase_database/firebase_database.dart' show ServerValue; // Import ServerValue

class ContentProgressService {
  final DatabaseReference _modulRef = FirebaseDatabase.instance.ref('modules');
  final DatabaseReference _progressRef = FirebaseDatabase.instance.ref('progress');

  // --- Fungsionalitas Pengguna (Baca) ---

  // Ambil semua daftar modul (Halaman Modul)
  Stream<List<ModulModel>> getModules() {
    return _modulRef.onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];
      
      List<ModulModel> modules = [];
      data.forEach((key, value) {
        // Pastikan nilai adalah Map
        if (value is Map) {
          modules.add(ModulModel.fromMap(Map<String, dynamic>.from(value), key.toString()));
        }
      });
      return modules;
    });
  }

  // Ambil detail modul
  Future<ModulModel?> getModuleDetail(String moduleId) async {
    final snapshot = await _modulRef.child(moduleId).get();
    if (snapshot.exists) {
      // Pastikan nilai adalah Map
      final value = snapshot.value;
      if (value is Map) {
        return ModulModel.fromMap(Map<String, dynamic>.from(value), moduleId);
      }
    }
    return null;
  }

  // Ambil progres user untuk modul tertentu
  Stream<Map<String, dynamic>?> getModuleProgressStream(String userId, String moduleId) {
    // Menggunakan stream untuk real-time progress
    return _progressRef.child(userId).child(moduleId).onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return null;
      return Map<String, dynamic>.from(data);
    });
  }

  // NEW: Menandai modul sebagai 'dipelajari' / started (dipanggil saat klik 'Pelajari Sekarang')
  Future<void> markModuleAsStarted(String userId, String moduleId) async {
    // Cek apakah progress sudah ada atau belum
    final progressSnapshot = await _progressRef.child(userId).child(moduleId).get();
    
    if (!progressSnapshot.exists) {
      // Jika belum ada, inisialisasi progres
      await _progressRef.child(userId).child(moduleId).set({
        'status': 'In Progress', // Status: Started / Dipelajari
        'startedAt': ServerValue.timestamp,
        // Progres unit akan diinisialisasi nanti saat unit pertama selesai.
      });
    } else {
      // Jika sudah ada, update status menjadi 'In Progress' jika belum 'Completed'
       await _progressRef.child(userId).child(moduleId).update({
        'status': 'In Progress',
      });
    }
  }

  // Menandai unit materi selesai (Viewer Konten Microlearning)
  Future<void> markUnitCompleted(String userId, String moduleId, int unitIndex) async {
    // Logika: update /progress/{userId}/{moduleId}/units/{unitIndex} = true
    await _progressRef.child(userId).child(moduleId).child('units').child(unitIndex.toString()).set(true);
    // Hitung total unit selesai untuk update progress global
  }

  // Log Partisipasi/Absensi (Partisipasi - Pengguna/Admin)
  Future<void> logParticipation(String userId, String eventType, String eventName) async {
    final newLogRef = _progressRef.child(userId).child('participation_log').push();
    await newLogRef.set({
      'eventType': eventType, // Contoh: 'Webinar', 'Tantangan Harian'
      'eventName': eventName,
      'timestamp': ServerValue.timestamp,
    });
  }
  
  // --- Fungsionalitas Admin (CRUD Modul) ---
  
  // Buat/Update Modul Baru (DIUPDATE)
  Future<void> saveModule(ModulModel modul) async {
    // Menggunakan toMap() dari ModulModel yang baru
    final Map<String, dynamic> data = modul.toMap();
    
    if (modul.id.isEmpty) {
      // Buat baru
      await _modulRef.push().set(data);
    } else {
      // Update
      await _modulRef.child(modul.id).update(data);
    }
  }

  // Hapus Modul
  Future<void> deleteModule(String moduleId) async {
    await _modulRef.child(moduleId).remove();
    // Opsional: Hapus juga progres pengguna terkait modul ini
    // Note: Menghapus progres banyak user bisa mahal. Diperlukan logika admin yang lebih kompleks.
  }
}
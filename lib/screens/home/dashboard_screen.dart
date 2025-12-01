import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart'; // NEW
import '../../main.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/quiz_service.dart';
import '../../services/content_progress_service.dart'; // NEW
import '../../models/quiz_model.dart';
import '../../models/modul_model.dart'; // 💡 PERBAIKAN: IMPORT MODULMODEL YANG HILANG
import '../learning/modul_list_screen.dart';
import '../profile/profile_screen.dart';
// import '../notification/notification_screen.dart'; // DIHAPUS - Hanya digunakan via named route
// import '../quiz/kuis_screen.dart'; // DIHAPUS - Hanya digunakan via named route atau belum diimplementasikan

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final AuthService _authService = AuthService();
  final QuizService _quizService = QuizService();
  final ContentProgressService _progressService = ContentProgressService(); // NEW: Inisialisasi Service
  final DatabaseReference _progressRef = FirebaseDatabase.instance.ref('progress'); // NEW: Referensi Progress DB
  
  UserModel? _currentUser;
  final User? firebaseUser = FirebaseAuth.instance.currentUser;

  // Halaman-halaman navigasi
  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    
    // Inisialisasi awal dengan widget
    _widgetOptions = <Widget>[
      _buildDashboardContent(),
      ModulListScreen(), // Halaman Modul (sudah non-const)
      const Center(child: Text('Memuat Daftar Kuis...', style: TextStyle(color: Colors.white))), // Halaman Kuis akan diisi kuis list screen
      ProfileScreen(userModel: _currentUser), // Halaman Profil & Penilaian
    ];
  }

  void _fetchUserData() async {
    if (firebaseUser != null) {
      final user = await _authService.getUserData(firebaseUser!.uid);
      setState(() {
        _currentUser = user;
        // Update widgetOptions dengan userModel yang baru diambil
        _widgetOptions[3] = ProfileScreen(userModel: _currentUser);
        // Memastikan Dashboard content di-refresh setelah data user ada
        _widgetOptions[0] = _buildDashboardContent(); 
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  
  // FUNGSI BARU: Manual date formatting untuk menghindari dependensi 'intl'
  String _formatDate(DateTime date) {
    String day = date.day.toString().padLeft(2, '0');
    String month = date.month.toString().padLeft(2, '0');
    String year = date.year.toString();
    String hour = date.hour.toString().padLeft(2, '0');
    String minute = date.minute.toString().padLeft(2, '0');

    // Format sederhana: DD/MM/YYYY HH:mm
    return "$day/$month/$year, $hour:$minute";
  }


  // Konten Utama Dashboard - SJP, Ringkasan Modul, Kuis Deadline, Tantangan
  Widget _buildDashboardContent() {
    // Menjamin firebaseUser tidak null karena AuthWrapper sudah mengecek
    final String currentUserId = firebaseUser!.uid; 
    
    // Hapus data dummy activeModules
    // const activeModules = [...] 

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Selamat Datang
          Text(
            'Halo, ${_currentUser?.name ?? 'Pengguna'}!',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text(
            'Persona Digital Anda: ${_currentUser?.persona ?? 'Memuat...'}',
            style: const TextStyle(fontSize: 16, color: accentColor),
          ),
          const SizedBox(height: 20),

          // 1. Skor Jejak Publik (SJP)
          _buildSjpCard(_currentUser?.skorJejakPublik ?? 0.0, _currentUser?.persona ?? 'Memuat...'),
          const SizedBox(height: 30),

          // 2. Ringkasan Modul Aktif (Navigasi ke ModulListScreen)
          GestureDetector(
            onTap: () => _onItemTapped(1), // Navigasi ke Tab Modul
            child: _buildSectionTitle('Ringkasan Modul Aktif', showArrow: true),
          ),
          
          // IMPLEMENTASI STREAMBUILDER BARU UNTUK MODUL AKTIF
          StreamBuilder<List<ModulModel>>(
            stream: _progressService.getModules(), // Stream semua modul
            builder: (context, allModulesSnapshot) {
              if (allModulesSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: accentColor));
              }
              if (allModulesSnapshot.hasError) {
                return Text('Error memuat modul: ${allModulesSnapshot.error}', style: const TextStyle(color: Colors.red));
              }

              final allModules = allModulesSnapshot.data ?? [];
              if (allModules.isEmpty) {
                return const Text('Belum ada modul yang tersedia.', style: TextStyle(color: Colors.white70));
              }

              // StreamBuilder 2 (Nested): Ambil semua progress pengguna
              return StreamBuilder<DatabaseEvent>(
                stream: _progressRef.child(currentUserId).onValue, // Menggunakan ID pengguna yang valid
                builder: (context, progressSnapshot) {
                  if (progressSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: Text('Memuat Progres...', style: TextStyle(color: Colors.white70)));
                  }

                  final progressData = (progressSnapshot.data?.snapshot.value as Map<dynamic, dynamic>?)?.cast<String, dynamic>() ?? {};

                  final List<Widget> moduleProgressWidgets = [];

                  for (var modul in allModules) {
                      final moduleProgress = progressData[modul.id] as Map<dynamic, dynamic>?;
                      
                      int progressValue = 0;

                      if (moduleProgress != null) {
                          final isCompleted = moduleProgress['completed'] == true;
                          final unitsMap = (moduleProgress['units'] as Map<dynamic, dynamic>?)?.cast<String, dynamic>() ?? {};
                          
                          // Menghitung unit yang sudah selesai
                          final unitsCompleted = unitsMap.values.where((v) => v == true).length;
                          
                          // Catatan: Karena totalUnits dihapus, kita ASUMSIKAN total unit adalah 4 (berdasarkan UnitModel dummy di lesson_screen.dart)
                          // Ini adalah solusi sementara sampai totalUnits dikembalikan ke ModulModel atau diambil dari sumber lain.
                          const int totalUnitsAssumed = 4; 
                          
                          if (isCompleted) {
                              progressValue = 100;
                          } else if (unitsCompleted > 0 && totalUnitsAssumed > 0) {
                              progressValue = ((unitsCompleted / totalUnitsAssumed) * 100).toInt().clamp(1, 99);
                          }
                      }

                      // Tampilkan hanya modul yang sedang dipelajari (progress > 0)
                      if (progressValue > 0) {
                          moduleProgressWidgets.add(_buildModuleProgressCard(modul.title, progressValue));
                      }
                  }
                  
                  if (moduleProgressWidgets.isEmpty) {
                      return const Text('Mulai pelajari modul pertama Anda!', style: TextStyle(color: Colors.white70));
                  }

                  // Tampilkan maksimal 2 modul aktif di dashboard
                  return Column(children: moduleProgressWidgets.take(2).toList());
                },
              );
            },
          ),
          const SizedBox(height: 30),
          // END OF NEW IMPLEMENTATION

          // 3. Pemberitahuan Kuis Deadline (Sudah menggunakan StreamBuilder dengan _quizService.getActiveQuizzes())
          _buildSectionTitle('Kuis Deadline Mendekat'),
          StreamBuilder<List<QuizModel>>(
            stream: _quizService.getActiveQuizzes(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: accentColor));
              }
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red));
              }
              final quizzes = snapshot.data ?? [];
              if (quizzes.isEmpty) {
                return const Text('Tidak ada kuis aktif saat ini.', style: TextStyle(color: Colors.white70));
              }
              return Column(
                // Ambil maksimal 2 kuis
                children: quizzes.take(2).map((quiz) => _buildQuizDeadlineCard(context, quiz)).toList(),
              );
            },
          ),
          const SizedBox(height: 30),

          // 4. Tantangan Harian "Filter Hoaks" (Sudah mengarah ke Named Route)
          _buildSectionTitle('Tantangan Harian'),
          _buildDailyChallengeCard(context),
        ],
      ),
    );
  }

  // ... sisa widget helper tetap sama ...

  Widget _buildSectionTitle(String title, {bool showArrow = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          if (showArrow)
            const Icon(Icons.arrow_forward, color: Colors.white70, size: 20),
        ],
      ),
    );
  }

  Widget _buildSjpCard(double sjp, String persona) {
    String sjpStatus = sjp > 75 ? 'Sangat Baik' : sjp > 50 ? 'Baik' : 'Perlu Peningkatan';
    Color statusColor = sjp > 75 ? Colors.green : sjp > 50 ? accentColor : Colors.red;

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: secondaryColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(15.0),
        border: Border.all(color: accentColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Skor Jejak Publik (SJP)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                sjp.toStringAsFixed(1),
                style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: statusColor),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Status: $sjpStatus', style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                  Text('Persona: $persona', style: const TextStyle(color: Colors.white70)),
                ],
              )
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: sjp / 100,
            backgroundColor: secondaryColor,
            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleProgressCard(String title, int progress) {
    return Card(
      color: secondaryColor.withOpacity(0.5),
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const Icon(Icons.menu_book, color: accentColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: LinearProgressIndicator(
          value: progress / 100,
          backgroundColor: primaryColor,
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.lightGreen),
        ),
        trailing: Text('$progress%', style: const TextStyle(color: Colors.white70)),
        onTap: () {
          _onItemTapped(1); // Pindah ke tab Modul
        },
      ),
    );
  }

  Widget _buildQuizDeadlineCard(BuildContext context, QuizModel quiz) {
    final remaining = quiz.deadline.difference(DateTime.now());

    return Card(
      color: Colors.red.withOpacity(0.2),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const Icon(Icons.timer, color: Colors.redAccent),
        title: Text(quiz.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        // MENGGUNAKAN FUNGSI MANUAL _formatDate
        subtitle: Text('Deadline: ${_formatDate(quiz.deadline)}'),
        trailing: Text(
          '${remaining.inDays} Hari',
          style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
        ),
        onTap: () {
          // Navigasi ke Halaman Kuis dengan ID kuis (menggunakan named route)
          Navigator.of(context).pushNamed('/quiz', arguments: quiz.id);
        },
      ),
    );
  }

  Widget _buildDailyChallengeCard(BuildContext context) {
    // ID kuis khusus untuk Tantangan Harian. Pastikan ID ini ada di Firebase Realtime Database.
    const dailyChallengeId = 'daily_hoax_challenge'; 
    
    return Card(
      color: accentColor.withOpacity(0.2),
      child: ListTile(
        leading: const Icon(Icons.flash_on, color: accentColor),
        title: const Text('Filter Hoaks - Tantangan Harian'),
        subtitle: const Text('Kenali berita palsu hari ini dan tingkatkan SJP Anda!'),
        trailing: ElevatedButton(
          onPressed: () {
            // Logika Fungsional: Navigasi ke Halaman Kuis dengan ID Tantangan Harian
            // Ini akan memicu rute '/quiz' dan melewatkan ID kuis sebagai argumen.
            Navigator.of(context).pushNamed('/quiz', arguments: dailyChallengeId);
            
            // Tampilkan pesan bahwa tantangan dimulai (opsional)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Memulai Tantangan Harian: Filter Hoaks...')),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          ),
          child: const Text('Mulai'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BIJAK ONLINE DASHBOARD'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: accentColor),
            onPressed: () {
              // Navigasi ke Halaman Notifikasi (menggunakan named route)
              Navigator.of(context).pushNamed('/notifications');
            },
          ),
        ],
      ),
      body: Center(
        // Gunakan IndexedStack untuk mempertahankan state tab
        child: IndexedStack(
          index: _selectedIndex,
          children: _widgetOptions,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books_outlined),
            activeIcon: Icon(Icons.library_books),
            label: 'Modul',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.quiz_outlined),
            activeIcon: Icon(Icons.quiz),
            label: 'Kuis',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: accentColor,
        unselectedItemColor: Colors.white54,
        onTap: _onItemTapped,
        backgroundColor: secondaryColor, // Latar belakang navigasi
        type: BottomNavigationBarType.fixed, // Penting untuk mempertahankan warna/ukuran
      ),
    );
  }
}
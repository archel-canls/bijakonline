// lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../main.dart';
import '../../models/user_model.dart';
import '../../models/quiz_model.dart'; // Import QuizResultModel
import '../../services/auth_service.dart';
import '../../services/quiz_service.dart';

class ProfileScreen extends StatelessWidget {
  final UserModel? userModel;
  // Hapus kata kunci 'const' di sini karena field _quizService dan _authService 
  // diinisialisasi dengan nilai non-konstan (non-const constructor).
  ProfileScreen({super.key, this.userModel});
  
  // Instance services - Inisialisasi non-konstan
  final QuizService _quizService = QuizService();
  final AuthService _authService = AuthService();


  // UI item list diadaptasi dari gambar referensi
  Widget _buildProfileItem(BuildContext context, {required String title, required IconData icon, VoidCallback? onTap, String? trailingText}) {
    return Card(
      color: secondaryColor.withOpacity(0.5),
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: Icon(icon, color: accentColor),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        trailing: trailingText != null 
          ? Text(trailingText, style: const TextStyle(color: Colors.white70))
          : (onTap != null ? const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16) : null),
        onTap: onTap,
      ),
    );
  }

  // Bagian untuk Halaman Penilaian (Ringkasan Skor & Badges)
  Widget _buildScoringSection(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
      return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Halaman Penilaian',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const Divider(color: Colors.white30),
        // Item Penilaian Fungsional
        _buildProfileItem(context, title: 'Skor Per Topik', icon: Icons.leaderboard_outlined, onTap: () {
          // Navigasi ke layar detail skor
          _showScoreDetail(context, userId);
        }),
        _buildProfileItem(context, title: 'Statistik SJP (vs. Rata-rata Persona)', icon: Icons.bar_chart, onTap: () {
          // Navigasi ke layar statistik
          _showStatisticDetail(context);
        }),
        _buildProfileItem(context, title: 'Digital Badge yang Diperoleh', icon: Icons.verified_user, onTap: () {
          // Navigasi ke daftar badge
          _showBadgeList(context);
        }),
        const SizedBox(height: 20),
      ],
    );
  }

  // FUNGSI UNTUK MENAMPILKAN DETAIL SKOR PER TOPIK
  void _showScoreDetail(BuildContext context, String? userId) {
    if (userId == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ringkasan Skor Kuis'),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<List<QuizResultModel>>(
            stream: _quizService.getAllQuizResults(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final results = snapshot.data ?? [];
              if (results.isEmpty) {
                return const Center(child: Text('Belum ada skor kuis tercatat.'));
              }

              return ListView.builder(
                shrinkWrap: true,
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final result = results[index];
                  return ListTile(
                    title: Text(result.quizId), // Seharusnya judul kuis, bukan ID
                    trailing: Text(
                      'Skor: ${result.score}',
                      style: TextStyle(color: result.isPassed ? Colors.green : Colors.red),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Tutup'))],
      ),
    );
  }
  
  // FUNGSI DUMMY UNTUK STATISTIK & BADGE
  void _showStatisticDetail(BuildContext context) {
      showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Statistik SJP'),
        content: Text('SJP Anda: ${userModel?.skorJejakPublik.toStringAsFixed(1) ?? 'N/A'}\n\nRata-rata Persona Digital Anda: 72.5 (Contoh data dummy).'),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Tutup'))],
      ),
    );
  }

  void _showBadgeList(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Digital Badge'),
        content: const Text('Badge yang diperoleh: Master Etika (Contoh), Verified Kritis. (Data badge akan dimuat dari database)'),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Tutup'))],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil & Pengaturan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Profil (Diadaptasi dari desain gambar)
            Row(
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: secondaryColor,
                  child: Icon(Icons.person, size: 50, color: accentColor),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userModel?.name ?? 'Nama Pengguna',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      userModel?.email ?? 'email@contoh.com',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      'Persona: ${userModel?.persona ?? 'Memuat...'}',
                      style: const TextStyle(color: accentColor, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 30),
            
            // Penilaian
            _buildScoringSection(context), 

            const Text(
              'Pengaturan Akun',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const Divider(color: Colors.white30),
            _buildProfileItem(context, title: 'Edit Profil & Persona Digital', icon: Icons.edit_outlined, onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Navigasi ke Edit Profil.')));
            }),
            _buildProfileItem(context, title: 'Ganti Password', icon: Icons.vpn_key_outlined, onTap: () {
              // Simulasikan Ganti Password
              // Catatan: Fungsi updatePassword memerlukan implementasi yang benar di AuthService
              _authService.updatePassword('password_baru').then((_) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password berhasil diupdate! (simulasi)')));
              }).catchError((e) {
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal ganti password: $e')));
              });
            }),
            _buildProfileItem(context, title: 'Pengaturan Notifikasi', icon: Icons.notifications_active_outlined, onTap: () {
              Navigator.of(context).pushNamed('/notifications');
            }),
            const SizedBox(height: 20),

            // Item-item lain yang relevan
            _buildProfileItem(context, title: 'Tentang Kami', icon: Icons.info_outline, onTap: () {}),
            _buildProfileItem(context, title: 'Kebijakan Privasi', icon: Icons.policy_outlined, onTap: () {}),
            _buildProfileItem(context, title: 'Versi App', icon: Icons.system_update_alt, trailingText: '1.0.0'),
            const SizedBox(height: 20),

            // Tombol Logout
            ElevatedButton(
              onPressed: () {
                _authService.signOut();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
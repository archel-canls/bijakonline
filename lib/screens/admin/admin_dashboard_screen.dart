// lib/screens/admin/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import '../../main.dart'; // Untuk warna
import '../../services/auth_service.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Akses pengguna saat ini secara langsung dari FirebaseAuth instance.
    // Karena kita hanya bisa mencapai layar ini jika user sudah login (dicek di AuthWrapper),
    // kita asumsikan currentUser tidak null.
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final AuthService authService = AuthService();
    
    // Walaupun AuthWrapper sudah mengecek Admin, pengecekan ini penting
    // jika kita ingin memastikan logika navigasi di masa depan lebih aman.
    if (currentUser == null || !authService.isAdmin(currentUser)) {
       // Ini adalah fallback. Seharusnya tidak pernah terjadi jika AuthWrapper bekerja.
       // Kita log user out untuk keamanan.
       Future.microtask(() => authService.signOut());
       return const Scaffold(
        body: Center(
          child: Text("Akses Ditolak. Memuat ulang...", style: TextStyle(color: Colors.red, fontSize: 18)),
        ),
      );
    }
    
    // Hapus baris AuthService()._auth.currentUser yang berpotensi null
    // final bool isAdmin = AuthService().isAdmin(AuthService()._auth.currentUser);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ADMIN DASHBOARD', style: TextStyle(color: accentColor)),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => authService.signOut(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selamat Datang, Administrator!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 20),
            
            _buildAdminCard(
              context,
              title: 'Manage User & Persona',
              subtitle: 'Kelola daftar pengguna dan persona digital.',
              icon: Icons.people_alt,
              onTap: () {/* Navigasi ke Halaman Manage User */},
            ),
            _buildAdminCard(
              context,
              title: 'Manage Modul & Kuis',
              subtitle: 'Buat, edit, dan hapus Modul Pembelajaran serta Kuis.',
              icon: Icons.school,
              onTap: () {
                 Navigator.of(context).pushNamed('/admin/manage_module');
              },
            ),
            _buildAdminCard(
              context,
              title: 'Upload Informasi Hoaks Terbaru',
              subtitle: 'Tambahkan data hoaks untuk Tantangan Harian.',
              icon: Icons.campaign,
              onTap: () {/* Navigasi ke Halaman Upload Hoaks */},
            ),
            const SizedBox(height: 30),
            const Text(
              'Analitik Global',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            _buildAnalyticsCard('SJP Rata-rata Global', '65.3'),
            _buildAnalyticsCard('Distribusi Persona', '5 Persona Aktif'),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return Card(
      color: secondaryColor.withOpacity(0.5),
      margin: const EdgeInsets.only(bottom: 15),
      child: ListTile(
        leading: Icon(icon, color: accentColor, size: 30),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white70),
        onTap: onTap,
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(15.0),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: secondaryColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
          Text(value, style: const TextStyle(color: accentColor, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
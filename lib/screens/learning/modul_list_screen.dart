// lib/screens/learning/modul_list_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../main.dart';
import '../../models/modul_model.dart';
import '../../services/content_progress_service.dart';
import 'modul_detail_screen.dart'; // Import ModulDetailScreen

class ModulListScreen extends StatefulWidget {
  ModulListScreen({super.key});

  @override
  State<ModulListScreen> createState() => _ModulListScreenState();
}

class _ModulListScreenState extends State<ModulListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ContentProgressService _progressService = ContentProgressService();
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest_user_id';
  final DatabaseReference _progressRef = FirebaseDatabase.instance.ref('progress');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); 
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Widget untuk menampilkan satu item modul (refactoring)
  Widget _buildModulListItem(BuildContext context, ModulModel modul, {String progressStatus = ''}) {
    Color statusColor = Colors.white70;
    String statusText = '';
    
    if (progressStatus == 'In Progress') {
        statusColor = Colors.orangeAccent;
        statusText = 'Sedang Dipelajari';
    } else if (progressStatus == 'Completed') {
        statusColor = Colors.greenAccent;
        statusText = 'Selesai';
    }

    return Card(
      color: secondaryColor.withOpacity(0.5),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const Icon(Icons.menu_book, color: accentColor),
        title: Text(modul.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Memastikan substring aman jika deskripsi terlalu pendek
            Text('${modul.description.substring(0, modul.description.length > 50 ? 50 : modul.description.length)}...'),
            if (statusText.isNotEmpty) 
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ModulDetailScreen(modul: modul),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // StreamBuilder 1: Ambil semua daftar modul
    return StreamBuilder<List<ModulModel>>(
      stream: _progressService.getModules(),
      builder: (context, moduleSnapshot) {
        if (moduleSnapshot.connectionState == ConnectionState.waiting) {
          // DIHAPUS: const dari Scaffold
          return Scaffold( 
            appBar: AppBar(title: const Text('Daftar Modul Pembelajaran')), // DITAMBAH: const pada Text
            body: const Center(child: CircularProgressIndicator(color: accentColor)),
          );
        }
        if (moduleSnapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Daftar Modul Pembelajaran')),
            body: Center(child: Text('Error memuat modul: ${moduleSnapshot.error}', style: const TextStyle(color: Colors.red))),
          );
        }

        final allModules = moduleSnapshot.data ?? [];
        if (allModules.isEmpty) {
          // DIHAPUS: const dari Scaffold
          return Scaffold( 
            appBar: AppBar(title: const Text('Daftar Modul Pembelajaran')), // DITAMBAH: const pada Text
            body: const Center(child: Text('Belum ada modul yang tersedia.', style: TextStyle(color: Colors.white70))),
          );
        }

        // StreamBuilder 2 (Nested): Ambil semua progress pengguna
        return StreamBuilder<DatabaseEvent>(
          stream: _progressRef.child(_userId).onValue, 
          builder: (context, progressSnapshot) {
            
            final progressData = (progressSnapshot.data?.snapshot.value as Map<dynamic, dynamic>?)?.cast<String, dynamic>() ?? {};

            // --- FILTERING LOGIC ---
            final inProgressModuleIds = progressData.keys.where((moduleId) {
                final moduleProgress = progressData[moduleId] as Map<dynamic, dynamic>?;
                final isStarted = moduleProgress != null;
                final isCompleted = moduleProgress?['completed'] == true; 
                return isStarted && !isCompleted;
            }).toSet();
            
            final modulesInProgress = allModules
                .where((m) => inProgressModuleIds.contains(m.id))
                .toList();

            // --- UI BUILD ---
            
            return Scaffold(
              appBar: AppBar(
                title: const Text('Daftar Modul Pembelajaran'),
                // Menambahkan TabBar di bawah AppBar
                bottom: TabBar(
                  controller: _tabController,
                  indicatorColor: accentColor,
                  labelColor: accentColor,
                  unselectedLabelColor: Colors.white54,
                  tabs: [
                    const Tab(text: 'Semua Modul'),
                    Tab(text: 'Modul Dipelajari (${modulesInProgress.length})'),
                  ],
                ),
              ),
              // Menambahkan TabBarView untuk konten tab
              body: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Semua Modul
                  ListView.builder(
                    padding: const EdgeInsets.all(15.0),
                    itemCount: allModules.length,
                    itemBuilder: (context, index) {
                      final modul = allModules[index];
                      // Tampilkan status jika sedang dipelajari
                      String status = inProgressModuleIds.contains(modul.id) ? 'In Progress' : '';
                      return _buildModulListItem(context, modul, progressStatus: status);
                    },
                  ),

                  // Tab 2: Modul Dipelajari (In Progress)
                  modulesInProgress.isEmpty
                      ? const Center(child: Text('Belum ada modul yang sedang dipelajari.', style: TextStyle(color: Colors.white70)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(15.0),
                          itemCount: modulesInProgress.length,
                          itemBuilder: (context, index) {
                            final modul = modulesInProgress[index];
                            return _buildModulListItem(context, modul, progressStatus: 'In Progress');
                          },
                        ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
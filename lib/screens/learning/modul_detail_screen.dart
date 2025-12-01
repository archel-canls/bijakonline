// lib/screens/learning/modul_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart'; // PASTIKAN package:youtube_player_flutter SUDAH DI-INSTALL

import '../../main.dart';
import '../../models/modul_model.dart';
import '../../services/content_progress_service.dart';
import 'lesson_screen.dart'; 

// Asumsi ModulModel menerima ModulModel
class ModulDetailScreen extends StatefulWidget {
  final ModulModel modul;
  const ModulDetailScreen({super.key, required this.modul});

  @override
  State<ModulDetailScreen> createState() => _ModulDetailScreenState();
}

class _ModulDetailScreenState extends State<ModulDetailScreen> {
  final ContentProgressService _progressService = ContentProgressService();
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest_user_id';
  
  late YoutubePlayerController _ytController;

  @override
  void initState() {
    super.initState();
    // Inisialisasi YouTube Player Controller
    final videoId = YoutubePlayer.convertUrlToId(widget.modul.youtubeUrl);
    _ytController = YoutubePlayerController(
      initialVideoId: videoId ?? 'dQw4w9WgXcQ', // Fallback ID jika URL tidak valid
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
      ),
    );
  }

  @override
  void deactivate() {
    // Memastikan controller di-pause saat widget tidak terlihat
    _ytController.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    // Memastikan controller dibuang saat widget dibuang
    _ytController.dispose();
    super.dispose();
  }

  // Fungsi untuk menandai modul sebagai 'Sedang Dipelajari' (In Progress)
  Future<void> _startLearning() async {
    try {
      // Tandai modul sebagai dimulai di Firebase
      await _progressService.markModuleAsStarted(_userId, widget.modul.id);
      
      // Navigasi ke LessonScreen, mengirimkan objek ModulModel
      if (mounted) {
         // Pastikan video berhenti sebelum pindah
         _ytController.pause();
         
         Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => LessonScreen(modul: widget.modul),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memulai modul: $e')));
      }
    }
  }

  // Widget opsional untuk informasi kuis terkait
  Widget _buildQuizInfo(BuildContext context, String quizId) {
    return Card(
      color: secondaryColor.withOpacity(0.5),
      margin: const EdgeInsets.only(bottom: 10.0),
      child: ListTile(
        leading: const Icon(Icons.quiz, color: accentColor),
        title: const Text('Kuis Terkait Tersedia', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text('ID Kuis: $quizId', style: const TextStyle(color: Colors.white70)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white70),
        onTap: () {
          // Navigasi ke KuisScreen menggunakan Named Route
          Navigator.of(context).pushNamed('/quiz', arguments: quizId);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.modul.title),
        backgroundColor: primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Konten Video YouTube
            YoutubePlayer(
              controller: _ytController,
              showVideoProgressIndicator: true,
              progressIndicatorColor: accentColor,
              onReady: () {
                // Controller siap
              },
            ),

            const SizedBox(height: 15),
            Text(
              widget.modul.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(
              widget.modul.description,
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 20),
            
            // Tombol "Pelajari Sekarang"
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _startLearning,
                icon: const Icon(Icons.menu_book),
                label: const Text(
                  'PELAJARI SEKARANG',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: accentColor,
                  foregroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
              ),
            ),
            
            const SizedBox(height: 30),

            // Opsi Kuis Terkait
            if (widget.modul.quizId != null && widget.modul.quizId!.isNotEmpty)
              _buildQuizInfo(context, widget.modul.quizId!),
          ],
        ),
      ),
    );
  }
}
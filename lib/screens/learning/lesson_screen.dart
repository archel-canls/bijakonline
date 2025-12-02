import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle; // Diperlukan untuk memuat assets
import 'package:firebase_auth/firebase_auth.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'dart:convert'; // Diperlukan untuk base64Decode
import 'dart:typed_data'; // Diperlukan untuk tipe data byte
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../main.dart';
import '../../models/modul_model.dart';
import '../../services/content_progress_service.dart';

// Fungsi Helper untuk mendapatkan Video ID dari URL YouTube
String? convertUrlToId(String url) {
  if (url.contains("youtu.be")) {
    // Mengambil ID dari URL youtu.be/ID
    return url.split('/').last.split('?').first;
  }
  // Mengambil ID dari URL watch?v=ID
  return url.contains("v=") ? url.split("v=")[1].split("&").first : null;
}

// Model Sederhana untuk Unit Pembelajaran
class UnitModel {
  final String title;
  final String type; // 'video', 'teks', 'simulasi', 'pdf'
  final String duration;
  final String contentUrl; // URL konten (misal: URL video ID, path teks, dll.)

  UnitModel({
    required this.title,
    required this.type,
    required this.duration,
    required this.contentUrl,
  });
}

// Data dummy unit
final List<UnitModel> dummyUnits = [
  // Unit Video (ContentUrl hanya placeholder, ID video diambil dari ModulModel)
  UnitModel(title: 'Unit 1: Tontonan Pengantar Modul', type: 'video', duration: '5 Menit', contentUrl: 'placeholder'),
  // Unit PDF (Material)
  UnitModel(title: 'Unit 2: Materi Lengkap PDF', type: 'pdf', duration: '10 Menit', contentUrl: 'material_pdf'),
  // Unit Teks
  UnitModel(title: 'Unit 3: Mengenal Hoaks', type: 'teks', duration: '10 Menit', contentUrl: 'Isi teks panjang tentang hoaks...'),
  // Unit Simulasi
  UnitModel(title: 'Unit 4: Keamanan Data Dasar', type: 'simulasi', duration: '8 Menit', contentUrl: 'Latihan membedakan hoaks'),
];


class LessonScreen extends StatefulWidget {
  final ModulModel modul;
  // Menghapus initialUnitIndex
  const LessonScreen({super.key, required this.modul});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  final ContentProgressService _progressService = ContentProgressService(); 
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest_user_id';

  // Menghapus _currentUnitIndex
  late YoutubePlayerController _youtubeController; 
  String? _pdfErrorMessage;
  Uint8List? _currentPdfBytes; 
  String _pdfSource = 'Base64'; 
  
  static const String _fallbackPdfPath = 'assets/pdf/materi_cadangan.pdf';

  @override
  void initState() {
    super.initState();
    // Panggil fungsi untuk memuat PDF jika ada unit PDF
    if (dummyUnits.any((unit) => unit.type == 'pdf')) {
        _loadPdfForUnit();
    }

    // Inisialisasi YoutubePlayerController
    final videoId = convertUrlToId(widget.modul.youtubeUrl);
    _youtubeController = YoutubePlayerController(
      initialVideoId: videoId ?? '', 
      flags: const YoutubePlayerFlags(
        autoPlay: false, 
        mute: false,
        loop: false, 
      ),
    );
  }

  // Fungsi untuk memuat PDF dari Base64 atau Asset (sama seperti sebelumnya)
  Future<void> _loadPdfForUnit() async {
    // Reset state sebelum memuat yang baru
    setState(() {
      _currentPdfBytes = null;
      _pdfErrorMessage = null;
      _pdfSource = 'Base64';
    });

    // 1. Coba dari Base64
    if (widget.modul.materialBase64 != null && widget.modul.materialBase64!.isNotEmpty) {
      try {
        final Uint8List pdfBytes = base64Decode(widget.modul.materialBase64!);
        if (mounted) {
          setState(() {
            _currentPdfBytes = pdfBytes;
            _pdfSource = 'Base64';
          });
        }
        return; // Berhasil dimuat dari Base64, selesai
      } catch (e) {
        // Gagal memproses Base64, log dan coba Fallback
        debugPrint('Gagal mendekode Base64 PDF: $e');
        if (mounted) {
          setState(() {
            _pdfErrorMessage = 'Gagal memuat dari Base64. Mencoba file cadangan...';
          });
        }
      }
    } else {
        // Base64 tidak tersedia
        if (mounted) {
          setState(() {
            _pdfErrorMessage = 'Base64 PDF tidak tersedia. Mencoba file cadangan...';
          });
        }
    }

    // 2. Coba dari Asset (Fallback)
    try {
      final ByteData data = await rootBundle.load(_fallbackPdfPath);
      final Uint8List assetBytes = data.buffer.asUint8List();
      if (mounted) {
        setState(() {
          _currentPdfBytes = assetBytes;
          _pdfSource = 'Asset Cadangan';
          _pdfErrorMessage = null; // Hapus pesan error Base64
        });
      }
    } catch (e) {
      // Gagal memuat dari Base64 dan Asset
      debugPrint('Gagal memuat PDF dari Asset: $e');
      if (mounted) {
        setState(() {
          _currentPdfBytes = null;
          _pdfErrorMessage = 'Gagal total memuat PDF: Base64 error dan Asset Cadangan tidak dapat dimuat atau tidak ditemukan di $_fallbackPdfPath';
          _pdfSource = 'Error';
        });
      }
    }
  }


  @override
  void didUpdateWidget(covariant LessonScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.modul.youtubeUrl != oldWidget.modul.youtubeUrl) {
      final videoId = convertUrlToId(widget.modul.youtubeUrl);
      _youtubeController.load(videoId ?? '');
    }
  }


  @override
  void dispose() {
    _youtubeController.dispose(); // Hapus controller saat widget dibuang
    super.dispose();
  }

  // Fungsi untuk menandai SEMUA unit sebagai selesai saat tombol 'Selesai' ditekan
  Future<void> _markAllUnitsAsCompleted() async {
    // Tandai semua unit sebagai selesai 
    for (int i = 0; i < dummyUnits.length; i++) {
        await _progressService.markUnitCompleted(
            _userId,
            widget.modul.id,
            i // Mengirim index unit (0, 1, 2, ...)
        );
    }
    // TODO: Tambahkan logika final markModuleAsCompleted jika diperlukan di ContentProgressService
  }

  // Widget untuk menampilkan konten PDF (sama seperti sebelumnya, namun diintegrasikan dalam scroll view)
  Widget _buildPdfContent(UnitModel unit) {
    // 1. Tampilkan indicator jika sedang loading atau belum dimuat
    if (_currentPdfBytes == null && _pdfErrorMessage == null) {
      // Panggil loadPdf jika belum dimuat (walaupun sudah dipanggil di initState, ini sebagai safeguard)
      if (unit.type == 'pdf' && _currentPdfBytes == null) {
          Future.microtask(_loadPdfForUnit);
      }
      return const Center(child: CircularProgressIndicator(color: accentColor));
    }
    
    Widget pdfViewer;
    
    // 2. Tampilkan pesan error
    if (_pdfErrorMessage != null) {
      pdfViewer = Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
              const SizedBox(height: 10),
              Text(
                'Gagal memuat PDF: $_pdfErrorMessage',
                style: const TextStyle(color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text('Sumber yang dicoba: $_pdfSource', style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      );
    } 
    // 3. Tampilkan PDF Viewer
    else if (_currentPdfBytes != null) {
      pdfViewer = SfPdfViewer.memory(
        _currentPdfBytes!, // Menggunakan bytes yang sudah dimuat (Base64 atau Asset)
        onDocumentLoadFailed: (details) {
          debugPrint('SfPdfViewer Gagal Memuat PDF: ${details.description}');
          setState(() {
            _pdfErrorMessage = 'SfPdfViewer Gagal Memuat Dokumen: ${details.description}';
            _pdfSource = 'Error pada $_pdfSource';
            _currentPdfBytes = null; 
          });
        },
      );
    }
    // 4. Kasus sisa
    else {
      pdfViewer = const Center(child: Text('Konten PDF tidak tersedia.', style: TextStyle(color: Colors.white70)));
    }


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Materi Lengkap PDF:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        Text('Sumber: $_pdfSource', style: const TextStyle(fontSize: 14, color: Colors.white70)),
        const SizedBox(height: 10),
        
        // Container yang menampilkan Viewer atau Error Widget
        // Tinggi diset 600 untuk memastikan SfPdfViewer memiliki dimensi yang cukup
        Container(
          height: 600, 
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: accentColor.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: pdfViewer,
        ),
        
        const SizedBox(height: 15),
        const Text('Deskripsi Unit:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        Text(unit.title, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }

  // Widget untuk menampilkan konten video (YouTube Player)
  Widget _buildVideoContent(UnitModel unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pemutar Video YouTube
        _youtubeController.initialVideoId.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Text('Video URL modul tidak valid.', style: TextStyle(color: Colors.redAccent)),
              ),
            )
          : YoutubePlayer(
              key: ValueKey(widget.modul.youtubeUrl), 
              controller: _youtubeController,
              showVideoProgressIndicator: true,
              progressIndicatorColor: accentColor,
              onReady: () {
                debugPrint('YouTube Player Ready!');
              },
            ),

        const SizedBox(height: 15),
        
        // Tombol Play/Pause untuk kontrol manual
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Builder(
              builder: (context) {
                return ElevatedButton.icon(
                  onPressed: () {
                    _youtubeController.value.isPlaying
                        ? _youtubeController.pause()
                        : _youtubeController.play();
                    // SetState diperlukan untuk memperbarui ikon/teks tombol
                    setState(() {});
                  },
                  icon: Icon(
                    _youtubeController.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: primaryColor,
                  ),
                  label: Text(
                    _youtubeController.value.isPlaying ? 'Jeda Video' : 'Putar Video',
                    style: const TextStyle(color: primaryColor),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                  ),
                );
              }
            ),
          ],
        ),

        const SizedBox(height: 15),
        const Text('Deskripsi Unit:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        Text(unit.title, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }


  // Fungsi untuk menampilkan konten unit (video/teks/simulasi/pdf)
  Widget _buildUnitContent(UnitModel unit) {
    switch (unit.type) {
      case 'video':
        return _buildVideoContent(unit); 
      case 'pdf':
        return _buildPdfContent(unit); 
      case 'teks':
      case 'simulasi':
      default:
        // Untuk tipe 'teks', 'simulasi' atau lainnya
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Materi Pembelajaran:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 10),
            Text(
              unit.contentUrl,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        );
    }
  }

  // Widget baru untuk menggabungkan semua konten unit dalam satu scroll
  Widget _buildAllUnitContent() {
      // Pastikan PDF dimuat di awal jika ada unit bertipe 'pdf'
      if (dummyUnits.any((unit) => unit.type == 'pdf') && _currentPdfBytes == null && _pdfErrorMessage == null) {
          Future.microtask(_loadPdfForUnit);
      }
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        // List.generate digunakan untuk membuat daftar konten dengan Divider
        children: List.generate(dummyUnits.length, (index) {
          final unit = dummyUnits[index];
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Judul Unit sebagai Header Konten
              Padding(
                // Atur padding atas hanya jika bukan unit pertama
                padding: EdgeInsets.only(top: index == 0 ? 0.0 : 25.0, bottom: 10.0),
                child: Text(
                  // Menghapus Judul Unit di sini karena sudah ada di dalam _buildUnitContent
                  '${unit.title}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: accentColor),
                ),
              ),
              // Konten Unit
              _buildUnitContent(unit),
            ],
          );
          
          // Tambahkan Divider setelah setiap unit kecuali yang terakhir untuk memisahkan konten
          if (index < dummyUnits.length - 1) {
            return Column(
              children: [
                content,
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Divider(color: secondaryColor, thickness: 1),
                ),
              ],
            );
          }
          
          return content;
        }),
      );
    }


  @override
  Widget build(BuildContext context) {
    // Pause video saat widget direbuild
    if (_youtubeController.value.isPlaying) {
      _youtubeController.pause();
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.modul.title),
        backgroundColor: primaryColor,
      ),
      body: Column(
        children: [
          // Menghapus Bar Progress

          // Konten Semua Unit (Scrollable)
          Expanded(
            child: SingleChildScrollView( 
              padding: const EdgeInsets.all(15.0),
              child: _buildAllUnitContent(), // Menampilkan semua unit secara berurutan
            ),
          ),

          // Tombol Selesai Modul (hanya satu tombol)
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                    _youtubeController.pause(); // Pause video
                    await _markAllUnitsAsCompleted(); // Tandai semua unit selesai
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Selamat! Modul Selesai.')),
                    );
                    Navigator.pop(context); // Kembali ke Modul Detail
                  },
                icon: const Icon(Icons.flag),
                label: const Text('Selesai Modul', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, // Warna Selesai
                  foregroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// lib/screens/learning/lesson_screen.dart
import 'dart:io'; // Hanya digunakan di non-web
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Impor kIsWeb untuk cek platform
import 'package:path_provider/path_provider.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:url_launcher/url_launcher.dart'; // Impor url_launcher

import '../../main.dart';
import '../../models/modul_model.dart';

class LessonScreen extends StatefulWidget {
  final ModulModel modul;

  const LessonScreen({super.key, required this.modul});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  // Gunakan String dummy untuk menandai success di web
  String? _pdfPath; 
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPdfFromBase64();
  }

  Future<void> _loadPdfFromBase64() async {
    if (widget.modul.materialBase64 == null || widget.modul.materialBase64!.isEmpty) {
      setState(() {
        _isLoading = false;
        _pdfPath = null;
      });
      return;
    }

    try {
      if (kIsWeb) {
        // --- LOGIKA KHUSUS UNTUK WEB ---
        final pdfUri = 'data:application/pdf;base64,${widget.modul.materialBase64!}';
        final uri = Uri.parse(pdfUri);

        if (await canLaunchUrl(uri)) {
          // Buka Base64 PDF di tab browser baru
          await launchUrl(uri, mode: LaunchMode.externalApplication);

          if (mounted) {
            // Tandai berhasil dimuat di web (walaupun hanya membuka tab)
            setState(() {
              _pdfPath = 'WEB_LOADED'; 
              _isLoading = false;
            });
          }
        } else {
          throw Exception('Gagal membuka Data URI PDF di browser.');
        }

      } else {
        // --- LOGIKA UNTUK MOBILE (iOS/Android) ---
        // 1. Decode Base64 menjadi bytes
        final bytes = base64Decode(widget.modul.materialBase64!);

        // 2. Dapatkan direktori sementara (hanya didukung di Mobile)
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/${widget.modul.id}_${DateTime.now().millisecondsSinceEpoch}.pdf');

        // 3. Tulis bytes ke file sementara
        await file.writeAsBytes(bytes, flush: true);

        // 4. Update state dengan path file
        setState(() {
          _pdfPath = file.path;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Tangani error, terutama di Web jika launchUrl gagal
      if (mounted) {
        // Cek kembali jika Base64 mungkin tidak valid PDF
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat materi PDF. Pastikan Base64 valid dan package sudah terinstal: $e')),
        );
      }
      setState(() {
        _isLoading = false;
        _pdfPath = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Materi: ${widget.modul.title}'),
        backgroundColor: primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: accentColor))
          : _pdfPath != null
              ? kIsWeb 
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.open_in_new, size: 50, color: Colors.blueAccent),
                          SizedBox(height: 10),
                          Text(
                            'Materi PDF telah dibuka di tab browser baru.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : PDFView(
                      // PDFView hanya dijalankan di Mobile
                      filePath: _pdfPath,
                      enableSwipe: true,
                      swipeHorizontal: false, // Gulir vertikal
                      autoSpacing: true,
                      pageFling: true,
                      pageSnap: true,
                      defaultPage: 0,
                      fitPolicy: FitPolicy.WIDTH,
                      preventLinkNavigation: false,
                      onError: (error) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error rendering PDF: $error')),
                          );
                        }
                      },
                    )
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Ikon yang sudah diperbaiki
                        const Icon(
                          Icons.info_outline, 
                          size: 50, 
                          color: Colors.redAccent
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Materi PDF tidak tersedia atau gagal dimuat untuk modul: ${widget.modul.title}. Coba periksa koneksi atau validasi data Base64.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
// lib/screens/notification/notification_screen.dart
import 'package:flutter/material.dart';
import '../../main.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Implementasi: Daftar notifikasi (Kuis deadline, informasi terbaru, dll.)
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pemberitahuan'),
      ),
      body: Center(
        child: Text(
          'Daftar notifikasi ada di sini.',
          style: TextStyle(color: accentColor.withOpacity(0.8)),
        ),
      ),
    );
  }
}
// lib/services/notification_service.dart
import 'package:firebase_database/firebase_database.dart';
import '../models/notification_model.dart';

class NotificationService {
  final DatabaseReference _notifRef = FirebaseDatabase.instance.ref('notifications');

  // Ambil semua notifikasi untuk user
  Stream<List<NotificationModel>> getNotifications(String userId) {
    // Misal notifikasi disimpan di /notifications/{userId}
    return _notifRef.child(userId).onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];
      
      List<NotificationModel> notifications = [];
      data.forEach((key, value) {
        notifications.add(NotificationModel.fromMap(Map<String, dynamic>.from(value as Map), key.toString()));
      });
      
      // Sort berdasarkan waktu terbaru
      notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return notifications;
    });
  }
}
// lib/models/notification_model.dart
class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> data, String id) {
    final timestampData = data['timestamp'];
    DateTime timestamp;

    // Perbaikan: Cek apakah data adalah int (dari ServerValue.timestamp)
    if (timestampData is int) {
      timestamp = DateTime.fromMillisecondsSinceEpoch(timestampData);
    } else {
      // Fallback: Jika string (ISO 8601) atau null
      timestamp = DateTime.tryParse(timestampData ?? '') ?? DateTime.now();
    }
    
    return NotificationModel(
      id: id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      timestamp: timestamp,
      isRead: data['isRead'] ?? false,
    );
  }
}
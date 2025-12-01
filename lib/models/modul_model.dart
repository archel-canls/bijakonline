// lib/models/modul_model.dart

class ModulModel {
  final String id;
  final String title;
  final String description;

  // Field Konten
  final String youtubeUrl;
  final String? materialBase64; 
  final String? quizId; 

  ModulModel({
    required this.id,
    required this.title,
    required this.description,
    required this.youtubeUrl, 
    this.materialBase64,
    this.quizId,
  });

  factory ModulModel.fromMap(Map<String, dynamic> data, String id) {
    return ModulModel(
      id: id,
      title: data['title'] ?? 'Modul Tanpa Judul',
      description: data['description'] ?? '',
      
      // Menerima data konten baru
      youtubeUrl: data['youtubeUrl'] ?? '',
      materialBase64: data['materialBase64'] as String?,
      quizId: data['quizId'] as String?,
    );
  }

  // Helper method untuk konversi ke Map (untuk penyimpanan ke Realtime DB)
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      // Konten
      'youtubeUrl': youtubeUrl,
      'materialBase64': materialBase64,
      'quizId': quizId,
    };
  }
}
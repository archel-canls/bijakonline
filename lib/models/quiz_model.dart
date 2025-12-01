// lib/models/quiz_model.dart

class QuizModel {
  final String id;
  final String title;
  final String moduleId;
  final DateTime deadline;
  final int totalQuestions;
  final String description; 

  QuizModel({
    required this.id,
    required this.title,
    required this.moduleId,
    required this.deadline,
    required this.totalQuestions,
    required this.description,
  });

  // Helper method untuk konversi ke Map
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'moduleId': moduleId,
      // Deadline biasanya disimpan sebagai String ISO 8601 untuk keterbacaan
      'deadline': deadline.toIso8601String(), 
      'totalQuestions': totalQuestions,
      'description': description,
    };
  }

  factory QuizModel.fromMap(Map<String, dynamic> data, String id) {
    final deadlineData = data['deadline'];
    DateTime deadline;

    if (deadlineData is int) {
      deadline = DateTime.fromMillisecondsSinceEpoch(deadlineData);
    } else {
      deadline = DateTime.tryParse(deadlineData ?? '') ?? DateTime.now().add(const Duration(days: 7));
    }

    return QuizModel(
      id: id,
      title: data['title'] ?? 'Kuis Baru',
      moduleId: data['moduleId'] ?? '',
      deadline: deadline,
      totalQuestions: data['totalQuestions'] ?? 0,
      description: data['description'] ?? 'Ukur pemahaman Anda tentang topik ini.',
    );
  }
}

// Model untuk setiap pertanyaan kuis
class QuestionModel {
  final String id;
  final String text;
  final List<String> options;
  final int correctAnswerIndex; // Index jawaban yang benar (0, 1, 2, ...)
  final String explanation; // Umpan Balik Instan

  QuestionModel({
    required this.id,
    required this.text,
    required this.options,
    required this.correctAnswerIndex,
    required this.explanation,
  });
  
  // Helper method untuk konversi ke Map
  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'explanation': explanation,
    };
  }

  factory QuestionModel.fromMap(Map<String, dynamic> data, String id) {
    return QuestionModel(
      id: id,
      text: data['text'] ?? 'Pertanyaan tanpa teks',
      options: List<String>.from(data['options'] ?? []),
      correctAnswerIndex: (data['correctAnswerIndex'] as num?)?.toInt() ?? 0,
      explanation: data['explanation'] ?? 'Tidak ada penjelasan.',
    );
  }
}

// Model untuk menyimpan hasil pengerjaan kuis oleh pengguna
class QuizResultModel {
  final String quizId;
  final String userId;
  final int score;
  final DateTime timestamp;
  final Map<String, int> userAnswers; // {questionId: selectedOptionIndex}
  final bool isPassed;

  QuizResultModel({
    required this.quizId,
    required this.userId,
    required this.score,
    required this.timestamp,
    required this.userAnswers,
    required this.isPassed,
  });
  
  // 🔥🔥🔥 PERBAIKAN UTAMA UNTUK ERROR toMap() 🔥🔥🔥
  Map<String, dynamic> toMap() {
    return {
      'quizId': quizId, 
      'userId': userId, 
      'score': score,
      // Simpan timestamp sebagai milidetik (int)
      'timestamp': timestamp.millisecondsSinceEpoch, 
      'userAnswers': userAnswers,
      'isPassed': isPassed,
    };
  }

  factory QuizResultModel.fromMap(Map<String, dynamic> data) {
    final timestampData = data['timestamp'];

    // Perbaikan: Menangani data timestamp yang bisa berupa int (milidetik) dari ServerValue.timestamp
    DateTime timestamp;
    if (timestampData is int) {
      timestamp = DateTime.fromMillisecondsSinceEpoch(timestampData);
    } else {
      // Fallback
      timestamp = DateTime.tryParse(timestampData ?? '') ?? DateTime.now();
    }
    
    return QuizResultModel(
      quizId: data['quizId'] ?? '',
      userId: data['userId'] ?? '',
      score: (data['score'] as num?)?.toInt() ?? 0,
      timestamp: timestamp, 
      userAnswers: Map<String, int>.from(data['userAnswers'] ?? {}),
      isPassed: data['isPassed'] ?? false,
    );
  }
}
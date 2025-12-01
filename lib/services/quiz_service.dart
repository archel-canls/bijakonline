import 'package:firebase_database/firebase_database.dart';
import '../models/quiz_model.dart';

class QuizService {
  final DatabaseReference _quizRef = FirebaseDatabase.instance.ref('quizzes');
  final DatabaseReference _questionRef = FirebaseDatabase.instance.ref('questions');
  final DatabaseReference _scoreRef = FirebaseDatabase.instance.ref('scores');

  // --- Fungsionalitas Pengguna (Baca) ---
  
  // Ambil kuis aktif (deadline > sekarang)
  Stream<List<QuizModel>> getActiveQuizzes() {
    return _quizRef.onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];
      
      List<QuizModel> quizzes = [];
      data.forEach((key, value) {
        final quiz = QuizModel.fromMap(Map<String, dynamic>.from(value as Map), key.toString());
        // Hanya tampilkan kuis yang belum melewati deadline
        if (quiz.deadline.isAfter(DateTime.now())) {
            quizzes.add(quiz);
        }
      });
      return quizzes;
    });
  }
  
  // Ambil detail pertanyaan untuk kuis tertentu
  Future<List<QuestionModel>> getQuestionsForQuiz(String quizId) async {
    final snapshot = await _questionRef.child(quizId).get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];
      
      List<QuestionModel> questions = [];
      data.forEach((key, value) {
        questions.add(QuestionModel.fromMap(Map<String, dynamic>.from(value as Map), key.toString()));
      });
      return questions;
    }
    return [];
  }

  // Ambil hasil kuis pengguna
  Future<QuizResultModel?> getQuizResult(String userId, String quizId) async {
      final snapshot = await _scoreRef.child(userId).child(quizId).get();
      if (snapshot.exists) {
        return QuizResultModel.fromMap(Map<String, dynamic>.from(snapshot.value as Map));
      }
      return null;
  }

  // Ambil semua hasil kuis pengguna untuk Halaman Penilaian
  Stream<List<QuizResultModel>> getAllQuizResults(String userId) {
    return _scoreRef.child(userId).onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];
      
      List<QuizResultModel> results = [];
      data.forEach((quizId, value) {
        // Asumsi struktur data di RTDB adalah: /scores/{userId}/{quizId}/{result_data}
        final resultData = Map<String, dynamic>.from(value as Map);
        // Tambahkan quizId dan userId ke data agar model bisa diinisialisasi
        resultData['quizId'] = quizId;
        resultData['userId'] = userId;
        results.add(QuizResultModel.fromMap(resultData));
      });
      return results;
    });
  }


  // Simpan hasil kuis & Update SJP (Halaman Kuis - Fungsionalitas Utama)
  Future<void> submitQuiz(String userId, String quizId, int finalScore, Map<String, int> userAnswers) async {
    final result = QuizResultModel(
      quizId: quizId,
      userId: userId,
      score: finalScore,
      timestamp: DateTime.now(),
      userAnswers: userAnswers,
      isPassed: finalScore >= 70, // Contoh: Lulus jika skor >= 70
    );
    
    // Simpan hasil kuis ke /scores/{userId}/{quizId}
    await _scoreRef.child(userId).child(quizId).set(result.toMap());
    
    // Logic untuk Update SJP (Perlu diimplementasikan di UserService atau di sini)
    // Untuk saat ini, kita akan mengasumsikan ada logika terpisah untuk update SJP.
    // Contoh: await _updateSJP(userId, finalScore);
    print('Kuis $quizId disubmit. Skor: $finalScore. SJP perlu diupdate.');
  }

  // --- Fungsionalitas Admin (CRUD) ---

  // Ambil semua kuis (untuk admin)
  Stream<List<QuizModel>> getAllQuizzesForAdmin() {
    return _quizRef.onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];
      
      List<QuizModel> quizzes = [];
      data.forEach((key, value) {
        quizzes.add(QuizModel.fromMap(Map<String, dynamic>.from(value as Map), key.toString()));
      });
      return quizzes;
    });
  }

  // Buat/Update Kuis Baru
  Future<void> saveQuiz(QuizModel quiz) async {
    if (quiz.id.isEmpty) {
      // Buat baru
      final newRef = _quizRef.push();
      await newRef.set({
        'title': quiz.title,
        'moduleId': quiz.moduleId,
        'deadline': quiz.deadline.toIso8601String(),
        'totalQuestions': quiz.totalQuestions,
        'description': quiz.description,
      });
    } else {
      // Update
      await _quizRef.child(quiz.id).update({
        'title': quiz.title,
        'moduleId': quiz.moduleId,
        'deadline': quiz.deadline.toIso8601String(),
        'totalQuestions': quiz.totalQuestions,
        'description': quiz.description,
      });
    }
  }

  // Hapus Kuis
  Future<void> deleteQuiz(String quizId) async {
    await _quizRef.child(quizId).remove();
    // Opsional: Hapus juga semua pertanyaan dan skor terkait
    await _questionRef.child(quizId).remove();
  }

  // Simpan Pertanyaan Kuis (Admin)
  Future<void> saveQuestion(String quizId, QuestionModel question) async {
    final Map<String, dynamic> data = {
      'text': question.text,
      'options': question.options,
      'correctAnswerIndex': question.correctAnswerIndex,
      'explanation': question.explanation,
    };
    
    if (question.id.isEmpty) {
      // Buat baru
      await _questionRef.child(quizId).push().set(data);
    } else {
      // Update
      await _questionRef.child(quizId).child(question.id).update(data);
    }
  }
}
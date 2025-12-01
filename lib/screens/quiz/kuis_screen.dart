// lib/screens/quiz/kuis_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../main.dart';
import '../../models/quiz_model.dart';
import '../../services/quiz_service.dart';

class KuisScreen extends StatefulWidget {
  final String quizId;

  // Di dashboard akan dinavigasikan ke sini
  const KuisScreen({super.key, required this.quizId});

  @override
  State<KuisScreen> createState() => _KuisScreenState();
}

class _KuisScreenState extends State<KuisScreen> {
  final QuizService _quizService = QuizService();
  // Pastikan user sudah login sebelum menggunakan .currentUser!
  final String _userId = FirebaseAuth.instance.currentUser!.uid; 
  
  late Future<List<QuestionModel>> _questionsFuture; // Future untuk pertanyaan kuis
  Map<String, int> _userAnswers = {}; // {questionId: selectedOptionIndex}
  int _currentQuestionIndex = 0;
  QuizModel? _quizDetail;
  QuizResultModel? _quizResult;

  @override
  void initState() {
    super.initState();
    // 1. Inisialisasi _questionsFuture secara sinkron di initState
    _questionsFuture = _quizService.getQuestionsForQuiz(widget.quizId); 
    // 2. Panggil fungsi terpisah untuk memuat hasil kuis sebelumnya
    _loadQuizResult();
  }

  // Fungsi khusus untuk memuat hasil kuis sebelumnya
  void _loadQuizResult() async {
    try {
      final result = await _quizService.getQuizResult(_userId, widget.quizId);
      
      setState(() {
        _quizResult = result;
        // _quizDetail = detail;
      });
    } catch (e) {
      // Handle error pemuatan result jika perlu
      print('Error memuat hasil kuis: $e');
    }
  }

  void _answerQuestion(String questionId, int selectedIndex) {
    setState(() {
      _userAnswers[questionId] = selectedIndex;
    });
  }

  void _nextQuestion(List<QuestionModel> questions) {
    // Cek apakah semua pertanyaan sudah dijawab sebelum pindah ke pertanyaan berikutnya atau submit
    if (_userAnswers.containsKey(questions[_currentQuestionIndex].id)) {
      if (_currentQuestionIndex < questions.length - 1) {
        setState(() {
          _currentQuestionIndex++;
        });
      } else {
        _submitQuiz(questions);
      }
    } else {
      // Tampilkan peringatan jika pengguna mencoba melompat tanpa menjawab
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda harus memilih jawaban sebelum melanjutkan.')),
      );
    }
  }

  void _submitQuiz(List<QuestionModel> questions) async {
    int correctCount = 0;
    
    for (var i = 0; i < questions.length; i++) {
      final question = questions[i];
      final userAnswer = _userAnswers[question.id];
      if (userAnswer != null && userAnswer == question.correctAnswerIndex) {
        correctCount++;
      }
    }
    
    final finalScore = (correctCount / questions.length * 100).round();
    
    await _quizService.submitQuiz(_userId, widget.quizId, finalScore, _userAnswers);
    
    // Tampilkan hasil dan umpan balik
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kuis Selesai!'),
        content: Text('Skor Anda: $finalScore. Anda menjawab $correctCount dari ${questions.length} pertanyaan dengan benar.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Muat ulang hasil kuis setelah submit. Gunakan _loadQuizResult() yang baru.
              _loadQuizResult(); 
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_quizDetail?.title ?? 'Kuis Interaktif'),
      ),
      // FutureBuilder sekarang hanya mengurus pemuatan pertanyaan kuis
      body: FutureBuilder<List<QuestionModel>>(
        future: _questionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: accentColor));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error memuat kuis: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }
          
          final questions = snapshot.data ?? [];
          if (questions.isEmpty) {
            return const Center(child: Text('Kuis belum memiliki pertanyaan.', style: TextStyle(color: Colors.white70)));
          }

          // Cek hasil kuis di sini (di luar FutureBuilder agar bisa diupdate oleh _loadQuizResult)
          if (_quizResult != null) {
            return _buildResultScreen(questions);
          }
          
          final currentQuestion = questions[_currentQuestionIndex];
          
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pertanyaan ${_currentQuestionIndex + 1} dari ${questions.length}',
                  style: const TextStyle(color: accentColor, fontSize: 16),
                ),
                const SizedBox(height: 10),
                Text(
                  currentQuestion.text,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Divider(color: Colors.white30),
                Expanded(
                  child: ListView.builder(
                    itemCount: currentQuestion.options.length,
                    itemBuilder: (context, index) {
                      final isSelected = _userAnswers[currentQuestion.id] == index;
                      return Card(
                        color: isSelected ? accentColor.withOpacity(0.3) : secondaryColor.withOpacity(0.5),
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          title: Text(currentQuestion.options[index], style: const TextStyle(color: Colors.white)),
                          leading: Radio<int>(
                            value: index,
                            groupValue: _userAnswers[currentQuestion.id],
                            onChanged: (int? value) {
                              if (value != null) _answerQuestion(currentQuestion.id, value);
                            },
                            activeColor: accentColor,
                          ),
                          onTap: () => _answerQuestion(currentQuestion.id, index),
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentQuestionIndex > 0)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _currentQuestionIndex--;
                          });
                        },
                        child: const Text('Sebelumnya', style: TextStyle(color: Colors.white70)),
                      ),
                    ElevatedButton(
                      // Panggil _nextQuestion (yang sekarang memiliki logic untuk cek jawaban)
                      onPressed: () => _nextQuestion(questions), 
                      child: Text(_currentQuestionIndex == questions.length - 1 ? 'Selesai & Submit' : 'Lanjut'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  // Halaman Umpan Balik Instan (Setelah Kuis Selesai)
  Widget _buildResultScreen(List<QuestionModel> questions) {
    if (_quizResult == null) return Container();
    
    int correctCount = 0;
    for (final q in questions) {
      if (_quizResult!.userAnswers.containsKey(q.id) && _quizResult!.userAnswers[q.id] == q.correctAnswerIndex) {
        correctCount++; 
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Hasil Kuis', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: accentColor)),
          const SizedBox(height: 10),
          Text('Skor Akhir Anda: ${_quizResult!.score}', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: _quizResult!.isPassed ? Colors.greenAccent : Colors.redAccent)),
          
          Text(
            'Anda menjawab $correctCount dari ${questions.length} pertanyaan dengan benar.', 
            style: const TextStyle(fontSize: 16, color: Colors.white70)
          ),
          
          Text('Status: ${_quizResult!.isPassed ? 'LULUS' : 'COBA LAGI'}', style: TextStyle(fontSize: 18, color: _quizResult!.isPassed ? Colors.greenAccent : Colors.redAccent)),
          const Divider(color: Colors.white30, height: 30),
          
          const Text('Ulasan Jawaban & Umpan Balik Instan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 10),
          
          ...questions.map((question) {
            final userAnswerIndex = _quizResult!.userAnswers[question.id];
            final isCorrect = userAnswerIndex == question.correctAnswerIndex;
            
            return Card(
              color: secondaryColor.withOpacity(0.5),
              margin: const EdgeInsets.only(bottom: 15),
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Q: ${question.text}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 5),
                    
                    Text('Jawaban Anda: ${userAnswerIndex != null ? question.options[userAnswerIndex] : 'Tidak Dijawab'}',
                      style: TextStyle(color: isCorrect ? Colors.greenAccent : Colors.redAccent)),
                    
                    if (!isCorrect)
                      Text('Jawaban Benar: ${question.options[question.correctAnswerIndex]}', style: const TextStyle(color: Colors.lightGreen)),

                    const SizedBox(height: 10),
                    const Text('Penjelasan (Umpan Balik Instan):', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
                    Text(question.explanation, style: const TextStyle(color: Colors.white60)),
                  ],
                ),
              ),
            );
          }).toList(),
          
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Kembali ke Dashboard'),
            ),
          )
        ],
      ),
    );
  }
}
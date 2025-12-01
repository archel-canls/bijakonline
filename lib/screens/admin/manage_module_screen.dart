import 'package:flutter/material.dart';

import 'dart:async';
import 'dart:convert'; // Untuk konversi Base64
import 'package:file_picker/file_picker.dart'; // Untuk memilih file
import 'package:intl/intl.dart'; 

// PERBAIKAN: Mengganti relative import menjadi package import
import 'package:bijakonline/main.dart'; 
import '../../models/modul_model.dart';
import '../../models/quiz_model.dart'; 
import '../../services/content_progress_service.dart';
import '../../services/quiz_service.dart';

// Screen untuk mengelola Modul dan Kuis
class ManageModuleScreen extends StatefulWidget {
  const ManageModuleScreen({super.key});

  @override
  State<ManageModuleScreen> createState() => _ManageModuleScreenState();
}

class _ManageModuleScreenState extends State<ManageModuleScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ContentProgressService _moduleService = ContentProgressService();
  final QuizService _quizService = QuizService();

  // State baru untuk menyimpan Quiz yang dipilih di tab Kuis (Admin)
  QuizModel? _selectedQuiz;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // Modul, Kuis, Hoaks
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- UI Utama ---
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin: Kelola Konten'),
        backgroundColor: primaryColor, // Menggunakan warna dari main.dart
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: accentColor,
          labelColor: accentColor,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Modul', icon: Icon(Icons.menu_book_outlined)),
            Tab(text: 'Kuis', icon: Icon(Icons.quiz_outlined)),
            Tab(text: 'Hoaks', icon: Icon(Icons.warning_amber_outlined)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildModuleList(), // Tab Modul
          _buildQuizTabContent(), // Tab Kuis (Baru)
          _buildHoaksTabContent(), // Tab Hoaks (Dummy)
        ],
      ),
    );
  }

  // --- TAB KUIS (FIX) ---
  
  // Wrapper untuk Tab Kuis yang mengelola Quiz terpilih
  Widget _buildQuizTabContent() {
    return Column(
      children: [
        // Daftar Pertanyaan (Jika kuis sudah dipilih)
        if (_selectedQuiz != null)
          Expanded(child: _buildQuestionList(_selectedQuiz!)),
        
        // Daftar Kuis (Hanya ditampilkan jika belum ada kuis yang dipilih)
        if (_selectedQuiz == null)
          Expanded(child: _buildQuizList()),
        
        // Tombol Kembali/Tambah Kuis/Tambah Pertanyaan
        Padding(
          padding: const EdgeInsets.all(15.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_selectedQuiz != null)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedQuiz = null;
                    });
                  },
                  icon: const Icon(Icons.arrow_back, color: accentColor),
                  label: const Text('Kembali ke Daftar Kuis', style: TextStyle(color: accentColor)),
                ),
              
              const Spacer(), // Dorong tombol ke kanan
              
              ElevatedButton.icon(
                onPressed: () {
                  if (_selectedQuiz != null) {
                    // Jika ada kuis terpilih, tampilkan form tambah pertanyaan
                    _showQuestionForm(context, quizId: _selectedQuiz!.id); 
                  } else {
                    // Jika tidak ada kuis terpilih, tampilkan form tambah kuis
                    _showQuizForm(context); 
                  }
                },
                icon: const Icon(Icons.add),
                label: Text(_selectedQuiz != null ? 'Tambah Pertanyaan' : 'Tambah Kuis'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: primaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Bagian 1: Daftar Kuis
  Widget _buildQuizList() {
    return StreamBuilder<List<QuizModel>>(
      stream: _quizService.getAllQuizzesForAdmin(), 
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: accentColor));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error memuat kuis: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }
        
        final quizzes = snapshot.data ?? [];
        if (quizzes.isEmpty) {
          return const Center(child: Text('Belum ada kuis yang dibuat.', style: TextStyle(color: Colors.white70)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(15.0),
          itemCount: quizzes.length,
          itemBuilder: (context, index) {
            final quiz = quizzes[index];
            return Card(
              color: secondaryColor.withOpacity(0.5),
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text(quiz.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('ID: ${quiz.id}\nDeadline: ${DateFormat('dd MMM yyyy').format(quiz.deadline.toLocal())}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: accentColor),
                      onPressed: () => _showQuizForm(context, quiz: quiz),
                    ),
                    IconButton(
                      icon: const Icon(Icons.list_alt, color: Colors.blueAccent),
                      onPressed: () {
                        // Pilih Kuis untuk lihat Pertanyaan
                        setState(() {
                          _selectedQuiz = quiz;
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => _deleteQuiz(quiz.id),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Bagian 2: Daftar Pertanyaan
  Widget _buildQuestionList(QuizModel quiz) {
    return FutureBuilder<List<QuestionModel>>(
      future: _quizService.getQuestionsForQuiz(quiz.id), 
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: accentColor));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error memuat pertanyaan: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }
        
        final questions = snapshot.data ?? [];
        if (questions.isEmpty) {
          return Center(child: Text('Belum ada pertanyaan untuk kuis: ${quiz.title}. Tambahkan sekarang!', style: const TextStyle(color: Colors.white70)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(15.0),
          itemCount: questions.length,
          itemBuilder: (context, index) {
            final question = questions[index];
            return Card(
              color: secondaryColor.withOpacity(0.5),
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text('Soal ${index + 1}: ${question.text.substring(0, question.text.length > 30 ? 30 : question.text.length)}...'),
                subtitle: Text('Jawaban Benar: ${question.options[question.correctAnswerIndex]} (Pilihan ${question.correctAnswerIndex + 1})'), 
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: accentColor),
                      // Tambahkan quizId saat memanggil form pertanyaan
                      onPressed: () => _showQuestionForm(context, quizId: quiz.id, question: question),
                    ),
                    // Hapus soal (jika _quizService.deleteQuestion sudah diimplementasikan)
                    // IconButton(
                    //   icon: const Icon(Icons.delete, color: Colors.redAccent),
                    //   onPressed: () => _deleteQuestion(quiz.id, question.id),
                    // ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  // --- Fungsionalitas Modul (Untuk Kelengkapan) ---

  // REVISI: Mengubah _buildModuleList untuk menyertakan tombol Tambah Modul
  Widget _buildModuleList() {
     return Column( // Tambahkan Column agar bisa menampung daftar dan tombol
      children: [
        Expanded( // Expanded agar daftar modul memenuhi sisa ruang
          child: StreamBuilder<List<ModulModel>>(
            stream: _moduleService.getModules(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: accentColor));
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error memuat modul: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
              }
              
              final modules = snapshot.data ?? [];
              if (modules.isEmpty) {
                return const Center(child: Text('Belum ada modul yang tersedia. Tambahkan sekarang.', style: TextStyle(color: Colors.white70)));
              }
              
              return ListView.builder(
                padding: const EdgeInsets.all(15.0),
                itemCount: modules.length,
                itemBuilder: (context, index) {
                  final modul = modules[index];
                  return Card(
                    color: primaryColor.withOpacity(0.5),
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(modul.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Quiz ID: ${modul.quizId ?? 'N/A'}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: accentColor),
                            onPressed: () => _showModuleForm(context, modul: modul),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () => _deleteModule(modul.id),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        
        // Tombol Tambah Modul
        Padding(
          padding: const EdgeInsets.all(15.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end, // Dorong tombol ke kanan
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  _showModuleForm(context);
                },
                icon: const Icon(Icons.add),
                label: const Text('Tambah Modul'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: primaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Fungsionalitas Hoaks (Dummy) ---

  Widget _buildHoaksTabContent() {
    return const Center(
      child: Text(
        'Manajemen Hoaks (Belum diimplementasikan)',
        style: TextStyle(color: Colors.white70, fontSize: 18),
      ),
    );
  }

  // --- Form dan Action Lain (Implementasi Dasar) ---

  // Form Tambah/Edit Modul
  void _showModuleForm(BuildContext context, {ModulModel? modul}) {
    final titleController = TextEditingController(text: modul?.title ?? '');
    final descController = TextEditingController(text: modul?.description ?? '');
    final youtubeController = TextEditingController(text: modul?.youtubeUrl ?? '');
    String? base64Material = modul?.materialBase64;

    // Gunakan State untuk mengelola ID Kuis dan pemicu rebuild
    showDialog(
      context: context,
      builder: (context) {
        String? selectedQuizId = modul?.quizId; // Pindahkan ke dalam builder agar stateful
        
        // Gunakan StatefulBuilder agar DropdownButton dapat mengubah state di dalam dialog
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            return AlertDialog(
              title: Text(modul == null ? 'Tambah Modul Baru' : 'Edit Modul: ${modul.title}'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Judul Modul')),
                    TextField(controller: descController, decoration: const InputDecoration(labelText: 'Deskripsi')),
                    TextField(controller: youtubeController, decoration: const InputDecoration(labelText: 'URL YouTube')),
                    
                    const SizedBox(height: 20),
                    Text('Quiz Terkait: ${selectedQuizId ?? 'Pilih Kuis'}'),
                    
                    // StreamBuilder untuk menampilkan daftar kuis yang ada
                    StreamBuilder<List<QuizModel>>(
                      stream: _quizService.getAllQuizzesForAdmin(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Text('Tidak ada kuis tersedia.', style: TextStyle(color: Colors.redAccent));
                        }
                        return DropdownButton<String>(
                          value: selectedQuizId,
                          hint: const Text('Pilih Kuis'),
                          items: snapshot.data!.map((quiz) {
                            return DropdownMenuItem<String>(
                              value: quiz.id,
                              child: Text('${quiz.title} (${quiz.id})'),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            // Panggil setStateDialog untuk memperbarui selectedQuizId di dalam dialog
                            setStateDialog(() { 
                              selectedQuizId = newValue;
                            });
                          },
                        );
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () async {
                        FilePickerResult? result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['pdf'],
                        );

                        if (result != null && result.files.single.bytes != null) {
                          // Mengonversi bytes PDF menjadi Base64 string
                          base64Material = base64Encode(result.files.single.bytes!);
                          // Perlu panggil setStateDialog untuk update teks tombol
                          setStateDialog(() {}); 
                          
                          // Gunakan ScaffoldMessenger dari root context
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Materi PDF berhasil dimuat!'))
                          );
                        }
                      },
                      icon: const Icon(Icons.upload_file),
                      label: Text(base64Material == null ? 'Unggah Materi PDF' : 'Ubah Materi PDF (Sudah Ada)'),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Batal'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  child: Text(modul == null ? 'Tambah' : 'Simpan'),
                  onPressed: () {
                    final newModul = ModulModel(
                      id: modul?.id ?? '', // Kosong jika baru
                      title: titleController.text,
                      description: descController.text,
                      youtubeUrl: youtubeController.text,
                      materialBase64: base64Material,
                      quizId: selectedQuizId,
                      // Nilai default untuk field wajib yang tidak ada di form:
                    );
                    _moduleService.saveModule(newModul);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          }
        );
      },
    );
  }

  // Form Tambah/Edit Kuis
  void _showQuizForm(BuildContext context, {QuizModel? quiz}) {
    final titleController = TextEditingController(text: quiz?.title ?? '');
    final descController = TextEditingController(text: quiz?.description ?? '');
    final moduleIdController = TextEditingController(text: quiz?.moduleId ?? '');
    final deadlineController = TextEditingController(text: quiz == null ? '' : DateFormat('yyyy-MM-dd').format(quiz.deadline));
    DateTime selectedDeadline = quiz?.deadline ?? DateTime.now().add(const Duration(days: 7));
    
    // Fungsi untuk memilih tanggal
    Future<void> _selectDate(BuildContext context, StateSetter setStateDialog) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDeadline,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)),
      );
      if (picked != null && picked != selectedDeadline) {
        setStateDialog(() {
          selectedDeadline = picked;
          deadlineController.text = DateFormat('yyyy-MM-dd').format(selectedDeadline);
        });
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            return AlertDialog(
              title: Text(quiz == null ? 'Tambah Kuis Baru' : 'Edit Kuis: ${quiz.title}'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Judul Kuis')),
                    TextField(controller: descController, decoration: const InputDecoration(labelText: 'Deskripsi Kuis')),
                    TextField(controller: moduleIdController, decoration: const InputDecoration(labelText: 'Modul ID Terkait (Optional)')),
                    GestureDetector(
                      onTap: () => _selectDate(context, setStateDialog),
                      child: AbsorbPointer(
                        child: TextField(
                          controller: deadlineController,
                          decoration: const InputDecoration(labelText: 'Deadline Kuis', suffixIcon: Icon(Icons.calendar_today)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Batal'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  child: Text(quiz == null ? 'Tambah' : 'Simpan'),
                  onPressed: () {
                    final newQuiz = QuizModel(
                      id: quiz?.id ?? '',
                      title: titleController.text,
                      description: descController.text,
                      moduleId: moduleIdController.text,
                      deadline: selectedDeadline,
                      totalQuestions: quiz?.totalQuestions ?? 0,
                    );
                    _quizService.saveQuiz(newQuiz);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Form Tambah/Edit Pertanyaan
  void _showQuestionForm(BuildContext context, {required String quizId, QuestionModel? question}) {
    final textController = TextEditingController(text: question?.text ?? '');
    final optionControllers = List.generate(
      4, // Asumsi maksimal 4 opsi
      (i) => TextEditingController(text: i < (question?.options.length ?? 0) ? question!.options[i] : ''),
    );
    final explanationController = TextEditingController(text: question?.explanation ?? '');
    int correctAnswerIndex = question?.correctAnswerIndex ?? 0;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(question == null ? 'Tambah Pertanyaan Baru' : 'Edit Soal: ${question.id}'),
          content: StatefulBuilder( // Gunakan StatefulBuilder untuk mengelola state radio button
            builder: (BuildContext context, StateSetter setStateDialog) {
              return SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    TextField(controller: textController, decoration: const InputDecoration(labelText: 'Teks Pertanyaan')),
                    ...List.generate(4, (index) {
                      return Row(
                        children: [
                          Radio<int>(
                            value: index,
                            groupValue: correctAnswerIndex,
                            onChanged: (int? value) {
                              setStateDialog(() { // Gunakan setStateDialog
                                correctAnswerIndex = value!;
                              });
                            },
                            activeColor: accentColor, // Tambah warna
                          ),
                          Expanded(
                            child: TextField(
                              controller: optionControllers[index], 
                              decoration: InputDecoration(labelText: 'Opsi ${index + 1}'),
                            ),
                          ),
                        ],
                      );
                    }),
                    TextField(controller: explanationController, decoration: const InputDecoration(labelText: 'Penjelasan Jawaban')),
                  ],
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text(question == null ? 'Tambah' : 'Simpan'),
              onPressed: () {
                final options = optionControllers.where((c) => c.text.isNotEmpty).map((c) => c.text).toList();
                
                // Pastikan ada minimal 2 opsi dan index jawaban benar valid
                if (options.length < 2 || correctAnswerIndex >= options.length) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Minimal 2 opsi dan pastikan jawaban benar valid.'))
                    );
                    return;
                }

                final newQuestion = QuestionModel(
                  id: question?.id ?? '',
                  text: textController.text,
                  options: options,
                  correctAnswerIndex: correctAnswerIndex,
                  explanation: explanationController.text,
                );
                _quizService.saveQuestion(quizId, newQuestion);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Aksi Hapus Modul
  Future<void> _deleteModule(String moduleId) async {
    // Implementasi konfirmasi penghapusan (dapat menggunakan showDialog)
    await _moduleService.deleteModule(moduleId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Modul berhasil dihapus!'))
    );
  }

  // Aksi Hapus Kuis
  Future<void> _deleteQuiz(String quizId) async {
    // Implementasi konfirmasi penghapusan (dapat menggunakan showDialog)
    await _quizService.deleteQuiz(quizId);
    // Jika kuis yang dihapus sedang dipilih, reset state
    if (_selectedQuiz?.id == quizId) {
        setState(() {
            _selectedQuiz = null;
        });
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kuis berhasil dihapus! (Termasuk Pertanyaan)'))
    );
  }

  // Aksi Hapus Pertanyaan (Opsional, jika diimplementasikan di QuizService)
  // Future<void> _deleteQuestion(String quizId, String questionId) async {
  //   await _quizService.deleteQuestion(quizId, questionId);
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(content: Text('Pertanyaan berhasil dihapus!'))
  //   );
  // }
}
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/auth/login_register_screen.dart';
import 'screens/home/dashboard_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/manage_module_screen.dart'; // Import Admin
import 'screens/quiz/kuis_screen.dart'; // Import KuisScreen
import 'screens/notification/notification_screen.dart'; // Import Notif
import 'screens/learning/modul_list_screen.dart'; // Import ModulListScreen
// import 'screens/learning/lesson_screen.dart'; // Tidak perlu diimport jika tidak dijadikan rute bernama
import 'services/auth_service.dart';

// Konfigurasi Firebase Anda (Sesuai dengan yang diberikan)
const firebaseConfig = {
  "apiKey": "AIzaSyBZX4dov8yH7uusBaF4qx49CGqh-cbsef4",
  "authDomain": "bijakonline-arc.firebaseapp.com",
  "databaseURL": "https://bijakonline-arc-default-rtdb.asia-southeast1.firebasedatabase.app",
  "projectId": "bijakonline-arc",
  "storageBucket": "bijakonline-arc.firebasestorage.com",
  "messagingSenderId": "1028254500154",
  "appId": "1:1028254500154:web:f5c3c1483cae2ffefc3c03",
  "measurementId": "G-SN25GP0ZZV"
};

// Warna yang diadaptasi dari desain
const Color primaryColor = Color(0xFF192A56); // Biru Gelap
const Color accentColor = Color(0xFFFDC84D); // Kuning/Orange Emas
const Color secondaryColor = Color(0xFF4B6584); // Biru Abu-abu

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: firebaseConfig["apiKey"]!,
      authDomain: firebaseConfig["authDomain"]!,
      databaseURL: firebaseConfig["databaseURL"]!,
      projectId: firebaseConfig["projectId"]!,
      storageBucket: firebaseConfig["storageBucket"]!,
      messagingSenderId: firebaseConfig["messagingSenderId"]!,
      appId: firebaseConfig["appId"]!,
      measurementId: firebaseConfig["measurementId"],
    ),
  );
  runApp(const BijakOnlineApp());
}

class BijakOnlineApp extends StatelessWidget {
  const BijakOnlineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bijak Online',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: primaryColor,
        scaffoldBackgroundColor: primaryColor, // Latar belakang gelap sesuai desain
        colorScheme: const ColorScheme.dark(
          primary: primaryColor,
          secondary: accentColor,
          background: primaryColor,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryColor,
          elevation: 0,
        ),
        // Penghapusan 'const' pada ElevatedButtonThemeData yang tidak diperlukan
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: primaryColor, 
            backgroundColor: accentColor, // Tombol utama berwarna accent
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            padding: const EdgeInsets.symmetric(vertical: 15),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        // Perbaikan: Pastikan TextStyle menggunakan 'const' jika berada di dalam 'const TextTheme'
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white70), // Perbaikan 'const' ganda
          bodyMedium: TextStyle(color: Colors.white60), // Perbaikan 'const' ganda
          titleLarge: TextStyle(color: Colors.white), // Perbaikan 'const' ganda
        ),
      ),
      home: const AuthWrapper(),
      // PENTING: Map untuk 'routes' TIDAK BOLEH 'const' jika salah satu nilainya
      // (terutama rute '/quiz' yang menggunakan 'ModalRoute') bersifat dinamis (runtime).
      routes: {
        '/dashboard': (context) => const DashboardScreen(),
        '/admin': (context) => const AdminDashboardScreen(),
        '/admin/manage_module': (context) => const ManageModuleScreen(), // Rute Admin
        '/login': (context) => const LoginRegisterScreen(),
        '/notifications': (context) => const NotificationScreen(), // Rute Notifikasi
        // ModulListScreen harus non-const jika memang memiliki state yang dinamis
        // Asumsi ModulListScreen sekarang sudah non-const, maka const di sini aman
        '/modules': (context) => ModulListScreen(), 
        '/quiz': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as String?;
          if (args != null) {
            // KuisScreen tidak boleh 'const' karena quizId bersifat dinamis (runtime)
            return KuisScreen(quizId: args); 
          }
          return const DashboardScreen(); // Fallback
        },
      },
    );
  }
}

// Widget untuk menentukan layar awal (AuthWrapper)
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    return StreamBuilder<User?>(
      stream: authService.user,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: accentColor)));
        } else if (snapshot.hasData) {
          // User sudah login, cek apakah dia admin
          // Pastikan AuthService.isAdmin tidak memerlukan await
          if (authService.isAdmin(snapshot.data)) {
            return const AdminDashboardScreen();
          } else {
            return const DashboardScreen();
          }
        } else {
          // User belum login
          return const LoginRegisterScreen();
        }
      },
    ); 
  }
}
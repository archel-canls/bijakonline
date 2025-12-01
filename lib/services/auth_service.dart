// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('users');
  final String _adminUid = 'izBSquLiNYTfCSmJZa6Sj8nuxlc2';

  // Stream untuk memantau status autentikasi
  Stream<User?> get user => _auth.authStateChanges();

  // Cek apakah user adalah Admin
  bool isAdmin(User? user) {
    return user != null && user.uid == _adminUid;
  }

  // Register (dengan seleksi Persona Digital)
  Future<User?> registerWithEmailAndPassword(String email, String password, String name, String persona) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;

      if (user != null) {
        // Simpan data user ke Realtime Database
        UserModel newUser = UserModel(
          uid: user.uid,
          email: email,
          name: name,
          persona: persona,
        );
        await _dbRef.child(user.uid).set(newUser.toMap());
      }
      return user;
    } catch (e) {
      print('Error during registration: $e');
      return null;
    }
  }

  // Login
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return result.user;
    } catch (e) {
      print('Error during sign in: $e');
      return null;
    }
  }

  // Reset Password
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Error sending reset email: $e');
      rethrow;
    }
  }

  // Logout
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Ambil data user dari RTDB
  Future<UserModel?> getUserData(String uid) async {
    try {
      final snapshot = await _dbRef.child(uid).get();
      if (snapshot.exists) {
        return UserModel.fromMap(Map<String, dynamic>.from(snapshot.value as Map), uid);
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Update Password (Diimplementasikan di ProfileScreen)
  Future<void> updatePassword(String newPassword) async {
    try {
      await _auth.currentUser!.updatePassword(newPassword);
    } catch (e) {
      print('Error updating password: $e');
      rethrow;
    }
  }
}
// lib/models/user_model.dart
class UserModel {
  final String uid;
  final String email;
  final String name;
  final String persona; // Contoh: "Netizen Kritis", "Pengguna Kasual"
  final double skorJejakPublik; // SJP

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.persona,
    this.skorJejakPublik = 0.0,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      persona: data['persona'] ?? 'Pengguna Kasual',
      skorJejakPublik: (data['sjp'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'persona': persona,
      'sjp': skorJejakPublik,
    };
  }
}
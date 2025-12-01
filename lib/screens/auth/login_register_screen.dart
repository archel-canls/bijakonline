// lib/screens/auth/login_register_screen.dart
import 'package:flutter/material.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // DIHAPUS
import '../../services/auth_service.dart';
import '../../main.dart'; // Untuk warna

class LoginRegisterScreen extends StatefulWidget {
  const LoginRegisterScreen({super.key});

  @override
  State<LoginRegisterScreen> createState() => _LoginRegisterScreenState();
}

class _LoginRegisterScreenState extends State<LoginRegisterScreen> {
  final AuthService _auth = AuthService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  String _name = '';
  String _selectedPersona = 'Pengguna Kasual';
  bool _isLogin = true;
  bool _isLoading = false;

  final List<String> _personas = [
    'Pengguna Kasual',
    'Netizen Kritis',
    'Pakar Digital',
    'Korban Hoaks',
  ];

  // UI adaptasi dari desain gambar
  Widget _buildTextField({required String label, required IconData icon, bool isPassword = false, required Function(String) onChanged, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextFormField(
        obscureText: isPassword,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          prefixIcon: Icon(icon, color: accentColor),
          filled: true,
          fillColor: secondaryColor.withOpacity(0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: const BorderSide(color: accentColor, width: 2),
          ),
        ),
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }

  void _submitAuthForm() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLogin) {
        // Login
        await _auth.signInWithEmailAndPassword(_email, _password);
      } else {
        // Register
        await _auth.registerWithEmailAndPassword(_email, _password, _name, _selectedPersona);
      }
      // Navigasi ke AuthWrapper akan otomatis mengurus routing
    } catch (e) {
      // Tampilkan error (Misalnya Snackbar)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isLogin ? 'Login Gagal: $e' : 'Registrasi Gagal: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _resetPassword() async {
    // Logika Reset Password, misal menggunakan dialog untuk input email
    String? email = await showDialog<String>(
      context: context,
      builder: (context) {
        TextEditingController emailController = TextEditingController();
        return AlertDialog(
          title: const Text('Reset Password'),
          content: TextField(
            controller: emailController,
            decoration: const InputDecoration(labelText: 'Email Anda'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(emailController.text),
              child: const Text('Kirim Link Reset'),
            ),
          ],
        );
      },
    );

    if (email != null && email.isNotEmpty) {
      try {
        await _auth.sendPasswordResetEmail(email);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Link reset password telah dikirim ke email Anda.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim link reset: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'MASUK BIJAK ID' : 'DAFTAR BIJAK ID', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo/Nama Aplikasi
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 40.0, top: 20.0),
                  child: Text(
                    'BIJAK ONLINE',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                ),
              ),

              // Form Email
              _buildTextField(
                label: 'Masukkan email',
                icon: Icons.email_outlined,
                onChanged: (val) => _email = val.trim(),
                validator: (val) => val!.isEmpty || !val.contains('@') ? 'Masukkan email yang valid.' : null,
              ),

              // Form Nama (Hanya Register)
              if (!_isLogin)
                _buildTextField(
                  label: 'Masukkan nama lengkap',
                  icon: Icons.person_outline,
                  onChanged: (val) => _name = val.trim(),
                  validator: (val) => val!.isEmpty ? 'Nama tidak boleh kosong.' : null,
                ),

              // Form Password
              _buildTextField(
                label: 'Masukkan password',
                icon: Icons.lock_outline,
                isPassword: true,
                onChanged: (val) => _password = val,
                validator: (val) => val!.length < 6 ? 'Password minimal 6 karakter.' : null,
              ),

              // Seleksi Persona Digital (Hanya Register)
              if (!_isLogin)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  margin: const EdgeInsets.only(bottom: 20.0),
                  decoration: BoxDecoration(
                    color: secondaryColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedPersona,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, color: accentColor),
                      dropdownColor: secondaryColor,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedPersona = newValue!;
                        });
                      },
                      items: _personas.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: const TextStyle(color: Colors.white)),
                        );
                      }).toList(),
                    ),
                  ),
                ),

              // Tombol Utama (Login/Daftar)
              if (_isLoading)
                const Center(child: CircularProgressIndicator(color: accentColor))
              else
                ElevatedButton(
                  onPressed: _submitAuthForm,
                  child: Text(_isLogin ? 'LOGIN' : 'DAFTAR'),
                ),

              const SizedBox(height: 20),

              // Link Lupa Password (Hanya Login)
              if (_isLogin)
                GestureDetector(
                  onTap: _resetPassword,
                  child: const Center(
                    child: Text(
                      'Lupa password?',
                      style: TextStyle(color: accentColor, decoration: TextDecoration.underline),
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // Link Switch Auth Mode
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_isLogin ? 'Belum punya akun?' : 'Sudah punya akun?', style: const TextStyle(color: Colors.white70)),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLogin = !_isLogin;
                        _formKey.currentState?.reset(); // Reset form state
                      });
                    },
                    child: Text(
                      _isLogin ? 'Daftar Sekarang' : 'Login disini',
                      style: const TextStyle(color: accentColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              
              // Opsi Login Lain (Diadaptasi dari desain)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Row(
                  children: [
                    Expanded(child: Divider(color: Colors.white24)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.0),
                      child: Text('Atau login dengan', style: TextStyle(color: Colors.white54)),
                    ),
                    Expanded(child: Divider(color: Colors.white24)),
                  ],
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // MENGGANTI FontAwesomeIcons.google -> Icons.g_mobiledata (Ikon Google/G yang tersedia)
                  _buildSocialIcon(Icons.g_mobiledata, size: 30), 
                  const SizedBox(width: 20),
                  // MENGGANTI FontAwesomeIcons.facebook -> Icons.facebook
                  _buildSocialIcon(Icons.facebook),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Mengubah parameter _buildSocialIcon agar dapat menerima Icons.IconData
  Widget _buildSocialIcon(IconData icon, {double size = 20}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: secondaryColor.withOpacity(0.5),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white30),
      ),
      // Menyesuaikan ukuran ikon Google agar terlihat proporsional
      child: Icon(icon, color: Colors.white, size: size),
    );
  }
}
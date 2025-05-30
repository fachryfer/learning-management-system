import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isObscure = true;
  bool _isConfirmObscure = true;
  String _selectedRole = 'student'; // Default role

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      UserCredential? userCredential;
      
      try {
        // 1. Buat user di Firebase Auth
        userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (userCredential.user == null) {
          throw FirebaseAuthException(
            code: 'auth/user-not-created',
            message: 'User credential is null after creation',
          );
        }

        // 2. Buat data user untuk Firestore
        final userData = {
          'uid': userCredential.user!.uid,
          'email': _emailController.text.trim(),
          'role': _selectedRole,
          'createdAt': FieldValue.serverTimestamp(),
        };

        print('Data yang akan disimpan ke Firestore: ${userData}');

        // 3. Simpan ke Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(userData);

        print('Data seharusnya sudah disimpan ke Firestore.');

        // 4. Verifikasi data tersimpan
        final docSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (!docSnapshot.exists) {
           // Hapus user dari Auth jika data tidak tersimpan di Firestore
          await userCredential.user!.delete();
          throw Exception('Verifikasi Firestore gagal: Data user tidak ditemukan setelah disimpan.');
        }

        print('Verifikasi Firestore berhasil. Data ditemukan: ${docSnapshot.data()}');

        // 5. Logout dan kembali ke login
        await FirebaseAuth.instance.signOut();
        print('Logout berhasil.');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registrasi berhasil! Silakan login.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushReplacementNamed(context, '/login');
        }

      } on FirebaseAuthException catch (e) {
        print('FirebaseAuthException saat registrasi: ${e.code} - ${e.message}');
        
        // Jika user sudah dibuat di Auth tapi gagal di Firestore/verifikasi, hapus user
        if (userCredential?.user != null) {
          try {
            print('Menghapus user dari Auth karena gagal di tahap selanjutnya...');
            await userCredential!.user!.delete();
            print('User berhasil dihapus dari Auth.');
          } catch (deleteError) {
            print('Error saat menghapus user dari Auth: $deleteError');
          }
        }

        String message = 'Terjadi kesalahan autentikasi.';
        if (e.code == 'weak-password') {
          message = 'Password terlalu lemah.';
        } else if (e.code == 'email-already-in-use') {
          message = 'Email sudah terdaftar.';
        } else if (e.code == 'invalid-email') {
          message = 'Format email tidak valid.';
        } else if (e.message != null) {
           message = 'Autentikasi gagal: ${e.message}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red[700],
          ),
        );
      } catch (e) {
        print('Error umum saat registrasi: ${e.toString()}');
        print('Tipe error: ${e.runtimeType}');
        // Jika user sudah dibuat di Auth tapi gagal di Firestore/verifikasi, hapus user
        if (userCredential?.user != null) {
          try {
             print('Menghapus user dari Auth karena error umum...');
            await userCredential!.user!.delete();
            print('User berhasil dihapus dari Auth.');
          } catch (deleteError) {
            print('Error saat menghapus user dari Auth (dari error umum): $deleteError');
          }
        }

        String message = 'Terjadi kesalahan saat registrasi.';
         if (e.toString().contains('List') && e.toString().contains('Object')) {
           message = 'Terjadi kesalahan format data saat registrasi. Cek log untuk detail.';
         } else {
           message = 'Terjadi kesalahan: ${e.toString()}';
         }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red[700],
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              const Color(0xFF2D2D2D),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.school,
                      size: 80,
                      color: Color(0xFF2196F3),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Daftar Akun',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2196F3),
                        letterSpacing: 2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Buat akun baru untuk mulai belajar',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email, color: Color(0xFF2196F3)),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email tidak boleh kosong';
                        }
                        if (!value.contains('@')) {
                          return 'Email tidak valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock, color: Color(0xFF2196F3)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isObscure ? Icons.visibility : Icons.visibility_off,
                            color: const Color(0xFF2196F3),
                          ),
                          onPressed: () {
                            setState(() {
                              _isObscure = !_isObscure;
                            });
                          },
                        ),
                      ),
                      obscureText: _isObscure,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password tidak boleh kosong';
                        }
                        if (value.length < 6) {
                          return 'Password minimal 6 karakter';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Konfirmasi Password',
                        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF2196F3)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmObscure ? Icons.visibility : Icons.visibility_off,
                            color: const Color(0xFF2196F3),
                          ),
                          onPressed: () {
                            setState(() {
                              _isConfirmObscure = !_isConfirmObscure;
                            });
                          },
                        ),
                      ),
                      obscureText: _isConfirmObscure,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Konfirmasi password tidak boleh kosong';
                        }
                        if (value != _passwordController.text) {
                          return 'Password tidak cocok';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        prefixIcon: Icon(Icons.person, color: Color(0xFF2196F3)),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'student',
                          child: Text('Siswa'),
                        ),
                        DropdownMenuItem(
                          value: 'admin',
                          child: Text('Admin'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedRole = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Daftar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: const Text('Sudah punya akun? Masuk'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({super.key});

  // Fungsi untuk mengubah role pengguna di Firestore
  Future<void> _changeUserRole(String userId, String newRole, BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'role': newRole,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Role pengguna berhasil diubah menjadi $newRole!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengubah role pengguna: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      print('Error changing user role: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser; // Dapatkan user saat ini

    if (currentUser == null) {
       return const Scaffold(
        body: Center(
          child: Text('Anda harus login untuk mengakses halaman ini.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Pengguna'),
        backgroundColor: const Color(0xFF2196F3),
      ),
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
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error memuat data pengguna: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final users = snapshot.data!.docs;

              // Filter pengguna agar tidak menampilkan admin yang sedang login
              final filteredUsers = users.where((doc) => doc.id != currentUser.uid).toList();

              if (filteredUsers.isEmpty) {
                return const Center(child: Text('Tidak ada pengguna lain yang terdaftar.'));
              }

              return ListView.builder(
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) {
                  final userDoc = filteredUsers[index];
                  final userData = userDoc.data() as Map<String, dynamic>;
                  final userId = userDoc.id;
                  final email = userData['email'] ?? '[Tidak ada Email]';
                  final role = userData['role'] ?? 'student'; // Default student jika role tidak ada

                  return Card(
                     color: const Color(0xFF2D2D2D), // Warna latar kartu gelap
                     margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), // Tambahkan margin
                     elevation: 4.0,
                     shape: RoundedRectangleBorder(
                         borderRadius: BorderRadius.circular(8.0),
                     ),
                    child: ListTile(
                      title: Text(email, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      subtitle: Text('Role: ${role == 'admin' ? 'Admin' : 'Siswa'}', style: const TextStyle(color: Colors.white70)),
                      trailing: DropdownButton<String>(
                        value: role, // Nilai saat ini
                        dropdownColor: const Color(0xFF2D2D2D), // Warna dropdown
                        style: const TextStyle(color: Colors.white), // Warna teks item dropdown
                        iconEnabledColor: Theme.of(context).primaryColorLight, // Warna ikon dropdown
                        items: const [
                          DropdownMenuItem(value: 'student', child: Text('Siswa')),
                          DropdownMenuItem(value: 'admin', child: Text('Admin')),
                        ],
                        onChanged: (String? newRole) {
                          if (newRole != null && newRole != role) {
                            _changeUserRole(userId, newRole, context);
                          }
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
} 
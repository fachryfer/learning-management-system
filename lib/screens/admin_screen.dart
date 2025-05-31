import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_assignment_screen.dart';
import 'add_material_screen.dart';
import 'view_submissions_admin_screen.dart';
import 'view_materials_admin_screen.dart';
import 'manage_assignments_screen.dart';
import 'manage_users_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal keluar'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2196F3),
              Color(0xFF2D2D2D),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo Talu Learn
                  Image.asset(
                    'assets/logo_talu_learn.png',
                    height: 90,
                  ),
                  const SizedBox(height: 18),
                  // Nama aplikasi
                  const Text(
                    'Talu Learn',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Learning Management System',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Card Dashboard
                  Card(
                    elevation: 12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Dashboard Guru',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2196F3),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.logout, color: Color(0xFF2196F3)),
                                onPressed: _signOut,
                                tooltip: 'Keluar',
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          GridView.count(
                            shrinkWrap: true,
                            crossAxisCount: 2,
                            crossAxisSpacing: 16.0,
                            mainAxisSpacing: 16.0,
                            childAspectRatio: 1.0,
                            physics: const NeverScrollableScrollPhysics(),
                            children: <Widget>[
                              _buildDashboardCard(
                                context,
                                'Tambah Tugas',
                                Icons.assignment_add,
                                () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddAssignmentScreen())),
                              ),
                              _buildDashboardCard(
                                context,
                                'Tambah Materi',
                                Icons.book_online,
                                () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddMaterialScreen())),
                              ),
                              _buildDashboardCard(
                                context,
                                'Kelola Tugas',
                                Icons.assignment_outlined,
                                () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageAssignmentsScreen())),
                              ),
                              _buildDashboardCard(
                                context,
                                'Lihat Pengumpulan',
                                Icons.assignment_turned_in_outlined,
                                () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ViewSubmissionsAdminScreen())),
                              ),
                              _buildDashboardCard(
                                context,
                                'Lihat Materi',
                                Icons.book_outlined,
                                () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ViewMaterialsAdminScreen())),
                              ),
                              _buildDashboardCard(
                                context,
                                'Kelola Pengguna',
                                Icons.people_alt_outlined,
                                () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageUsersScreen())),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Card(
      color: const Color(0xFF2D2D2D),
      elevation: 8.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 50,
                color: const Color(0xFF2196F3),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 
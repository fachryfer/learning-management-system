import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_assignment_screen.dart';
import 'add_material_screen.dart';
import 'view_submissions_admin_screen.dart';
import 'view_materials_admin_screen.dart';
import 'manage_assignments_screen.dart';

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
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: const Color(0xFF2196F3),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
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
          child: SingleChildScrollView(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.admin_panel_settings,
                    size: 120,
                    color: Color(0xFF2196F3),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Selamat Datang Admin',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2196F3),
                    ),
                  ),
                  const SizedBox(height: 48),
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
                    ],
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
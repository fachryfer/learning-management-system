import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/student_screen.dart';
import 'firebase_options.dart';
import 'screens/add_assignment_screen.dart';
import 'screens/add_material_screen.dart';
import 'screens/view_submissions_admin_screen.dart';
import 'screens/view_materials_admin_screen.dart';
import 'screens/view_assignments_screen.dart';
import 'screens/view_materials_screen.dart';
import 'screens/view_submissions_student_screen.dart';
import 'screens/manage_assignments_screen.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    print('Menginisialisasi Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase berhasil diinisialisasi');
    
    // Verifikasi koneksi Firestore
    try {
      await FirebaseFirestore.instance.collection('test').doc('test').set({
        'test': 'test'
      });
      print('Koneksi Firestore berhasil');
      // Hapus dokumen test
      await FirebaseFirestore.instance.collection('test').doc('test').delete();
    } catch (e) {
      print('Error saat verifikasi Firestore: $e');
    }
    
    runApp(const MyApp());
  } catch (e) {
    print('Error saat inisialisasi Firebase: $e');
    rethrow;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-Learning',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF2196F3), // Blue
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF2196F3),
          secondary: const Color(0xFF64B5F6), // Light Blue
          surface: const Color(0xFF2D2D2D),
          background: const Color(0xFF1A1A1A),
          error: Colors.red[700]!,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2D2D2D),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2196F3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2196F3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF64B5F6), width: 2),
      ),
          labelStyle: const TextStyle(color: Color(0xFF64B5F6)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2196F3),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF64B5F6),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A1A),
          foregroundColor: Color(0xFF64B5F6),
          elevation: 0,
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/addAssignment': (context) => const AddAssignmentScreen(),
        '/addMaterial': (context) => const AddMaterialScreen(),
        '/viewSubmissionsAdmin': (context) => const ViewSubmissionsAdminScreen(),
        '/viewMaterialsAdmin': (context) => const ViewMaterialsAdminScreen(),
        '/viewAssignmentsStudent': (context) => const ViewAssignmentsScreen(),
        '/viewMaterialsStudent': (context) => const ViewMaterialsScreen(),
        '/viewSubmissionsStudent': (context) => const ViewSubmissionsStudentScreen(),
        '/manageAssignments': (context) => const ManageAssignmentsScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF64B5F6),
              ),
            ),
          );
        }

        if (snapshot.hasData) {
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(snapshot.data!.uid)
                .get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF64B5F6),
                    ),
                  ),
                );
              }

              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                final role = userData['role'] as String;

                if (role == 'admin') {
                  return const AdminScreen();
                } else {
                  return const StudentScreen();
                }
              }

              // Jika data user tidak ditemukan, logout dan kembali ke login
              FirebaseAuth.instance.signOut();
              return const LoginScreen();
            },
          );
        }

        return const LoginScreen();
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/content_model.dart';
import 'package:url_launcher/url_launcher.dart';

class ViewSubmissionsStudentScreen extends StatelessWidget {
  const ViewSubmissionsStudentScreen({super.key});

  // Fungsi untuk mendapatkan judul tugas berdasarkan ID
  Future<String> _getAssignmentTitle(String assignmentId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('assignments').doc(assignmentId).get();
      return doc.exists ? (doc.data()?['title'] ?? 'Judul Tidak Ditemukan') : 'Tugas Tidak Ditemukan';
    } catch (e) {
      print('Error fetching assignment title: $e');
      return 'Error Judul Tugas';
    }
  }

  // Fungsi untuk membuka URL
  void _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tidak bisa membuka link: $url'),
            backgroundColor: Colors.red,
          )
        );
        print('Could not launch $url');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saat membuka link: ${e.toString()}'),
          backgroundColor: Colors.red,
        )
      );
      print('Error launching URL $url: ${e.toString()}');
    }
  }

  // Fungsi untuk menampilkan gambar dalam tampilan penuh
  void _showFullScreenImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).pop(); // Tutup dialog saat gambar diklik
            },
            child: InteractiveViewer( // Memungkinkan zoom dan pan
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain, // Sesuaikan agar gambar terlihat penuh
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null && loadingProgress.expectedTotalBytes != 0
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!.toDouble()
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                   print('Error loading full screen image: ${error.toString()}');
                   return const Center(child: Icon(Icons.error, color: Colors.red)); // Ikon error
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper untuk memeriksa apakah URL terlihat seperti gambar
  bool _isImageUrl(String url) {
    final lowerCaseUrl = url.toLowerCase();
    return lowerCaseUrl.endsWith('.jpg') ||
           lowerCaseUrl.endsWith('.jpeg') ||
           lowerCaseUrl.endsWith('.png') ||
           lowerCaseUrl.endsWith('.gif') ||
           lowerCaseUrl.endsWith('.bmp');
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Anda harus login terlebih dahulu'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengumpulan Tugas Saya'),
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
            stream: FirebaseFirestore.instance
                .collection('submissions')
                .where('studentId', isEqualTo: currentUser.uid)
                .orderBy('submittedAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error memuat pengumpulan: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final submissions = snapshot.data!.docs.map((doc) {
                return Submission.fromMap({
                  ...doc.data() as Map<String, dynamic>,
                  'id': doc.id,
                });
              }).toList();

              if (submissions.isEmpty) {
                return const Center(child: Text('Belum ada pengumpulan tugas.'));
              }

              return ListView.builder(
                itemCount: submissions.length,
                itemBuilder: (context, index) {
                  final submission = submissions[index];
                  
                  return FutureBuilder<String>(
                    future: _getAssignmentTitle(submission.assignmentId),
                    builder: (context, titleSnapshot) {
                      if (titleSnapshot.connectionState == ConnectionState.waiting) {
                        return Card(
                          color: const Color(0xFF2D2D2D),
                          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                          child: const ListTile(
                            title: Text('Memuat...', style: TextStyle(color: Colors.white70)),
                          ),
                        );
                      }

                      final assignmentTitle = titleSnapshot.data ?? 'Judul Tidak Ditemukan';

                      return Card(
                        color: const Color(0xFF2D2D2D),
                        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                        child: ListTile(
                          title: Text('Tugas: $assignmentTitle', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Dikumpulkan: ${submission.submittedAt.toDate().toLocal()}', style: const TextStyle(color: Colors.white70),),
                              Text('Status: ${submission.grade != null ? 'Sudah Dinilai' : 'Belum Dinilai'}', style: const TextStyle(color: Colors.white70),),
                              if (submission.grade != null)
                                Text('Nilai: ${submission.grade}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent),),
                            ],
                          ),
                          trailing: submission.fileUrl.isNotEmpty
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Ikon Penjepit Kertas (untuk buka URL)
                                    IconButton(
                                      icon: const Icon(Icons.attach_file, color: Colors.blue),
                                      onPressed: () {
                                        _launchUrl(context, submission.fileUrl);
                                      },
                                    ),
                                    // Ikon Gambar (untuk tampilkan gambar penuh, jika URL adalah gambar)
                                    if (_isImageUrl(submission.fileUrl))
                                      IconButton(
                                        icon: const Icon(Icons.image, color: Colors.green),
                                        onPressed: () {
                                          _showFullScreenImageDialog(context, submission.fileUrl);
                                        },
                                      ),
                                  ],
                                )
                              : null,
                        ),
                      );
                    },
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
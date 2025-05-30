import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/content_model.dart'; // Untuk model Submission
import 'package:firebase_auth/firebase_auth.dart'; // Import firebase_auth
import 'package:url_launcher/url_launcher.dart'; // Tambahkan import ini

class ViewSubmissionsAdminScreen extends StatefulWidget {
  const ViewSubmissionsAdminScreen({super.key});

  @override
  State<ViewSubmissionsAdminScreen> createState() => _ViewSubmissionsAdminScreenState();
}

class _ViewSubmissionsAdminScreenState extends State<ViewSubmissionsAdminScreen> {
  // Pindahkan controller nilai ke level State
  late final TextEditingController _gradeController;
  late final User? currentUser; // Tambahkan currentUser di state

  @override
  void initState() {
    super.initState();
    // Inisialisasi controller di initState
    _gradeController = TextEditingController();
    currentUser = FirebaseAuth.instance.currentUser; // Dapatkan user saat ini
  }

  @override
  void dispose() {
    // Pastikan controller di-dispose di sini
    _gradeController.dispose();
    print('_gradeController disposed from ViewSubmissionsAdminScreen State'); // Log disposal
    super.dispose();
  }

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

  // Fungsi untuk mendapatkan email siswa berdasarkan ID
  Future<String> _getStudentEmail(String studentId) async {
     try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(studentId).get();
      return doc.exists ? (doc.data()?['email'] ?? 'Email Tidak Ditemukan') : 'Siswa Tidak Ditemukan';
    } catch (e) {
      print('Error fetching student email: $e');
      return 'Error Email Siswa';
    }
  }

  // Fungsi untuk membuka URL
  void _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tidak bisa membuka link: $url'),
              backgroundColor: Colors.red,
            )
          );
        }
        print('Could not launch $url'); // Cetak ke konsol debug juga
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saat membuka link: ${e.toString()}'),
            backgroundColor: Colors.red,
          )
        );
      }
      print('Error launching URL $url: ${e.toString()}'); // Cetak ke konsol debug
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

  // Fungsi untuk menampilkan dialog untuk memberi nilai
  void _showGradingDialog(Submission submission) async {
    // Set nilai controller sesuai nilai yang sudah ada (jika ada)
    _gradeController.text = submission.grade?.toString() ?? '';
    // Tidak menggunakan feedback controller lagi

    // Ambil judul tugas dan email siswa untuk ditampilkan di dialog
    final assignmentTitle = await _getAssignmentTitle(submission.assignmentId);
    final studentEmail = await _getStudentEmail(submission.studentId);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Beri Nilai Tugas'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, // Align text to start
              children: [
                Text('Tugas: $assignmentTitle'),
                const SizedBox(height: 8),
                Text('Pengumpulan oleh: $studentEmail'),
                const SizedBox(height: 16),

                // Tampilkan link file atau jawaban teks di sini
                // Jika fileUrl adalah gambar, admin bisa melihatnya dari daftar.
                // Jika bukan gambar (misal: PDF, dokumen), tampilkan link untuk dibuka eksternal
                if (submission.fileUrl.isNotEmpty && !_isImageUrl(submission.fileUrl))
                   InkWell(
                    onTap: () {
                      _launchUrl(context, submission.fileUrl); // Implementasi buka file non-gambar
                    },
                    child: Text(
                      'Unduh File Pengumpulan',
                      style: TextStyle(color: Theme.of(context).primaryColor, decoration: TextDecoration.underline),
                    ),
                  ),

                 if (submission.textSubmission != null && submission.textSubmission!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text('Jawaban Teks:\n${submission.textSubmission}'),
                    ),
                 const SizedBox(height: 16),

                TextFormField(
                  controller: _gradeController,
                  decoration: const InputDecoration(labelText: 'Nilai'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                   validator: (value) {
                    if (value == null || value.isEmpty) {
                       return 'Nilai tidak boleh kosong';
                    }
                     // Validasi jika nilai adalah angka
                     if (double.tryParse(value) == null) {
                        return 'Masukkan angka yang valid';
                     }
                    return null;
                   }
                ),
                 // Hapus field feedback
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                // Dispose dilakukan di method dispose screen
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Simpan Nilai'),
              onPressed: () async {
                 // TODO: Validasi form - bisa tambahkan GlobalKey<FormState> ke dialog jika perlu validasi real-time
                final grade = double.tryParse(_gradeController.text.trim());
                // Tidak ada feedback lagi

                 if (grade != null) {
                   try {
                      await FirebaseFirestore.instance
                          .collection('submissions')
                          .doc(submission.id)
                          .update({
                        'grade': grade,
                        // Hapus field feedback dari update
                      });
                      if (mounted) {
                         ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Nilai berhasil disimpan!'),
                              backgroundColor: Colors.green,
                            )
                         );
                         // Dispose dilakukan di method dispose screen
                         Navigator.of(context).pop();
                      }
                   } catch (e) {
                       if (mounted) {
                         ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Gagal menyimpan nilai: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            )
                         );
                         // Dispose dilakukan di method dispose screen
                         Navigator.of(context).pop();
                      }
                   }
                 } else {
                     // Tampilkan error validasi jika nilai tidak valid
                      if (mounted) {
                         ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Nilai tidak valid!'), backgroundColor: Colors.red,)
                         );
                      }
                 }
              },
            ),
          ],
        );
      },
    ); // Hapus whenComplete karena controller di-dispose di method dispose StatefulWidget
    // .whenComplete((){ ... });
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
       return const Scaffold(
        body: Center(
          child: Text('Anda harus login sebagai admin.'),
        ),
      );
    }

    // Ambil daftar ID tugas yang dibuat oleh admin ini
    return FutureBuilder<List<String>>(
      future: FirebaseFirestore.instance
          .collection('assignments')
          .where('adminId', isEqualTo: currentUser!.uid)
          .get()
          .then((snapshot) => snapshot.docs.map((doc) => doc.id).toList()),
      builder: (context, assignmentIdsSnapshot) {
        if (assignmentIdsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (assignmentIdsSnapshot.hasError) {
          return Center(child: Text('Error memuat daftar tugas: ${assignmentIdsSnapshot.error}'));
        }

        final adminAssignmentIds = assignmentIdsSnapshot.data ?? [];

        if (adminAssignmentIds.isEmpty) {
           return Scaffold(
             appBar: AppBar(
               title: const Text('Pengumpulan Tugas Siswa'),
               backgroundColor: const Color(0xFF2196F3),
             ),
             body: const Center(child: Text('Anda belum membuat tugas apa pun.')),
           );
        }

        // Gunakan daftar ID tugas untuk memfilter pengumpulan
        return Scaffold(
          appBar: AppBar(
            title: const Text('Pengumpulan Tugas Siswa'),
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
                    .where('assignmentId', whereIn: adminAssignmentIds) // Filter berdasarkan ID tugas admin
                    .orderBy('submittedAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error memuat pengumpulan tugas: ${snapshot.error}'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final submissions = snapshot.data!.docs.map((doc) {
                    // Menggunakan ID dokumen Firestore dan data field untuk membuat objek Submission
                    return Submission.fromMap({
                      ...doc.data() as Map<String, dynamic>,
                      'id': doc.id, // Ambil ID dokumen dari snapshot
                    });
                  }).toList();

                  if (submissions.isEmpty) {
                    return const Center(child: Text('Belum ada pengumpulan tugas.'));
                  }

                  return ListView.builder(
                    itemCount: submissions.length,
                    itemBuilder: (context, index) {
                      final submission = submissions[index];
                      
                      // Gunakan FutureBuilder untuk mengambil data tugas dan siswa
                      return FutureBuilder<Map<String, String>>(
                        future: Future.wait([
                          _getAssignmentTitle(submission.assignmentId),
                          _getStudentEmail(submission.studentId),
                        ]).then((results) => {
                          'assignmentTitle': results[0],
                          'studentEmail': results[1],
                        }),
                        builder: (context, dataSnapshot) {
                          if (dataSnapshot.connectionState == ConnectionState.waiting) {
                            // Tampilkan placeholder atau spinner ringan saat memuat data tambahan
                            return Card(
                               color: const Color(0xFF2D2D2D),
                               margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                               child: ListTile(
                                 title: Text('Memuat...', style: TextStyle(color: Colors.white70)),
                                 subtitle: Text('Dikumpulkan: ${submission.submittedAt.toDate().toLocal()}', style: const TextStyle(color: Colors.white70)),
                               ),
                             );
                          }
                          if (dataSnapshot.hasError) {
                             print('Error fetching related data: ${dataSnapshot.error}');
                             // Tampilkan dengan ID jika gagal memuat data tambahan
                             return Card(
                               color: const Color(0xFF2D2D2D),
                               margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                               child: ListTile(
                                 title: Text('Tugas ID: ${submission.assignmentId} (Error)', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),),
                                 subtitle: Text('Siswa ID: ${submission.studentId} (Error)\nDikumpulkan: ${submission.submittedAt.toDate().toLocal()}\nNilai: ${submission.grade == null ? 'Belum Dinilai' : submission.grade.toString()}', style: const TextStyle(color: Colors.white70),),
                                 onTap: () => _showGradingDialog(submission),
                               ),
                             );
                          }

                          // Data tugas dan siswa berhasil dimuat
                          final relatedData = dataSnapshot.data!;
                          final assignmentTitle = relatedData['assignmentTitle']!;
                          final studentEmail = relatedData['studentEmail']!;

                          return Card(
                            color: const Color(0xFF2D2D2D),
                            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                            child: ListTile(
                              title: Text('Tugas: $assignmentTitle', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),),
                              subtitle: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                    Text('Oleh: $studentEmail', style: const TextStyle(color: Colors.white70),),
                                    Text('Dikumpulkan: ${submission.submittedAt.toDate().toLocal()}', style: const TextStyle(color: Colors.white70),),
                                     Text('Nilai: ${submission.grade == null ? 'Belum Dinilai' : submission.grade.toString()}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent),),
                                 ],
                              ),
                               trailing: submission.fileUrl.isNotEmpty
                               ? Row(
                                   mainAxisSize: MainAxisSize.min,
                                   children: [
                                     // Ikon Penjepit Kertas (untuk buka URL)
                                     IconButton(
                                        icon: const Icon(Icons.attach_file, color: Colors.blue), // Warna biru untuk link
                                        onPressed: () {
                                          _launchUrl(context, submission.fileUrl); // Buka URL eksternal
                                        },
                                     ),
                                     // Ikon Gambar (untuk tampilkan gambar penuh, jika URL adalah gambar)
                                     if (_isImageUrl(submission.fileUrl))
                                       IconButton(
                                         icon: const Icon(Icons.image, color: Colors.green), // Ikon hijau untuk gambar
                                         onPressed: () {
                                           _showFullScreenImageDialog(context, submission.fileUrl); // Tampilkan gambar penuh
                                         },
                                       ),
                                   ],
                                 )
                               : null,
                              onTap: () => _showGradingDialog(submission), // Tap untuk memberi nilai
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
      },
    );
  }
} 
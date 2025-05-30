import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/content_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class ViewAssignmentsScreen extends StatefulWidget {
  const ViewAssignmentsScreen({super.key});

  @override
  State<ViewAssignmentsScreen> createState() => _ViewAssignmentsScreenState();
}

class _ViewAssignmentsScreenState extends State<ViewAssignmentsScreen> {
  File? _selectedImage;
  bool _isSubmitting = false;
  final TextEditingController _fileUrlController = TextEditingController();

  @override
  void dispose() {
    _fileUrlController.dispose();
    super.dispose();
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

  // Fungsi untuk mengecek apakah tugas sudah dikumpulkan
  Future<bool> _isAssignmentSubmitted(String assignmentId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;

    final querySnapshot = await FirebaseFirestore.instance
        .collection('submissions')
        .where('assignmentId', isEqualTo: assignmentId)
        .where('studentId', isEqualTo: currentUser.uid)
        .get();

    return querySnapshot.docs.isNotEmpty;
  }

  void _showAssignmentDetailAndSubmission(BuildContext context, Assignment assignment) async {
    final isSubmitted = await _isAssignmentSubmitted(assignment.id);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(assignment.title),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Deskripsi: ${assignment.description}'),
                const SizedBox(height: 8),
                Text('Tenggat: ${assignment.dueDate.toDate().toLocal().toString().split(' ')[0]}'),
                const SizedBox(height: 8),
                if (assignment.fileUrl.isNotEmpty)
                  InkWell(
                    onTap: () {
                      _launchUrl(context, assignment.fileUrl);
                    },
                    child: Text(
                      'Unduh File Tugas',
                      style: TextStyle(color: Theme.of(context).primaryColor, decoration: TextDecoration.underline),
                    ),
                  ),
                const SizedBox(height: 16),
                Text('Status Pengumpulan:'),
                Text(isSubmitted ? 'Sudah Dikumpulkan' : 'Belum Dikumpulkan'),
              ],
            ),
          ),
          actions: <Widget>[
            if (!isSubmitted)
              TextButton(
                child: const Text('Kumpulkan Tugas'),
                onPressed: () {
                  Navigator.of(context).pop(); // Tutup dialog
                  _showSubmissionForm(context, assignment); // Tampilkan form pengumpulan
                },
              ),
            TextButton(
              child: const Text('Tutup'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showSubmissionForm(BuildContext context, Assignment assignment) {
    // Reset state untuk form pengumpulan baru
    setState(() {
      _selectedImage = null;
      _fileUrlController.clear();
      _isSubmitting = false;
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Kumpulkan Tugas'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start, // Align items to the start
                  children: [
                    // Detail Tugas
                    Text(
                      assignment.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      assignment.description,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Tenggat: ${assignment.dueDate.toDate().toLocal().toString().split(' ')[0]}',
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                     if (assignment.fileUrl.isNotEmpty)
                       Padding(
                         padding: const EdgeInsets.only(top: 8.0),
                         child: InkWell(
                            onTap: () => _launchUrl(context, assignment.fileUrl),
                            child: Text(
                              'Unduh File Tugas (dari Admin)',
                              style: TextStyle(color: Theme.of(context).primaryColor, decoration: TextDecoration.underline),),),
                       ),
                    const Divider(height: 32), // Garis pemisah

                    // Bagian Pengumpulan
                    const Text(
                      'Form Pengumpulan Anda',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _fileUrlController,
                      decoration: InputDecoration(
                        labelText: 'URL File Tugas Anda (Opsional)',
                        hintText: 'Masukkan URL file tugas Anda (link Google Drive, dll.)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 15.0),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Bagian Pilih Foto
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0), // Padding di dalam container
                      decoration: BoxDecoration(
                         color: Colors.grey[800], // Warna latar belakang untuk bagian foto
                         borderRadius: BorderRadius.circular(8.0),
                         border: Border.all(color: Theme.of(context).primaryColor), // Border biru
                      ),
                      child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                            const Text('Atau Unggah Foto (Opsional)', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _isSubmitting ? null : () async {
                                final pickedImage = await _pickImage();
                                if (pickedImage != null) {
                                  setStateDialog(() {
                                    _selectedImage = pickedImage;
                                    _fileUrlController.clear(); // Kosongkan URL jika foto dipilih
                                  });
                                }
                              },
                              icon: const Icon(Icons.photo_library),
                              label: Text(_selectedImage == null ? 'Pilih Foto dari Galeri' : 'Ganti Foto: ${_selectedImage!.path.split('/').last}'),
                              style: ElevatedButton.styleFrom(
                                 foregroundColor: Colors.white, backgroundColor: Theme.of(context).primaryColor, // Warna teks dan ikon
                                 shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                 ),),),
                            const SizedBox(height: 8),
                            if (_selectedImage != null)
                              Center(
                                child: Image.file(_selectedImage!, height: 150, fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, color: Colors.red), // Handle error display
                                ),
                              ),
                         ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Batal'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => _submitAssignment(context, assignment),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Kumpulkan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<File?> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      return File(image.path);
    } else {
      return null;
    }
  }

  // Fungsi untuk upload ke Cloudinary
  Future<String?> _uploadToCloudinary(File imageFile) async {
    // Ganti dengan Cloud Name dan Upload Preset Anda
    final url = Uri.parse('https://api.cloudinary.com/v1_1/dmhbguqqa/image/upload'); // Ganti dmhbguqqa jika berbeda
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = 'my_flutter_upload' // Ganti public_uploads menjadi nama preset yang benar
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await http.Response.fromStream(response);
        final result = jsonDecode(responseData.body);
        return result['secure_url']; // Ini adalah URL file yang diunggah
      } else {
        print('Cloudinary upload failed with status: ${response.statusCode}');
        final responseData = await http.Response.fromStream(response);
        print('Response body: ${responseData.body}');
        return null;
      }
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      return null;
    }
  }

  // Fungsi untuk submit assignment
  void _submitAssignment(BuildContext context, Assignment assignment) async {
    // Validasi: Setidaknya salah satu (foto atau URL) harus diisi
    if (_selectedImage == null && _fileUrlController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih foto atau masukkan URL file tugas.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    String? finalFileUrl;

    try {
      if (_selectedImage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Mengunggah foto...'), duration: Duration(seconds: 5),)
        );
        finalFileUrl = await _uploadToCloudinary(_selectedImage!); // Panggil fungsi upload
        if (finalFileUrl == null) {
           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Gagal mengunggah foto.'), backgroundColor: Colors.red,)
             );
             setState(() {
               _isSubmitting = false;
             });
           }
           return;
        }
         if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Sembunyikan pesan mengunggah
         }

      } else if (_fileUrlController.text.trim().isNotEmpty) {
        finalFileUrl = _fileUrlController.text.trim();
      }

      if (finalFileUrl == null || finalFileUrl.isEmpty) {
         if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Tidak ada URL file untuk disimpan.'), backgroundColor: Colors.red,)
             );
             setState(() {
               _isSubmitting = false;
             });
         }
         return;
      }

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('User tidak ditemukan');

      await FirebaseFirestore.instance.collection('submissions').add({
        'assignmentId': assignment.id,
        'studentId': currentUser.uid,
        'fileUrl': finalFileUrl,
        'submittedAt': FieldValue.serverTimestamp(),
        'grade': null,
        'adminId': assignment.adminId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tugas berhasil dikumpulkan!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengumpulkan tugas: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Tugas'),
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
          child: Padding(
            padding: const EdgeInsets.all(16.0), // Tambahkan padding keseluruhan
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daftar Tugas Tersedia',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2196F3),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('assignments').orderBy('dueDate', descending: false).snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error memuat tugas: ${snapshot.error}'));
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final assignments = snapshot.data!.docs.map((doc) {
                        return Assignment.fromMap({
                          ...doc.data() as Map<String, dynamic>,
                          'id': doc.id,
                        });
                      }).toList();

                      if (assignments.isEmpty) {
                        return const Center(child: Text('Tidak ada tugas saat ini.'));
                      }

                      return ListView.builder(
                        itemCount: assignments.length,
                        itemBuilder: (context, index) {
                          final assignment = assignments[index];
                          return Card(
                            color: const Color(0xFF2D2D2D), // Warna latar kartu gelap
                            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0.0), // Atur margin horizontal di sini (di dalam Padding SafeArea)
                            elevation: 4.0,
                            shape: RoundedRectangleBorder(
                               borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: ListTile(
                              leading: Icon(Icons.assignment, color: Theme.of(context).primaryColorLight), // Tambahkan ikon tugas
                              title: Text(assignment.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                       Icon(Icons.calendar_today, size: 16, color: Colors.white70), // Ikon kalender
                                       const SizedBox(width: 4),
                                       Text('Tenggat: ${assignment.dueDate.toDate().toLocal().toString().split(' ')[0]}', style: const TextStyle(color: Colors.white70)),
                                    ],
                                  ),
                                   // Opsional: Tampilkan sedikit deskripsi di sini juga
                                   // if (assignment.description.isNotEmpty)
                                   //   Padding(
                                   //     padding: const EdgeInsets.only(top: 4.0),
                                   //     child: Text(
                                   //       assignment.description,
                                   //       style: const TextStyle(color: Colors.white54, fontSize: 12.0), // Warna dan ukuran lebih redup
                                   //       maxLines: 1, // Batasi hingga 1 baris
                                   //       overflow: TextOverflow.ellipsis, // Tampilkan ... jika terpotong
                                   //     ),
                                   //   ),
                                ],
                              ),
                              onTap: () => _showAssignmentDetailAndSubmission(context, assignment), // Tetap panggil dialog detail
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 
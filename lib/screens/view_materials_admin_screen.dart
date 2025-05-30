import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/content_model.dart'; // Untuk model LearningMaterial
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher
import 'package:firebase_auth/firebase_auth.dart'; // Import firebase_auth

class ViewMaterialsAdminScreen extends StatefulWidget {
  const ViewMaterialsAdminScreen({super.key});

  @override
  State<ViewMaterialsAdminScreen> createState() => _ViewMaterialsAdminScreenState();
}

class _ViewMaterialsAdminScreenState extends State<ViewMaterialsAdminScreen> {
  // Pindahkan controllers edit materi ke level State
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _fileUrlController; // Controller untuk URL

  @override
  void initState() {
    super.initState();
    // Inisialisasi controllers
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _fileUrlController = TextEditingController(); // Inisialisasi controller URL
  }

  @override
  void dispose() {
    // Pastikan controllers di-dispose di sini
    _titleController.dispose();
    _descriptionController.dispose();
    _fileUrlController.dispose(); // Dispose controller URL
    print('_titleController dan _descriptionController disposed from ViewMaterialsAdminScreen State'); // Log disposal
    print('_fileUrlController disposed from ViewMaterialsAdminScreen State'); // Log disposal URL
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser; // Dapatkan user saat ini

    if (currentUser == null) {
       return const Scaffold(
        body: Center(
          child: Text('Anda harus login sebagai admin.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Materi Pembelajaran'),
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
                .collection('materials')
                .where('adminId', isEqualTo: currentUser.uid) // Filter berdasarkan adminId
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error memuat materi: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // Tambahkan logging untuk melihat jumlah dokumen yang diambil
              print('Jumlah dokumen materi dari Firestore: ${snapshot.data!.docs.length}');

              final materials = snapshot.data!.docs.map((doc) {
                // Menggunakan ID dokumen Firestore dan data field untuk membuat objek LearningMaterial
                return LearningMaterial.fromMap({
                  ...doc.data() as Map<String, dynamic>,
                  'id': doc.id, // Ambil ID dokumen dari snapshot
                });
              }).toList();

              if (materials.isEmpty) {
                return const Center(child: Text('Belum ada materi pembelajaran.'));
              }

              return ListView.builder(
                itemCount: materials.length,
                itemBuilder: (context, index) {
                  final material = materials[index];
                  return Card(
                    color: const Color(0xFF2D2D2D),
                    margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    child: ListTile(
                      title: Text(material.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      subtitle: Text(material.description, style: const TextStyle(color: Colors.white70)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (material.fileUrl.isNotEmpty)
                            IconButton(
                              icon: Icon(Icons.attach_file, color: Theme.of(context).primaryColorLight),
                              onPressed: () {
                                _launchUrl(material.fileUrl);
                              },
                            ),
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.yellow[700]),
                            onPressed: () {
                              _showEditMaterialDialog(material);
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red[700]),
                            onPressed: () {
                              _confirmDeleteMaterial(material);
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        // TODO: Opsional: Implementasi tampilan detail materi
                      },
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

  // Fungsi untuk menampilkan dialog edit materi
  void _showEditMaterialDialog(LearningMaterial material) {
    // Set nilai controllers sesuai data materi yang akan diedit
    _titleController.text = material.title;
    _descriptionController.text = material.description;
    _fileUrlController.text = material.fileUrl; // Set nilai controller URL

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Materi'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Judul Materi'),
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Deskripsi'),
                  maxLines: 3,
                ),
                // Field untuk mengedit URL file
                TextFormField(
                  controller: _fileUrlController,
                  decoration: const InputDecoration(labelText: 'URL File (Opsional)'),
                  keyboardType: TextInputType.url,
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
              child: const Text('Simpan'),
              onPressed: () async {
                // TODO: Validasi input
                final newTitle = _titleController.text.trim();
                final newDescription = _descriptionController.text.trim();
                final newFileUrl = _fileUrlController.text.trim(); // Ambil nilai URL baru

                if (newTitle.isNotEmpty && newDescription.isNotEmpty) {
                  try {
                    await FirebaseFirestore.instance
                        .collection('materials')
                        .doc(material.id) // Gunakan ID materi yang ada
                        .update({
                      'title': newTitle,
                      'description': newDescription,
                      'fileUrl': newFileUrl, // Simpan URL file yang diperbarui
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Materi berhasil diperbarui!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.of(context).pop();
                    }
                  } catch (e) {
                    if (mounted) {
                       ScaffoldMessenger.of(context).showSnackBar(
                         SnackBar(
                           content: Text('Gagal memperbarui materi: ${e.toString()}'),
                           backgroundColor: Colors.red,
                         ),
                       );
                       Navigator.of(context).pop();
                    }
                  }
                } else {
                  // Tampilkan error validasi
                   if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(
                           content: Text('Judul dan Deskripsi tidak boleh kosong!'),
                           backgroundColor: Colors.red,
                         )
                      );
                   }
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Fungsi untuk menampilkan dialog konfirmasi hapus
  void _confirmDeleteMaterial(LearningMaterial material) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus Materi'),
          content: Text('Anda yakin ingin menghapus materi "${material.title}"?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
              child: const Text('Hapus'),
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance
                      .collection('materials')
                      .doc(material.id)
                      .delete();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Materi berhasil dihapus!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.of(context).pop();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal menghapus materi: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    Navigator.of(context).pop();
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Fungsi untuk meluncurkan URL file materi
  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        // Tangkap dan tampilkan error jika URL tidak bisa diluncurkan
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
       // Tangkap error lain saat meluncurkan URL dan tampilkan
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
} 
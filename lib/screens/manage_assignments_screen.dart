import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/content_model.dart';

class ManageAssignmentsScreen extends StatefulWidget {
  const ManageAssignmentsScreen({super.key});

  @override
  State<ManageAssignmentsScreen> createState() => _ManageAssignmentsScreenState();
}

class _ManageAssignmentsScreenState extends State<ManageAssignmentsScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _fileUrlController = TextEditingController();
  DateTime _selectedDueDate = DateTime.now().add(const Duration(days: 7));
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _fileUrlController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDueDate) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  void _showAddEditAssignmentDialog([Assignment? assignment]) {
    // Jika ini adalah edit, isi controller dengan data yang ada
    if (assignment != null) {
      _titleController.text = assignment.title;
      _descriptionController.text = assignment.description;
      _fileUrlController.text = assignment.fileUrl;
      _selectedDueDate = assignment.dueDate.toDate();
    } else {
      // Reset controller jika ini adalah tambah baru
      _titleController.clear();
      _descriptionController.clear();
      _fileUrlController.clear();
      _selectedDueDate = DateTime.now().add(const Duration(days: 7));
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(assignment == null ? 'Tambah Tugas Baru' : 'Edit Tugas'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Judul Tugas'),
                ),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Deskripsi'),
                  maxLines: 3,
                ),
                TextField(
                  controller: _fileUrlController,
                  decoration: const InputDecoration(
                    labelText: 'URL File Tugas',
                    hintText: 'Masukkan URL file tugas (opsional)',
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Tenggat Waktu'),
                  subtitle: Text(_selectedDueDate.toString().split(' ')[0]),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDate(context),
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
              onPressed: _isLoading
                  ? null
                  : () async {
                      if (_titleController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Judul tugas tidak boleh kosong'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setState(() {
                        _isLoading = true;
                      });

                      try {
                        final currentUser = FirebaseAuth.instance.currentUser;
                        if (currentUser == null) throw Exception('User tidak ditemukan');

                        final assignmentData = {
                          'title': _titleController.text.trim(),
                          'description': _descriptionController.text.trim(),
                          'fileUrl': _fileUrlController.text.trim(),
                          'dueDate': Timestamp.fromDate(_selectedDueDate),
                          'adminId': currentUser.uid,
                          'createdAt': FieldValue.serverTimestamp(),
                        };

                        if (assignment == null) {
                          // Tambah tugas baru
                          await FirebaseFirestore.instance
                              .collection('assignments')
                              .add(assignmentData);
                        } else {
                          // Update tugas yang ada
                          await FirebaseFirestore.instance
                              .collection('assignments')
                              .doc(assignment.id)
                              .update(assignmentData);
                        }

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(assignment == null
                                  ? 'Tugas berhasil ditambahkan!'
                                  : 'Tugas berhasil diperbarui!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          Navigator.of(context).pop();
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      }
                    },
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(assignment == null ? 'Tambah' : 'Simpan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteAssignment(Assignment assignment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: Text('Apakah Anda yakin ingin menghapus tugas "${assignment.title}"? Ini juga akan menghapus semua pengumpulan terkait.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Hapus'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        // 1. Cari semua pengumpulan tugas yang terkait dengan tugas ini
        final submissionSnapshot = await FirebaseFirestore.instance
            .collection('submissions')
            .where('assignmentId', isEqualTo: assignment.id)
            .get();

        // 2. Hapus setiap pengumpulan tugas yang ditemukan
        for (final doc in submissionSnapshot.docs) {
          await doc.reference.delete();
          print('Deleted submission: ${doc.id}');
        }

        // 3. Hapus tugas itu sendiri
        await FirebaseFirestore.instance
            .collection('assignments')
            .doc(assignment.id)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tugas dan pengumpulan terkait berhasil dihapus!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus tugas atau pengumpulan terkait: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Anda harus login sebagai admin.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Tugas'),
        backgroundColor: const Color(0xFF2196F3),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditAssignmentDialog(),
        child: const Icon(Icons.add),
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
                .collection('assignments')
                .where('adminId', isEqualTo: currentUser.uid)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
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
                return const Center(child: Text('Belum ada tugas.'));
              }

              return ListView.builder(
                itemCount: assignments.length,
                itemBuilder: (context, index) {
                  final assignment = assignments[index];
                  return Card(
                    color: const Color(0xFF2D2D2D),
                    margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    child: ListTile(
                      title: Text(assignment.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(assignment.description),
                          Text('Tenggat: ${assignment.dueDate.toDate().toString().split(' ')[0]}'),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.yellow),
                            onPressed: () => _showAddEditAssignmentDialog(assignment),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmDeleteAssignment(assignment),
                          ),
                        ],
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
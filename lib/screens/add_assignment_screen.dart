import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/content_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddAssignmentScreen extends StatefulWidget {
  const AddAssignmentScreen({super.key});

  @override
  State<AddAssignmentScreen> createState() => _AddAssignmentScreenState();
}

class _AddAssignmentScreenState extends State<AddAssignmentScreen> {
  final _formKeyAssignment = GlobalKey<FormState>();
  final _assignmentTitleController = TextEditingController();
  final _assignmentDescriptionController = TextEditingController();
  final _assignmentFileUrlController = TextEditingController();
  DateTime? _assignmentDueDate;
  bool _isLoadingAssignment = false;

  @override
  void dispose() {
    _assignmentTitleController.dispose();
    _assignmentDescriptionController.dispose();
    _assignmentFileUrlController.dispose();
    super.dispose();
  }

  Future<void> _addAssignment() async {
    if (_formKeyAssignment.currentState!.validate()) {
      setState(() {
        _isLoadingAssignment = true;
      });

      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Anda harus login sebagai admin.'), backgroundColor: Colors.red,)
            );
            setState(() {
              _isLoadingAssignment = false;
            });
          }
          return;
        }

        final docRef = FirebaseFirestore.instance.collection('assignments').doc();
        final newAssignment = Assignment(
          id: docRef.id,
          title: _assignmentTitleController.text.trim(),
          description: _assignmentDescriptionController.text.trim(),
          fileUrl: _assignmentFileUrlController.text.trim(),
          dueDate: _assignmentDueDate != null ? Timestamp.fromDate(_assignmentDueDate!) : Timestamp.now(),
          createdAt: Timestamp.now(),
          adminId: currentUser.uid,
        );

        await docRef.set(newAssignment.toMap());

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tugas berhasil ditambahkan!'),
              backgroundColor: Colors.green,
            ),
          );
          _clearAssignmentForm();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menambahkan tugas: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoadingAssignment = false;
          });
        }
      }
    }
  }

  void _clearAssignmentForm() {
    _assignmentTitleController.clear();
    _assignmentDescriptionController.clear();
    _assignmentFileUrlController.clear();
    setState(() {
      _assignmentDueDate = null;
    });
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _assignmentDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _assignmentDueDate) {
      setState(() {
        _assignmentDueDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Tugas'),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              color: const Color(0xFF2D2D2D),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKeyAssignment,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _assignmentTitleController,
                        decoration: const InputDecoration(labelText: 'Judul Tugas'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Judul tugas tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _assignmentDescriptionController,
                        decoration: const InputDecoration(labelText: 'Deskripsi Tugas'),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Deskripsi tugas tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _assignmentFileUrlController,
                        decoration: const InputDecoration(labelText: 'URL File Tugas (Opsional)'),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        title: Text(
                          _assignmentDueDate == null
                              ? 'Pilih Tanggal Tenggat'
                              : 'Tenggat: ${(_assignmentDueDate!).toLocal().toString().split(' ')[0]}',
                          style: TextStyle(color: const Color(0xFF64B5F6)),
                        ),
                        trailing: const Icon(Icons.calendar_today, color: Color(0xFF64B5F6)),
                        onTap: () => _selectDueDate(context),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _isLoadingAssignment ? null : _addAssignment,
                        child: _isLoadingAssignment
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Tambah Tugas'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 
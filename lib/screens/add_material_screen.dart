import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/content_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddMaterialScreen extends StatefulWidget {
  const AddMaterialScreen({super.key});

  @override
  State<AddMaterialScreen> createState() => _AddMaterialScreenState();
}

class _AddMaterialScreenState extends State<AddMaterialScreen> {
  final _formKeyMaterial = GlobalKey<FormState>();
  final _materialTitleController = TextEditingController();
  final _materialDescriptionController = TextEditingController();
  final _materialFileUrlController = TextEditingController();
  bool _isLoadingMaterial = false;

  @override
  void dispose() {
    _materialTitleController.dispose();
    _materialDescriptionController.dispose();
    _materialFileUrlController.dispose();
    super.dispose();
  }

  Future<void> _addLearningMaterial() async {
    if (_formKeyMaterial.currentState!.validate()) {
      setState(() {
        _isLoadingMaterial = true;
      });

      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Anda harus login sebagai admin.'), backgroundColor: Colors.red,)
            );
            setState(() {
              _isLoadingMaterial = false;
            });
          }
          return;
        }

        final docRef = FirebaseFirestore.instance.collection('materials').doc();
        final newMaterial = LearningMaterial(
          id: docRef.id,
          title: _materialTitleController.text.trim(),
          description: _materialDescriptionController.text.trim(),
          fileUrl: _materialFileUrlController.text.trim(),
          createdAt: Timestamp.now(),
          adminId: currentUser.uid,
        );

        await docRef.set(newMaterial.toMap());

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Materi berhasil ditambahkan!'),
              backgroundColor: Colors.green,
            ),
          );
          _clearMaterialForm();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menambahkan materi: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoadingMaterial = false;
          });
        }
      }
    }
  }

  void _clearMaterialForm() {
    _materialTitleController.clear();
    _materialDescriptionController.clear();
    _materialFileUrlController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Materi'),
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
                  key: _formKeyMaterial,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _materialTitleController,
                        decoration: const InputDecoration(labelText: 'Judul Materi'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Judul materi tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _materialDescriptionController,
                        decoration: const InputDecoration(labelText: 'Deskripsi Materi'),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Deskripsi materi tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _materialFileUrlController,
                        decoration: const InputDecoration(labelText: 'URL File Materi (Opsional)'),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _isLoadingMaterial ? null : _addLearningMaterial,
                        child: _isLoadingMaterial
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Tambah Materi'),
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
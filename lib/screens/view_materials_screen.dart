import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/content_model.dart';
import 'package:url_launcher/url_launcher.dart';

class ViewMaterialsScreen extends StatelessWidget {
  const ViewMaterialsScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Materi'),
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
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Materi Pembelajaran',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2196F3),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('materials').orderBy('createdAt', descending: true).snapshots(),
                    builder: (context, snapshot) {
                       if (snapshot.hasError) {
                        return Center(child: Text('Error memuat materi: ${snapshot.error}'));
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final materials = snapshot.data!.docs.map((doc) {
                        return LearningMaterial.fromMap(doc.data() as Map<String, dynamic>);
                      }).toList();

                       if (materials.isEmpty) {
                        return const Center(child: Text('Tidak ada materi saat ini.'));
                      }

                      return ListView.builder(
                        itemCount: materials.length,
                        itemBuilder: (context, index) {
                          final material = materials[index];
                          return Card(
                             color: const Color(0xFF2D2D2D),
                             margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                            child: ListTile(
                              title: Text(material.title,
                               style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              subtitle: Text(material.description,
                               style: const TextStyle(color: Colors.white70),
                              ),
                               onTap: () {
                                // TODO: Tampilkan detail materi
                                // Bisa juga menambahkan tombol untuk buka fileUrl jika ada
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text(material.title),
                                      content: SingleChildScrollView(
                                        child: ListBody(
                                          children: <Widget>[
                                            Text('Deskripsi: ${material.description}', style: const TextStyle(color: Colors.white70),),
                                            const SizedBox(height: 8),
                                             if (material.fileUrl.isNotEmpty)
                                              InkWell(
                                                onTap: () {
                                                  _launchUrl(context, material.fileUrl);
                                                },
                                                child: Text(
                                                  'Unduh Materi',
                                                  style: TextStyle(color: Theme.of(context).primaryColor, decoration: TextDecoration.underline),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      actions: <Widget>[
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
                               },
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
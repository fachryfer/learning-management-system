import 'package:cloud_firestore/cloud_firestore.dart';

class Assignment {
  final String id;
  final String title;
  final String description;
  final String fileUrl; // URL file materi/tugas jika ada
  final Timestamp dueDate;
  final Timestamp createdAt;
  final String adminId;

  Assignment({
    required this.id,
    required this.title,
    required this.description,
    required this.fileUrl,
    required this.dueDate,
    required this.createdAt,
    required this.adminId,
  });

  factory Assignment.fromMap(Map<String, dynamic> map) {
    return Assignment(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      fileUrl: map['fileUrl'] ?? '',
      dueDate: map['dueDate'] ?? Timestamp.now(),
      createdAt: map['createdAt'] ?? Timestamp.now(),
      adminId: map['adminId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'fileUrl': fileUrl,
      'dueDate': dueDate,
      'createdAt': createdAt,
      'adminId': adminId,
    };
  }
}

class LearningMaterial {
  final String id;
  final String title;
  final String description;
  final String fileUrl; // URL file materi jika ada
  final Timestamp createdAt;
  final String adminId;

  LearningMaterial({
    required this.id,
    required this.title,
    required this.description,
    required this.fileUrl,
    required this.createdAt,
    required this.adminId,
  });

  factory LearningMaterial.fromMap(Map<String, dynamic> map) {
    return LearningMaterial(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      fileUrl: map['fileUrl'] ?? '',
      createdAt: map['createdAt'] ?? Timestamp.now(),
      adminId: map['adminId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'fileUrl': fileUrl,
      'createdAt': createdAt,
      'adminId': adminId,
    };
  }
}

class Submission {
  final String id;
  final String assignmentId;
  final String studentId;
  final String fileUrl; // URL file pengumpulan tugas
  final String? textSubmission; // Pengumpulan dalam bentuk teks (opsional)
  final Timestamp submittedAt;
  final double? grade;
  final String? feedback;
  final String? adminId;

  Submission({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.fileUrl,
    this.textSubmission,
    required this.submittedAt,
    this.grade,
    this.feedback,
    this.adminId,
  });

  factory Submission.fromMap(Map<String, dynamic> map) {
    return Submission(
      id: map['id'] ?? '',
      assignmentId: map['assignmentId'] ?? '',
      studentId: map['studentId'] ?? '',
      fileUrl: map['fileUrl'] ?? '',
      textSubmission: map['textSubmission'],
      submittedAt: map['submittedAt'] ?? Timestamp.now(),
      grade: map['grade'] as double?,
      feedback: map['feedback'] as String?,
      adminId: map['adminId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'assignmentId': assignmentId,
      'studentId': studentId,
      'fileUrl': fileUrl,
      'textSubmission': textSubmission,
      'submittedAt': submittedAt,
      'grade': grade,
      'feedback': feedback,
      'adminId': adminId,
    };
  }
} 
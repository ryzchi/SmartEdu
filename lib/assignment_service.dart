import 'package:cloud_firestore/cloud_firestore.dart';

class AssignmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Hardcoded credentials for demo purposes
  static const Map<String, Map<String, String>> demoCredentials = {
    'student': {
      'email': 'student@gmail.com',
      'password': '123456789',
      'name': 'Juan Dela Cruz',
    },
    'faculty': {
      'email': 'userfc@dpnhs.edu.ph',
      'password': 'fc123456789',
      'name': 'Maria Santos',
    },
    'teacher': {
      'email': 'usertc@dpnhs.edu.ph',
      'password': 'tc123456789',
      'name': 'Maria Santos',
    },
  };

  Future<void> createAssignment({
    required String title,
    required String description,
    required DateTime deadline,
  }) async {
    await _firestore.collection('assignments').add({
      'title': title,
      'description': description,
      'deadline': deadline,
      'createdAt': Timestamp.now(),
    });
  }

  Future<void> submitAssignment({
    required String assignmentId,
    required String fileUrl,
  }) async {
    await _firestore.collection('submissions').add({
      'assignmentId': assignmentId,
      'fileUrl': fileUrl,
      'submittedAt': Timestamp.now(),
    });
  }
}
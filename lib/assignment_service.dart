import 'package:cloud_firestore/cloud_firestore.dart';

class AssignmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
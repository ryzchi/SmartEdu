import '../services/api_client.dart';

class AssignmentService {
  final ApiClient _api = ApiClient();

  Future<List<Map<String, dynamic>>> fetchAssignments() async {
    final response = await _api.get('assignments.php');

    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(
        (response['assignments'] ?? []) as List,
      );
    }

    return [];
  }

  Future<Map<String, dynamic>> createAssignment({
    required String title,
    required String description,
    required String deadline,
  }) async {
    return _api.post('assignments.php', {
      'title': title,
      'description': description,
      'deadline': deadline,
    });
  }

  Future<Map<String, dynamic>> editAssignment({
    required String id,
    required String title,
    required String description,
    required String deadline,
  }) async {
    return _api.post('assignments.php', {
      'action': 'edit',
      'id': id,
      'title': title,
      'description': description,
      'deadline': deadline,
    });
  }

  Future<Map<String, dynamic>> deleteAssignment(
    String id,
  ) async {
    return _api.post('assignments.php', {
      'action': 'delete',
      'id': id,
    });
  }

   Future<Map<String, dynamic>> submitAssignment({
    required String assignmentId,
    required String filePath,
    required String studentEmail,
  }) async {
    return _api.uploadFile(
      'submit_assignment.php',
      'file',
      filePath,
      fields: {
        'assignment_id': assignmentId,
        'student_email': studentEmail,
        'status': 'Pending',
      },
    );
  }

  Future<List<Map<String, dynamic>>> fetchSubmissions() async {
    final response = await _api.get('submissions.php');

    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(
        response['submissions'],
      );
    }

    return [];
  }

  Future<Map<String, dynamic>> reviewSubmission({
    required String submissionId,
    required String status,
    required String feedback,
  }) async {
    return _api.post('review_submission.php', {
      'submission_id': submissionId,
      'status': status,
      'feedback': feedback,
    });
  }
}
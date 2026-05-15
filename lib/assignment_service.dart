import '../services/api_client.dart';

class AssignmentService {
  final ApiClient _api = ApiClient();

  Future<List<Map<String, dynamic>>> fetchAssignments() async {
    final response = await _api.get('assignments.php');
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from((response['assignments'] ?? []) as List);
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
      },
    );
  }
}

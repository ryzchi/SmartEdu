import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../security_service/auth_service.dart';
import '../services/api_client.dart';

class StudentController extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiClient _api = ApiClient();

  bool isLoadingAssignments = false;

  List<Map<String, dynamic>> assignments = [];
  List<Map<String, dynamic>> submissions = [];
  List<Map<String, dynamic>> attendanceRecords = [];
  List<Map<String, dynamic>> announcements = [];
  List<Map<String, dynamic>> quizzes = [];
  List<Map<String, dynamic>> quizAttempts = [];

  int newAnnouncementCount = 0;
  Set<int> readAnnouncementIds = {};

  AuthService get authService => _authService;

  Future<void> init() async {
    await Future.wait([
      loadAssignmentsWithStatus(),
      loadAttendanceData(),
      loadAnnouncementsFromTeacher(),
      loadTeacherQuizzes(),
      loadStudentQuizAttempts(),
    ]);
  }

  Future<void> loadAttendanceData() async {
    final prefs = await SharedPreferences.getInstance();
    final studentEmail = _authService.currentUserEmail ?? 'student';
    final key = 'attendance_${studentEmail.replaceAll('.', '_')}';
    final String? data = prefs.getString(key);
    if (data != null) {
      attendanceRecords = List<Map<String, dynamic>>.from(jsonDecode(data));
    } else {
      attendanceRecords = [];
    }
    notifyListeners();
  }

  Future<void> loadAnnouncementsFromTeacher() async {
    final prefs = await SharedPreferences.getInstance();
    final studentEmail = _authService.currentUserEmail ?? 'student';
    final readKey =
        'read_announcements_${studentEmail.replaceAll('.', '_')}';

    try {
      final response = await _api.get('announcements.php');
      if (response['success'] == true) {
        final loaded = List<Map<String, dynamic>>.from(
          response['announcements'] ?? [],
        );

        final readIdsJson = prefs.getString(readKey);
        if (readIdsJson != null) {
          readAnnouncementIds = Set<int>.from(
            jsonDecode(readIdsJson) as List,
          );
        }

        announcements = loaded;
        newAnnouncementCount = announcements
            .where(
              (a) => !readAnnouncementIds.contains(announcements.indexOf(a)),
            )
            .length;
      } else {
        announcements = [];
      }
    } catch (e) {
      print('Error loading announcements: $e');
      announcements = [];
    }
    notifyListeners();
  }

  Future<void> markAnnouncementAsRead(int index) async {
    if (readAnnouncementIds.contains(index)) return;
    final prefs = await SharedPreferences.getInstance();
    final studentEmail = _authService.currentUserEmail ?? 'student';
    final readKey =
        'read_announcements_${studentEmail.replaceAll('.', '_')}';

    readAnnouncementIds.add(index);
    await prefs.setString(
      readKey,
      jsonEncode(readAnnouncementIds.toList()),
    );

    newAnnouncementCount = announcements
        .where(
          (a) => !readAnnouncementIds.contains(announcements.indexOf(a)),
        )
        .length;
    notifyListeners();
  }

  Future<void> loadAssignmentsWithStatus() async {
    isLoadingAssignments = true;
    notifyListeners();

    try {
      final assignmentsResponse = await _api.get('assignments.php');
      if (assignmentsResponse['success'] == true) {
        assignments = List<Map<String, dynamic>>.from(
          assignmentsResponse['assignments'] ?? [],
        );
      } else {
        assignments = [];
      }

      final prefs = await SharedPreferences.getInstance();
      final studentEmail = _authService.currentUserEmail ?? 'student';
      final submissionsKey =
          'submissions_${studentEmail.replaceAll('.', '_')}';
      final submissionsJson = prefs.getString(submissionsKey);

      submissions = submissionsJson != null
          ? List<Map<String, dynamic>>.from(jsonDecode(submissionsJson))
          : [];
    } catch (e) {
      print('Error loading data: $e');
      assignments = [];
      submissions = [];
    } finally {
      isLoadingAssignments = false;
      notifyListeners();
    }
  }

  bool isAssignmentSubmitted(String assignmentId) {
    return submissions.any((sub) => sub['assignment_id'] == assignmentId);
  }

  Map<String, dynamic>? getSubmission(String assignmentId) {
    try {
      return submissions.firstWhere(
        (sub) => sub['assignment_id'] == assignmentId,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> submitAssignment(
    String assignmentId,
    String comment,
    String fileName,
    Uint8List? fileBytes,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final studentEmail = _authService.currentUserEmail ?? 'student';
    final studentName = _authService.currentUserName ?? 'Student';

    String assignmentTitle = '';
    try {
      final assignment = assignments.firstWhere((a) => a['id'] == assignmentId);
      assignmentTitle = assignment['title'] ?? 'Unknown';
    } catch (e) {
      assignmentTitle = 'Unknown';
    }

    final submission = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'assignment_id': assignmentId,
      'assignment_title': assignmentTitle,
      'student_email': studentEmail,
      'student_name': studentName,
      'status': 'Pending',
      'feedback': '',
      'comment': comment,
      'file_name': fileName,
      'file_size': fileBytes?.length ?? 0,
      'submitted_at': DateTime.now().toIso8601String(),
    };

    final globalSubmissionsJson = prefs.getString('all_submissions');
    List<Map<String, dynamic>> allSubmissions = globalSubmissionsJson != null
        ? List<Map<String, dynamic>>.from(jsonDecode(globalSubmissionsJson))
        : [];
    allSubmissions.add(submission);
    await prefs.setString('all_submissions', jsonEncode(allSubmissions));

    // Save to student-specific submissions
    final studentKey = 'submissions_${studentEmail.replaceAll('.', '_')}';
    final studentSubmissionsJson = prefs.getString(studentKey);
    List<Map<String, dynamic>> studentSubmissions =
        studentSubmissionsJson != null
        ? List<Map<String, dynamic>>.from(jsonDecode(studentSubmissionsJson))
        : [];
    studentSubmissions.add(submission);
    await prefs.setString(studentKey, jsonEncode(studentSubmissions));

    submissions.add(submission);
    notifyListeners();
  }

  Future<void> loadTeacherQuizzes() async {
    final prefs = await SharedPreferences.getInstance();
    final quizzesJson = prefs.getString('teacher_quizzes');
    quizzes = quizzesJson != null
        ? List<Map<String, dynamic>>.from(jsonDecode(quizzesJson))
        : [];
    notifyListeners();
  }

  Future<void> loadStudentQuizAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    final studentEmail =
        (_authService.currentUserEmail ?? 'student').replaceAll('.', '_');
    final attemptsJson = prefs.getString('quiz_attempts_$studentEmail');
    quizAttempts = attemptsJson != null
        ? List<Map<String, dynamic>>.from(jsonDecode(attemptsJson))
        : [];
    notifyListeners();
  }

  Map<String, dynamic>? getQuizById(String id) {
    try {
      return quizzes.firstWhere((quiz) => quiz['id'].toString() == id);
    } catch (_) {
      return null;
    }
  }

  Future<bool> logout() async {
    try {
      await _authService.logout();
      return true;
    } catch (e) {
      return false;
    }
  }
}

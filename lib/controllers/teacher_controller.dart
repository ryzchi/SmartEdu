import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' as io;

import '../security_service/auth_service.dart';
import '../services/api_client.dart';
import '../pages/uploaded_material.dart';

class TeacherController extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiClient _api = ApiClient();

  Timer? _notificationTimer;

  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> announcements = [];
  List<Map<String, dynamic>> materials = [];
  List<Map<String, dynamic>> assignments = [];
  List<Map<String, dynamic>> submissions = [];
  List<Map<String, dynamic>> attendanceRecords = [];
  List<Map<String, dynamic>> quizzes = [];
  List<Map<String, dynamic>> notifications = [];

  int _fileCounter = 0;

  AuthService get authService => _authService;

  void init() {
    loadAllData();
    loadQuizzes();
    loadNotifications();
    _notificationTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => loadNotifications(),
    );
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  Future<void> loadAllData() async {
    await Future.wait([
      loadStudents(),
      loadAnnouncements(),
      loadMaterials(),
      loadAssignments(),
      loadSubmissions(),
      loadAttendance(),
    ]);
    notifyListeners();
  }

  Future<void> loadStudents() async {
    try {
      final response = await _api.get('students.php');
      if (response['success'] == true) {
        students = List<Map<String, dynamic>>.from(response['students'] ?? []);
      } else {
        students = [];
      }
    } catch (e) {
      students = [];
    }
    notifyListeners();
  }

  Future<void> loadAnnouncements() async {
    try {
      final response = await _api.get('announcements.php');
      if (response['success'] == true) {
        announcements = List<Map<String, dynamic>>.from(
          response['announcements'] ?? [],
        );
      } else {
        announcements = [];
      }
    } catch (e) {
      announcements = [];
    }
    notifyListeners();
  }

  Future<void> loadMaterials() async {
    try {
      final response = await _api.get('materials.php');
      if (response['success'] == true) {
        materials = List<Map<String, dynamic>>.from(
          response['materials'] ?? [],
        );
      } else {
        materials = [];
      }
    } catch (e) {
      materials = [];
    }
    notifyListeners();
  }

  Future<void> loadAssignments() async {
    try {
      final response = await _api.get('assignments.php');
      if (response['success'] == true) {
        assignments = List<Map<String, dynamic>>.from(
          response['assignments'] ?? [],
        );
      } else {
        assignments = [];
      }
    } catch (e) {
      assignments = [];
    }
    notifyListeners();
  }

  Future<void> loadSubmissions() async {
    try {
      final response = await _api.get('submissions.php');
      if (response['success'] == true) {
        submissions = List<Map<String, dynamic>>.from(
          response['submissions'] ?? [],
        );
      } else {
        submissions = [];
      }
    } catch (e) {
      submissions = [];
    }
    notifyListeners();
  }

  Future<void> loadAttendance() async {
    try {
      final response = await _api.get('attendance.php');
      if (response['success'] == true) {
        attendanceRecords = List<Map<String, dynamic>>.from(
          response['attendance_records'] ?? [],
        );
      } else {
        attendanceRecords = [];
      }
    } catch (e) {
      print('Error loading attendance: $e');
      attendanceRecords = [];
    }
    notifyListeners();
  }

  Future<void> loadNotifications() async {
    try {
      final userId = _authService.currentUserId ?? 0;
      if (userId <= 0) return;
      final response = await _api.get('notifications.php?user_id=$userId');
      if (response['success'] == true) {
        notifications = List<Map<String, dynamic>>.from(
          response['notifications'] ?? [],
        );
      } else {
        notifications = [];
      }
    } catch (e) {
      print('Error loading notifications: $e');
      notifications = [];
    }
    notifyListeners();
  }

  Future<void> loadQuizzes() async {
    try {
      final response = await _api.get('quizzes.php');
      if (response['success'] == true) {
        quizzes = List<Map<String, dynamic>>.from(response['quizzes'] ?? []);
      } else {
        quizzes = [];
      }
    } catch (e) {
      print('Error loading quizzes: $e');
      quizzes = [];
    }
    notifyListeners();
  }

  Future<void> saveQuizzes() async {
    try {
      for (var quiz in quizzes) {
        await _api.post('quizzes.php', {
          'action': 'save',
          'id': quiz['id'],
          'title': quiz['title'],
          'description': quiz['description'],
          'questions': jsonEncode(quiz['questions']),
          'teacher_id': _authService.currentUserId ?? 0,
        });
      }
    } catch (e) {
      print('Error in saveQuizzes: $e');
    }
  }

  Future<Map<String, dynamic>?> createQuizApi(
    String title,
    String description,
  ) async {
    final newQuiz = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'description': description,
      'questions': <Map<String, dynamic>>[],
    };
    try {
      final response = await _api.post('quizzes.php', {
        'action': 'create',
        'id': newQuiz['id'],
        'title': newQuiz['title'],
        'description': newQuiz['description'],
        'teacher_id': _authService.currentUserId ?? 0,
      });
      if (response['success'] == true) {
        quizzes.add(newQuiz);
        notifyListeners();
        return newQuiz;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  void saveQuizQuestions(
    Map<String, dynamic> quiz,
    List<Map<String, dynamic>> questions,
  ) {
    final index = quizzes.indexWhere((q) => q['id'] == quiz['id']);
    if (index != -1) {
      quizzes[index]['questions'] = questions;
      notifyListeners();
      saveQuizzes();
    }
  }

  int autoScoreMultipleChoice(
    List<Map<String, dynamic>> questions,
    Map<String, dynamic> studentAnswers,
  ) {
    int score = 0;
    for (var question in questions) {
      if (question['type'] == 'Multiple Choice') {
        final correctAnswer =
            question['correctAnswer']?.toString().toUpperCase() ?? '';
        final studentAnswer =
            studentAnswers[question['text']]?.toString().toUpperCase() ?? '';
        if (correctAnswer == studentAnswer) score++;
      }
    }
    return score;
  }

  int autoScoreIdentification(
    List<Map<String, dynamic>> questions,
    Map<String, dynamic> studentAnswers,
  ) {
    int score = 0;
    for (var question in questions) {
      if (question['type'] == 'Identification') {
        final correctAnswer =
            question['answer']?.toString().toLowerCase().trim() ?? '';
        final studentAnswer =
            studentAnswers[question['text']]?.toString().toLowerCase().trim() ??
            '';
        if (correctAnswer == studentAnswer) score++;
      }
    }
    return score;
  }

  Future<void> saveAttendanceRecords() async {
    try {
      for (var record in attendanceRecords) {
        await _api.post('attendance.php', {
          'action': 'save',
          'date': record['date'],
          'display_date': record['displayDate'],
          'statuses': jsonEncode(record['statuses']),
          'teacher_id': _authService.currentUserId ?? 0,
        });
      }
    } catch (e) {
      print('Error in saveAttendanceRecords: $e');
    }
  }

  Future<String?> createAttendanceRecord(DateTime selectedDate) async {
    final dateKey =
        "${selectedDate.year}-${selectedDate.month}-${selectedDate.day}";
    if (attendanceRecords.any((r) => r['date'] == dateKey)) {
      return 'exists';
    }
    Map<String, String> statuses = {};
    for (var student in students) {
      statuses[student['id'].toString()] = 'Present';
    }
    final newRecord = {
      'date': dateKey,
      'displayDate': "${selectedDate.toLocal()}".split(' ')[0],
      'statuses': statuses,
    };
    try {
      final response = await _api.post('attendance.php', {
        'action': 'create',
        'date': dateKey,
        'display_date': "${selectedDate.toLocal()}".split(' ')[0],
        'statuses': jsonEncode(statuses),
        'teacher_id': _authService.currentUserId ?? 0,
      });
      if (response['success'] == true) {
        attendanceRecords.add(newRecord);
        notifyListeners();
        return dateKey;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> updateAttendanceStatuses(
    String dateKey,
    Map<String, String> statuses,
  ) async {
    final index = attendanceRecords.indexWhere((r) => r['date'] == dateKey);
    if (index != -1) {
      attendanceRecords[index]['statuses'] = statuses;
      notifyListeners();
      await saveAttendanceRecords();
    }
  }

  String generateFileId() {
    _fileCounter++;
    return 'file_${DateTime.now().millisecondsSinceEpoch}_$_fileCounter';
  }

  String fixFileUrl(String url) {
    if (url.isEmpty) return url;
    if (url.startsWith('http')) return url;
    const baseUrl = 'http://localhost/ADET/backend/php/';
    return '$baseUrl$url';
  }

  Future<Uint8List?> fetchFileBytes(String fileUrl) async {
    try {
      final fixedUrl = fixFileUrl(fileUrl);
      final response = await _api.get(fixedUrl);
      return null; 
    } catch (e) {
      return null;
    }
  }

  Future<void> addUploadedMaterial(
    UploadedMaterial uploadedMaterial,
    Function(String) onSuccess,
    Function(String) onError,
  ) async {
    final fileExtension =
        uploadedMaterial.fileName.split('.').last.toUpperCase();
    String? localPath;

    if (!kIsWeb &&
        uploadedMaterial.fileBytes != null &&
        uploadedMaterial.fileBytes!.isNotEmpty) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final file = io.File('${dir.path}/${uploadedMaterial.fileName}');
        await file.writeAsBytes(uploadedMaterial.fileBytes!);
        localPath = file.path;
      } catch (e) {
        print('Error saving file: $e');
      }
    } else if (uploadedMaterial.fileUrl != null &&
        uploadedMaterial.fileUrl!.isNotEmpty) {
      localPath = uploadedMaterial.fileUrl;
    }

    final newMaterial = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': uploadedMaterial.title,
      'subject': uploadedMaterial.subject,
      'date': DateTime.now().toString().split(' ')[0],
      'format': fileExtension,
      'filePath': localPath ?? '',
      'fileUrl': uploadedMaterial.fileUrl,
    };
    materials.insert(0, newMaterial);
    notifyListeners();

    try {
      final response = await _api.post('materials.php', {
        'action': 'create',
        'title': uploadedMaterial.title,
        'subject': uploadedMaterial.subject,
        'type': fileExtension,
        'file_url': localPath ?? '',
        'uploaded_by': _authService.currentUserId ?? 0,
      });
      if (response['success'] != true) {
        onError('Database save failed: ${response['message']}');
      } else {
        onSuccess('${uploadedMaterial.title} added to Lesson Plans!');
      }
    } catch (e) {
      onError('Connection error: $e');
    }
  }

  Future<void> deleteMaterial(String id) async {
    materials.removeWhere((m) => m['id'].toString() == id);
    notifyListeners();
    try {
      await _api.post('materials.php', {'action': 'delete', 'id': id});
    } catch (e) {
      print('Error deleting material: $e');
    }
  }

  Future<void> updateMaterial(String id, String title, String subject) async {
    final index = materials.indexWhere((m) => m['id'].toString() == id);
    if (index != -1) {
      materials[index]['title'] = title;
      materials[index]['subject'] = subject;
      notifyListeners();
      try {
        await _api.post('materials.php', {
          'action': 'update',
          'id': id,
          'title': title,
          'subject': subject,
        });
      } catch (e) {
        print('Error updating material: $e');
      }
    }
  }

  Future<bool> createAnnouncement(
    String title,
    String content,
    String color,
  ) async {
    try {
      final response = await _api.post('announcements.php', {
        'action': 'create',
        'title': title,
        'content': content,
        'color': color,
        'author_id': _authService.currentUserId ?? 0,
      });
      if (response['success'] == true) {
        await loadAnnouncements();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteAnnouncement(int id) async {
    try {
      final response = await _api.post('announcements.php', {
        'action': 'delete',
        'id': id,
      });
      if (response['success'] == true) {
        await loadAnnouncements();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> createAssignment(
    String title,
    String description,
    String deadline,
    String subject,
  ) async {
    try {
      final response = await _api.post('assignments.php', {
        'title': title,
        'description': description,
        'deadline': deadline,
        'subject': subject,
      });
      if (response['success'] == true) {
        await loadAssignments();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteAssignment(int id) async {
    try {
      final response = await _api.post('assignments.php', {
        'action': 'delete',
        'id': id,
      });
      if (response['success'] == true) {
        await loadAssignments();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  int getUnreadNotificationCount() {
    return notifications
        .where((n) => n['read_status'] == 0 || n['read_status'] == false)
        .length;
  }

  Future<void> createNotification({
    required String title,
    required String message,
    String type = 'info',
    String actionUrl = '',
  }) async {
    try {
      final userId = _authService.currentUserId ?? 0;
      if (userId <= 0) return;
      await _api.post('notifications.php', {
        'action': 'create',
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type,
        'action_url': actionUrl,
      });
      await loadNotifications();
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  Future<void> markNotificationAsRead(int notificationId) async {
    try {
      await _api.post('notifications.php', {
        'action': 'mark_read',
        'notification_id': notificationId,
      });
      final index = notifications.indexWhere((n) => n['id'] == notificationId);
      if (index != -1) {
        notifications[index]['read_status'] = 1;
        notifyListeners();
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> markAllNotificationsRead() async {
    try {
      await _api.post('notifications.php', {
        'action': 'mark_all_read',
        'user_id': _authService.currentUserId ?? 0,
      });
      for (var n in notifications) {
        n['read_status'] = 1;
      }
      notifyListeners();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  Future<void> deleteNotification(int notificationId) async {
    try {
      await _api.post('notifications.php', {
        'action': 'delete',
        'notification_id': notificationId,
      });
      notifications.removeWhere((n) => n['id'] == notificationId);
      notifyListeners();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  int getPendingSubmissionsCount() {
    return submissions.where((s) => s['status'] == 'Pending').length;
  }

  String getDisplayDate(Map<String, dynamic> material) {
    String rawDate =
        material['created_at']?.toString() ??
        material['date']?.toString() ??
        '';
    if (rawDate.isEmpty) return 'No date';
    if (rawDate.contains(' ')) return rawDate.split(' ')[0];
    if (rawDate.contains('T')) return rawDate.split('T')[0];
    return rawDate;
  }

  String formatNotificationTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final dt = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
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

import 'dart:io' as io;
import 'dart:html' as html;
import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../pages/upload_material_page.dart';
import '../pages/uploaded_material.dart';
import '../security_service/auth_service.dart';
import '../pages/teacher_review_page.dart';
import '../pages/file_viewer_widget.dart';
import '../services/api_client.dart';
import 'package:flutter/services.dart';


class TeacherDashboardPage extends StatefulWidget {
  const TeacherDashboardPage({super.key});

  @override
  State<TeacherDashboardPage> createState() => _TeacherDashboardPageState();
}

class _TeacherDashboardPageState extends State<TeacherDashboardPage> {
  final _authService = AuthService();
  final ApiClient _api = ApiClient();
  int _selectedIndex = 0;
  bool _isMobile = false;
  Timer? _notificationTimer;

  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _announcements = [];
  List<Map<String, dynamic>> _materials = [];
  List<Map<String, dynamic>> _assignments = [];
  List<Map<String, dynamic>> _submissions = [];
  List<Map<String, dynamic>> _attendanceRecords = [];
  List<Map<String, dynamic>> _quizzes = [];
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadAllData();
    _loadQuizzes();
    _loadNotifications();

    // Set up periodic notification refresh (every 30 seconds)
    _notificationTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadNotifications(),
    );
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  // ========== API LOADERS ==========
  Future<void> _loadAllData() async {
    await Future.wait([
      _loadStudents(),
      _loadAnnouncements(),
      _loadMaterials(),
      _loadAssignments(),
      _loadSubmissions(),
      _loadAttendance(),
    ]);
    setState(() {});
  }

  Future<void> _loadStudents() async {
    try {
      final response = await _api.get('students.php');
      if (response['success'] == true) {
        setState(
          () => _students = List<Map<String, dynamic>>.from(
            response['students'] ?? [],
          ),
        );
      } else {
        _students = [];
      }
    } catch (e) {
      _students = [];
    }
  }

  Future<void> _loadAnnouncements() async {
    try {
      final response = await _api.get('announcements.php');
      if (response['success'] == true) {
        setState(
          () => _announcements = List<Map<String, dynamic>>.from(
            response['announcements'] ?? [],
          ),
        );
      } else {
        _announcements = [];
      }
    } catch (e) {
      _announcements = [];
    }
  }

  Future<void> _loadMaterials() async {
    try {
      final response = await _api.get('materials.php');
      if (response['success'] == true) {
        setState(
          () => _materials = List<Map<String, dynamic>>.from(
            response['materials'] ?? [],
          ),
        );
      } else {
        _materials = [];
      }
    } catch (e) {
      _materials = [];
    }
  }

  Future<void> _loadAssignments() async {
    try {
      final response = await _api.get('assignments.php');
      if (response['success'] == true) {
        setState(
          () => _assignments = List<Map<String, dynamic>>.from(
            response['assignments'] ?? [],
          ),
        );
      } else {
        _assignments = [];
      }
    } catch (e) {
      _assignments = [];
    }
  }

  Future<void> _loadSubmissions() async {
    try {
      final response = await _api.get('submission.php');
      if (response['success'] == true) {
        setState(() {
          _submissions = List<Map<String, dynamic>>.from(
            response['submissions'] ?? [],
          );
        });
      } else {
        _submissions = [];
      }
    } catch (e) {
      print('Error loading submissions: $e');
      _submissions = [];
    }
  }

  Future<void> _loadAttendance() async {
    try {
      final response = await _api.get('attendance.php');
      if (response['success'] == true) {
        final records = List<Map<String, dynamic>>.from(
          response['attendance_records'] ?? [],
        );
        for (var record in records) {
          if (record['statuses'] is String) {
            record['statuses'] = jsonDecode(record['statuses']);
          }
          // Ensure it's a Map<String, String>
          if (record['statuses'] is Map) {
            record['statuses'] = Map<String, String>.from(record['statuses']);
          }
        }
        setState(() => _attendanceRecords = records);
      } else {
        _attendanceRecords = [];
      }
    } catch (e) {
      print('Error loading attendance: $e');
      _attendanceRecords = [];
    }
  }

  Future<void> _loadNotifications() async {
    try {
      final userId = _authService.currentUserId ?? 0;
      if (userId <= 0) return;

      final response = await _api.get('notifications.php?user_id=$userId');
      if (response['success'] == true) {
        setState(() {
          _notifications = List<Map<String, dynamic>>.from(
            response['notifications'] ?? [],
          );
        });
      } else {
        _notifications = [];
      }
    } catch (e) {
      print('Error loading notifications: $e');
      _notifications = [];
    }
  }

  // ========== QUIZZES ==========
  Future<void> _loadQuizzes() async {
    try {
      final response = await _api.get('quizzes.php');
      if (response['success'] == true) {
        final List<Map<String, dynamic>> quizzesList =
            List<Map<String, dynamic>>.from(response['quizzes'] ?? []);
        for (var quiz in quizzesList) {
          // If questions is a String (JSON), decode it to List
          if (quiz['questions'] is String) {
            try {
              quiz['questions'] = jsonDecode(quiz['questions']);
            } catch (e) {
              quiz['questions'] = [];
            }
          }
          // Ensure questions is a List
          if (quiz['questions'] is! List) {
            quiz['questions'] = [];
          }
        }
        setState(() => _quizzes = quizzesList);
      } else {
        _quizzes = [];
      }
    } catch (e) {
      print('Error loading quizzes: $e');
      _quizzes = [];
    }
  }

  Future<void> _saveQuizzes() async {
    try {
      for (var quiz in _quizzes) {
        final response = await _api.post('quizzes.php', {
          'action': 'save',
          'id': quiz['id'],
          'title': quiz['title'],
          'description': quiz['description'],
          'questions': jsonEncode(quiz['questions']),
          'teacher_id': _authService.currentUserId ?? 0,
        });
        if (response['success'] != true) {
          print('Error saving quiz ${quiz['id']}: ${response['message']}');
        }
      }
    } catch (e) {
      print('Error in _saveQuizzes: $e');
    }
  }

Future<void> _createQuiz() async {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  final List<String> subjects = [
    'Mathematics',
    'Science',
    'English',
    'Filipino',
    'AP',
    'ESP',
    'TLE',
    'MAPEH',
  ];

  String selectedSubject = 'Mathematics';

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: StatefulBuilder(
        builder: (context, setStateDialog) {
          return Container(
            width: 580,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── HEADER ──
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0d2b5c), Color(0xFF1a5276)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.quiz_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Create New Quiz',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Add a new quiz for your students',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          titleController.dispose();
                          descriptionController.dispose();
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── QUIZ DETAILS ──
                const Text(
                  'Quiz Details',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0d2b5c),
                  ),
                ),
                const SizedBox(height: 12),

                // Quiz Title
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Quiz Title',
                      hintText: 'e.g., Chapter 5 Quiz',
                      prefixIcon: Icon(
                        Icons.title,
                        color: Color(0xFF0d2b5c),
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      labelStyle: TextStyle(fontSize: 13),
                      hintStyle: TextStyle(fontSize: 14),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(height: 12),

                // Subject Dropdown (same style as assignment)
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButtonFormField<String>(
                      value: selectedSubject,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Subject',
                        prefixIcon: Icon(
                          Icons.school,
                          color: Color(0xFF0d2b5c),
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        labelStyle: TextStyle(fontSize: 13),
                      ),
                      items: subjects.map((subject) {
                        return DropdownMenuItem<String>(
                          value: subject,
                          child: Text(subject),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setStateDialog(() {
                            selectedSubject = value;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Description
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Enter quiz details...',
                      prefixIcon: Icon(
                        Icons.description,
                        color: Color(0xFF0d2b5c),
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      labelStyle: TextStyle(fontSize: 13),
                      hintStyle: TextStyle(fontSize: 14),
                    ),
                    style: const TextStyle(fontSize: 14),
                    maxLines: 2,
                  ),
                ),
                const SizedBox(height: 20),

                // ── CREATE BUTTON ──
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      if (titleController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a quiz title'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      // Create quiz logic here
                      final newQuiz = {
                        'id': DateTime.now().millisecondsSinceEpoch.toString(),
                        'title': titleController.text.trim(),
                        'subject': selectedSubject,
                        'description': descriptionController.text.trim(),
                        'questions': [],
                      };

                      // Add to local list
                      setState(() {
                        _quizzes.insert(0, newQuiz);
                      });

                      // Save to API
                      _api.post('quizzes.php', {
                        'action': 'create',
                        'title': newQuiz['title'],
                        'subject': newQuiz['subject'],
                        'description': newQuiz['description'],
                        'questions': jsonEncode(newQuiz['questions']),
                        'teacher_id': _authService.currentUserId ?? 0,
                      }).then((response) {
                        if (response['success'] == true) {
                          // Refresh quizzes
                          _loadQuizzes();
                        }
                      });

                      titleController.dispose();
                      descriptionController.dispose();
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Quiz created successfully!'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0d2b5c),
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add,
                          size: 18,
                          color: Colors.white,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Create Quiz',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

  Future<void> _editQuizQuestions(Map<String, dynamic> quiz) async {
    final List<Map<String, dynamic>> questions = List.from(
      quiz['questions'] ?? [],
    );
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text('Edit Quiz: ${quiz['title']}'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      await _addQuestionDialog(
                        quiz,
                        questions,
                        setStateDialog,
                        null,
                      );
                      // Reload quiz from storage to sync
                      final updatedQuiz = _quizzes.firstWhere(
                        (q) => q['id'] == quiz['id'],
                        orElse: () => quiz,
                      );
                      if (updatedQuiz != quiz) {
                        quiz = updatedQuiz;
                        questions.clear();
                        questions.addAll(
                          List.from(updatedQuiz['questions'] ?? []),
                        );
                      }
                      setStateDialog(() {});
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Question'),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: questions.length,
                      itemBuilder: (context, idx) {
                        final q = questions[idx];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(
                              '${idx + 1}. ${q['text']}',
                              maxLines: 2,
                            ),
                            subtitle: Text('Type: ${q['type']}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () => _editSingleQuestionDialog(
                                    quiz,
                                    questions,
                                    setStateDialog,
                                    idx,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    questions.removeAt(idx);
                                    setStateDialog(() {});
                                    _saveQuizQuestions(quiz, questions);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _saveQuizQuestions(quiz, questions);
                  Navigator.pop(context);
                },
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _saveQuizQuestions(
    Map<String, dynamic> quiz,
    List<Map<String, dynamic>> questions,
  ) {
    final index = _quizzes.indexWhere((q) => q['id'] == quiz['id']);
    if (index != -1) {
      setState(() => _quizzes[index]['questions'] = questions);
      _saveQuizzes();
    }
  }

  Future<void> _addQuestionDialog(
    Map<String, dynamic> quiz,
    List<Map<String, dynamic>> questions,
    StateSetter setStateDialog,
    int? editIndex,
  ) async {
    if (editIndex != null) {
      await _editSingleQuestionDialog(
        quiz,
        questions,
        setStateDialog,
        editIndex,
      );
      return;
    }

    String questionType = 'Multiple Choice';
    final questionTextController = TextEditingController();
    final correctAnswerController = TextEditingController();
    final identificationAnswerController = TextEditingController();
    final essayAnswerController = TextEditingController();
    List<TextEditingController> choiceControllers = [
      TextEditingController(),
      TextEditingController(),
      TextEditingController(),
      TextEditingController(),
    ];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateInner) {
          return AlertDialog(
            title: const Text('Add Question (Keep Adding)'),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: questionType,
                      items: const [
                        DropdownMenuItem(
                          value: 'Multiple Choice',
                          child: Text('Multiple Choice'),
                        ),
                        DropdownMenuItem(
                          value: 'Identification',
                          child: Text('Identification'),
                        ),
                        DropdownMenuItem(value: 'Essay', child: Text('Essay')),
                      ],
                      onChanged: (val) {
                        questionType = val!;
                        setStateInner(() {});
                      },
                      decoration: const InputDecoration(
                        labelText: 'Question Type',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: questionTextController,
                      decoration: const InputDecoration(
                        labelText: 'Question Text',
                      ),
                    ),
                    if (questionType == 'Multiple Choice') ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text(
                            'Choices',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(
                              Icons.add_circle,
                              color: Colors.blue,
                            ),
                            onPressed: () {
                              setStateInner(() {
                                choiceControllers.add(TextEditingController());
                              });
                            },
                            tooltip: 'Add choice',
                          ),
                        ],
                      ),
                      ...List.generate(choiceControllers.length, (i) {
                        final char = String.fromCharCode(65 + i);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: choiceControllers[i],
                                  decoration: InputDecoration(
                                    labelText: 'Choice $char',
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                tooltip: 'Delete choice',
                                onPressed: () {
                                  setStateInner(() {
                                    if (choiceControllers.length <= 2) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'At least 2 choices are recommended.',
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    choiceControllers[i].dispose();
                                    choiceControllers.removeAt(i);
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      TextField(
                        controller: correctAnswerController,
                        decoration: const InputDecoration(
                          labelText: 'Correct Answer (e.g., A, B, C, D)',
                        ),
                        onChanged: (val) =>
                            correctAnswerController.text = val.toUpperCase(),
                      ),
                    ],
                    if (questionType == 'Identification') ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: identificationAnswerController,
                        decoration: const InputDecoration(
                          labelText: 'Correct Answer',
                        ),
                      ),
                    ],
                    if (questionType == 'Essay') ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: essayAnswerController,
                        decoration: const InputDecoration(
                          labelText: 'Sample Answer / Rubric',
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  questionTextController.dispose();
                  correctAnswerController.dispose();
                  identificationAnswerController.dispose();
                  essayAnswerController.dispose();
                  for (var controller in choiceControllers) {
                    controller.dispose();
                  }
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (questionTextController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter question text'),
                      ),
                    );
                    return;
                  }
                  final Map<String, dynamic> newQuestion = {
                    'text': questionTextController.text,
                    'type': questionType,
                  };

                  if (questionType == 'Multiple Choice') {
                    newQuestion['choices'] = choiceControllers
                        .map((c) => c.text)
                        .toList();
                    newQuestion['correctAnswer'] = correctAnswerController.text
                        .toUpperCase();
                  } else if (questionType == 'Identification') {
                    newQuestion['answer'] = identificationAnswerController.text;
                  } else {
                    newQuestion['sampleAnswer'] = essayAnswerController.text;
                  }

                  questions.add(newQuestion);
                  _saveQuizQuestions(quiz, questions);
                  setStateDialog(() {});
                  questionTextController.clear();
                  correctAnswerController.clear();
                  identificationAnswerController.clear();
                  essayAnswerController.clear();
                  for (var controller in choiceControllers) {
                    controller.dispose();
                  }
                  choiceControllers = [
                    TextEditingController(),
                    TextEditingController(),
                    TextEditingController(),
                    TextEditingController(),
                  ];
                  setStateInner(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Question added!'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: const Text('Add Another'),
              ),
              ElevatedButton(
                onPressed: () {
                  questionTextController.dispose();
                  correctAnswerController.dispose();
                  identificationAnswerController.dispose();
                  essayAnswerController.dispose();
                  for (var controller in choiceControllers) {
                    controller.dispose();
                  }
                  _saveQuizQuestions(quiz, questions);
                  Navigator.pop(context);
                },
                child: const Text('Done'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _editSingleQuestionDialog(
    Map<String, dynamic> quiz,
    List<Map<String, dynamic>> questions,
    StateSetter setStateDialog,
    int editIndex,
  ) async {
    final q = questions[editIndex];
    String questionType = q['type'];
    String questionText = q['text'];
    List<String> choices = q['type'] == 'Multiple Choice'
        ? List.from(q['choices'])
        : ['', '', '', ''];
    String correctAnswer = q['type'] == 'Multiple Choice'
        ? q['correctAnswer']
        : '';
    String identificationAnswer = q['type'] == 'Identification'
        ? q['answer']
        : '';
    String essayAnswer = q['type'] == 'Essay' ? q['sampleAnswer'] : '';
    int choiceCount = choices.length;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateInner) {
          return AlertDialog(
            title: const Text('Edit Question'),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: questionType,
                      items: const [
                        DropdownMenuItem(
                          value: 'Multiple Choice',
                          child: Text('Multiple Choice'),
                        ),
                        DropdownMenuItem(
                          value: 'Identification',
                          child: Text('Identification'),
                        ),
                        DropdownMenuItem(value: 'Essay', child: Text('Essay')),
                      ],
                      onChanged: (val) {
                        questionType = val!;
                        setStateInner(() {});
                      },
                      decoration: const InputDecoration(
                        labelText: 'Question Type',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Question Text',
                      ),
                      controller: TextEditingController(text: questionText),
                      onChanged: (val) => questionText = val,
                    ),
                    if (questionType == 'Multiple Choice') ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text(
                            'Choices',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(
                              Icons.add_circle,
                              color: Colors.blue,
                            ),
                            onPressed: () {
                              setStateInner(() {
                                choices.add('');
                                choiceCount++;
                              });
                            },
                          ),
                        ],
                      ),
                      ...List.generate(
                        choiceCount,
                        (i) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: TextField(
                            decoration: InputDecoration(
                              labelText:
                                  'Choice ${String.fromCharCode(65 + i)}',
                            ),
                            controller: TextEditingController(text: choices[i]),
                            onChanged: (val) => choices[i] = val,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Correct Answer (e.g., A, B, C, D)',
                        ),
                        controller: TextEditingController(text: correctAnswer),
                        onChanged: (val) => correctAnswer = val.toUpperCase(),
                      ),
                    ],
                    if (questionType == 'Identification') ...[
                      const SizedBox(height: 12),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Correct Answer',
                        ),
                        controller: TextEditingController(
                          text: identificationAnswer,
                        ),
                        onChanged: (val) => identificationAnswer = val,
                      ),
                    ],
                    if (questionType == 'Essay') ...[
                      const SizedBox(height: 12),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Sample Answer / Rubric',
                        ),
                        maxLines: 3,
                        controller: TextEditingController(text: essayAnswer),
                        onChanged: (val) => essayAnswer = val,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (questionText.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter question text'),
                      ),
                    );
                    return;
                  }
                  Map<String, dynamic> updatedQuestion = {
                    'text': questionText,
                    'type': questionType,
                  };
                  if (questionType == 'Multiple Choice') {
                    updatedQuestion['choices'] = choices;
                    updatedQuestion['correctAnswer'] = correctAnswer;
                  } else if (questionType == 'Identification') {
                    updatedQuestion['answer'] = identificationAnswer;
                  } else {
                    updatedQuestion['sampleAnswer'] = essayAnswer;
                  }
                  questions[editIndex] = updatedQuestion;
                  setStateDialog(() {});
                  _saveQuizQuestions(quiz, questions);
                  Navigator.pop(context);
                },
                child: const Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ========== QUIZ SCORING & SHARING ==========

  /// Auto score multiple choice questions
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
        if (correctAnswer == studentAnswer) {
          score++;
        }
      }
    }
    return score;
  }

  /// Auto score identification questions
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
        if (correctAnswer == studentAnswer) {
          score++;
        }
      }
    }
    return score;
  }

  /// Manual scoring for essay questions - shows dialog to enter scores
  Future<void> manualScoreEssay(
    Map<String, dynamic> quiz,
    Map<String, dynamic> studentAnswers,
  ) async {
    final essayQuestions =
        quiz['questions'].where((q) => q['type'] == 'Essay').toList()
            as List<Map<String, dynamic>>;

    if (essayQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No essay questions in this quiz')),
      );
      return;
    }

    Map<String, int> essayScores = {};

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Score Essay Questions'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...List.generate(essayQuestions.length, (idx) {
                    final q = essayQuestions[idx];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${idx + 1}. ${q['text']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Student Answer: ${studentAnswers[q['text']] ?? 'No answer'}',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sample: ${q['sampleAnswer'] ?? 'N/A'}',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Score (0-10)',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (val) {
                              essayScores[q['text']] = int.tryParse(val) ?? 0;
                            },
                          ),
                          const Divider(),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Essay scores recorded: ${essayScores.values.reduce((a, b) => a + b)}/100',
                    ),
                  ),
                );
              },
              child: const Text('Save Scores'),
            ),
          ],
        ),
      ),
    );
  }

  /// Generate shareable quiz link
  void generateShareableQuizLink(Map<String, dynamic> quiz) {
    final quizId = quiz['id'];
    final quizTitle = quiz['title'];
    final quizLink = 'https://adet.app/quiz/$quizId';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Quiz'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quiz: $quizTitle'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      quizLink,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.content_copy, size: 20),
                    onPressed: () {
                      // In a real app, this would copy to clipboard
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Link copied to clipboard!'),
                        ),
                      );
                      Navigator.pop(context);
                    },
                    tooltip: 'Copy link',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Share this link with your students to take the quiz',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAttendanceRecords() async {
    try {
      for (var record in _attendanceRecords) {
        final response = await _api.post('attendance.php', {
          'action': 'save',
          'date': record['date'],
          'display_date': record['displayDate'],
          'statuses': jsonEncode(record['statuses']),
          'teacher_id': _authService.currentUserId ?? 0,
        });
        if (response['success'] != true) {
          print(
            'Error saving attendance for ${record['date']}: ${response['message']}',
          );
        }
      }
    } catch (e) {
      print('Error in _saveAttendanceRecords: $e');
    }
  }

  Future<void> _createAttendanceRecord() async {
    final DateTime today = DateTime.now();
    final String todayKey =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: today,
      lastDate: today,
      selectableDayPredicate: (DateTime date) {
        return date.year == today.year &&
            date.month == today.month &&
            date.day == today.day;
      },
    );
    if (picked == null) return;

    final dateKey =
        "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";

    if (_attendanceRecords.any((r) => r['date'] == dateKey)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have already marked attendance for today.'),
          backgroundColor: Colors.black87,
        ),
      );
      _markAttendanceForDate(dateKey);
      return;
    }

    if (_students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No students available to mark attendance.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Map<String, String> statuses = {};
    for (var student in _students) {
      statuses[student['id'].toString()] = 'Present';
    }

    final newRecord = {
      'date': dateKey,
      'displayDate': "${picked.toLocal()}".split(' ')[0],
      'statuses': statuses,
    };

    try {
      final response = await _api.post('attendance.php', {
        'action': 'create',
        'date': dateKey,
        'display_date': "${picked.toLocal()}".split(' ')[0],
        'statuses': jsonEncode(statuses),
        'teacher_id': _authService.currentUserId ?? 0,
      });

      if (response['success'] == true) {
        setState(() {
          _attendanceRecords.add(newRecord);
        });
        _markAttendanceForDate(dateKey);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${response['message']}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating attendance: $e')),
        );
      }
    }
  }

  void _markAttendanceForDate(String dateKey) {
    final now = DateTime.now();
    final todayKey =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    if (dateKey != todayKey) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only edit today\'s attendance.'),
          backgroundColor: Colors.black87,
        ),
      );
      return;
    }

    final recordIndex = _attendanceRecords.indexWhere(
      (r) => r['date'] == dateKey,
    );
    if (recordIndex == -1) return;

    Map<String, String> currentStatuses = Map.from(
      _attendanceRecords[recordIndex]['statuses'],
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.9,
                maxChildSize: 0.9,
                minChildSize: 0.5,
                builder: (context, scrollController) {
                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Attendance for $dateKey',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1a2b4a),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: _students.length,
                          itemBuilder: (ctx, index) {
                            final student = _students[index];
                            final studentId = student['id'].toString();
                            String status =
                                currentStatuses[studentId] ?? 'Present';
                            return Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: const Color(
                                      0xFF0d2b5c,
                                    ).withOpacity(0.1),
                                    child: Text(
                                      student['name'][0],
                                      style: const TextStyle(
                                        color: Color(0xFF0d2b5c),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          student['name'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1a2b4a),
                                          ),
                                        ),
                                        Text(
                                          student['email'] ?? '',
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SegmentedButton<String>(
                                    segments: const [
                                      ButtonSegment(
                                        value: 'Present',
                                        label: Text('Present'),
                                        icon: Icon(
                                          Icons.check_circle,
                                          size: 16,
                                        ),
                                      ),
                                      ButtonSegment(
                                        value: 'Late',
                                        label: Text('Late'),
                                        icon: Icon(Icons.access_time, size: 16),
                                      ),
                                      ButtonSegment(
                                        value: 'Absent',
                                        label: Text('Absent'),
                                        icon: Icon(Icons.cancel, size: 16),
                                      ),
                                    ],
                                    selected: {status},
                                    onSelectionChanged:
                                        (Set<String> newSelection) {
                                          final newStatus = newSelection.first;
                                          setSheetState(
                                            () => currentStatuses[studentId] =
                                                newStatus,
                                          );
                                        },
                                    style: ButtonStyle(
                                      backgroundColor:
                                          WidgetStateProperty.resolveWith((
                                            states,
                                          ) {
                                            if (states.contains(
                                              WidgetState.selected,
                                            )) {
                                              if (status == 'Present') {
                                                return Colors.green.shade50;
                                              }
                                              if (status == 'Late') {
                                                return Colors.orange.shade50;
                                              }
                                              if (status == 'Absent') {
                                                return Colors.red.shade50;
                                              }
                                            }
                                            return Colors.grey.shade50;
                                          }),
                                      foregroundColor:
                                          WidgetStateProperty.resolveWith((
                                            states,
                                          ) {
                                            if (states.contains(
                                              WidgetState.selected,
                                            )) {
                                              if (status == 'Present') {
                                                return Colors.green;
                                              }
                                              if (status == 'Late') {
                                                return Colors.orange;
                                              }
                                              if (status == 'Absent') {
                                                return Colors.red;
                                              }
                                            }
                                            return Colors.grey.shade700;
                                          }),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  setState(
                                    () =>
                                        _attendanceRecords[recordIndex]['statuses'] =
                                            currentStatuses,
                                  );
                                  await _saveAttendanceRecords();
                                  if (mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Attendance saved!'),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0d2b5c),
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Save Attendance'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  void _viewAttendanceHistory() {
    final now = DateTime.now();
    final todayKey =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.9,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Attendance History',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _attendanceRecords.isEmpty
                      ? const Center(child: Text('No attendance records yet.'))
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: _attendanceRecords.length,
                          itemBuilder: (context, index) {
                            final record = _attendanceRecords[index];
                            final date =
                                record['displayDate'] ?? record['date'];
                            final statuses = Map<String, String>.from(
                              record['statuses'],
                            );
                            int present = statuses.values
                                .where((s) => s == 'Present')
                                .length;
                            int late = statuses.values
                                .where((s) => s == 'Late')
                                .length;
                            int absent = statuses.values
                                .where((s) => s == 'Absent')
                                .length;
                            bool isToday = record['date'] == todayKey;
                            return Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        date,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (isToday)
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.blue,
                                          ),
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _markAttendanceForDate(
                                              record['date'],
                                            );
                                          },
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 16,
                                    children: [
                                      Chip(
                                        avatar: const Icon(
                                          Icons.check_circle,
                                          size: 16,
                                          color: Colors.green,
                                        ),
                                        label: Text('Present: $present'),
                                        backgroundColor: Colors.green.shade50,
                                      ),
                                      Chip(
                                        avatar: const Icon(
                                          Icons.access_time,
                                          size: 16,
                                          color: Colors.orange,
                                        ),
                                        label: Text('Late: $late'),
                                        backgroundColor: Colors.orange.shade50,
                                      ),
                                      Chip(
                                        avatar: const Icon(
                                          Icons.cancel,
                                          size: 16,
                                          color: Colors.red,
                                        ),
                                        label: Text('Absent: $absent'),
                                        backgroundColor: Colors.red.shade50,
                                      ),
                                    ],
                                  ),
                                  if (isToday)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: TextButton.icon(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _markAttendanceForDate(
                                            record['date'],
                                          );
                                        },
                                        icon: const Icon(Icons.edit_note),
                                        label: const Text('Edit details'),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _generateAttendanceSummary() {
    if (_attendanceRecords.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Data'),
          content: const Text('No attendance records found.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    int totalPresent = 0, totalLate = 0, totalAbsent = 0;
    int totalDays = _attendanceRecords.length;
    Map<String, Map<String, dynamic>> studentSummary = {};
    for (var student in _students) {
      studentSummary[student['id'].toString()] = {
        'name': student['name'],
        'present': 0,
        'late': 0,
        'absent': 0,
      };
    }
    for (var record in _attendanceRecords) {
      Map<String, String> statuses = Map.from(record['statuses']);
      for (var entry in statuses.entries) {
        String studentId = entry.key;
        String status = entry.value;
        var summary = studentSummary[studentId];
        if (summary != null) {
          if (status == 'Present') {
            summary['present'] = (summary['present'] ?? 0) + 1;
            totalPresent++;
          } else if (status == 'Late') {
            summary['late'] = (summary['late'] ?? 0) + 1;
            totalLate++;
          } else if (status == 'Absent') {
            summary['absent'] = (summary['absent'] ?? 0) + 1;
            totalAbsent++;
          }
        }
      }
    }
    int totalEvents = totalPresent + totalLate + totalAbsent;
    double overallPresentPercent = totalEvents > 0
        ? (totalPresent / totalEvents) * 100
        : 0;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.9,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Attendance Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Text(
                                'Overall Statistics',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _summaryStat(
                                      'Total Days',
                                      totalDays.toString(),
                                      Colors.blue,
                                    ),
                                  ),
                                  Expanded(
                                    child: _summaryStat(
                                      'Total Present',
                                      totalPresent.toString(),
                                      Colors.green,
                                    ),
                                  ),
                                  Expanded(
                                    child: _summaryStat(
                                      'Total Late',
                                      totalLate.toString(),
                                      Colors.orange,
                                    ),
                                  ),
                                  Expanded(
                                    child: _summaryStat(
                                      'Total Absent',
                                      totalAbsent.toString(),
                                      Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              LinearProgressIndicator(
                                value: totalEvents > 0
                                    ? totalPresent / totalEvents
                                    : 0,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.green,
                                ),
                                minHeight: 8,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Present: ${overallPresentPercent.toStringAsFixed(1)}%',
                                    style: const TextStyle(color: Colors.green),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Text(
                                'Student-wise Summary',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columnSpacing: 16,
                                  columns: const [
                                    DataColumn(label: Text('Student')),
                                    DataColumn(label: Text('Present')),
                                    DataColumn(label: Text('Late')),
                                    DataColumn(label: Text('Absent')),
                                    DataColumn(label: Text('Rate')),
                                  ],
                                  rows: studentSummary.values.map((data) {
                                    int present = data['present'],
                                        late = data['late'],
                                        absent = data['absent'],
                                        total = present + late + absent;
                                    double rate = total > 0
                                        ? (present / total) * 100
                                        : 0;
                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Text(
                                            data['name'],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            present.toString(),
                                            style: const TextStyle(
                                              color: Colors.green,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            late.toString(),
                                            style: const TextStyle(
                                              color: Colors.orange,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            absent.toString(),
                                            style: const TextStyle(
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            '${rate.toStringAsFixed(1)}%',
                                            style: TextStyle(
                                              color: rate >= 85
                                                  ? Colors.green
                                                  : rate >= 75
                                                  ? Colors.orange
                                                  : Colors.red,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _summaryStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ],
    );
  }

  // ========== FILE REGISTRY ==========
  final Map<String, Map<String, dynamic>> _fileRegistry = {};
  int _fileCounter = 0;

  String _generateFileId() {
    _fileCounter++;
    return 'f$_fileCounter';
  }

  // Register file with metadata
  void _registerFile({
    required String fileUrl,
    required String fileName,
    String? fileType,
  }) {
    final id = _generateFileId();
    _fileRegistry[id] = {
      'url': fileUrl,
      'name': fileName,
      'type': fileType ?? 'application/octet-stream',
    };
  }

  Future<void> _viewFilePreview(String fileUrl, String fileName) async {
    if (fileUrl.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No file to preview.')));
      }
      return;
    }
    
    String fixedUrl = fileUrl;
    
    if (fileUrl.startsWith('uploads/') || fileUrl.startsWith('/uploads/')) {
      fixedUrl = 'http://127.0.0.1/ADET/backend/$fileUrl';
    } else if (fileUrl.contains('localhost')) {
      fixedUrl = fileUrl.replaceFirst('http://localhost', 'http://127.0.0.1');
    } else if (!fileUrl.startsWith('http')) {
      if (fileUrl.startsWith('/ADET/backend/')) {
        fixedUrl = 'http://127.0.0.1$fileUrl';
      } else if (fileUrl.startsWith('/ADET/')) {
        fixedUrl = 'http://127.0.0.1$fileUrl';
      } else if (fileUrl.startsWith('/')) {
        fixedUrl = 'http://127.0.0.1$fileUrl';
      } else {
        fixedUrl = 'http://127.0.0.1/ADET/backend/$fileUrl';
      }
    }
    
    final ext = fixedUrl.split('.').last.split('?').first.toUpperCase();
    
    FileViewerDialog.show(
      context,
      fileUrl: fixedUrl,
      fileName: fileName,
      fileType: ext,
    );
  }

  // Download file to device
Future<void> _downloadFileToDevice(String fileUrl, String fileName) async {
  if (fileUrl.isEmpty) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No file to download.')),
      );
    }
    return;
  }

  if (kIsWeb) {
    String fixedUrl = fileUrl;
    if (fixedUrl.contains('localhost')) {
      fixedUrl = fixedUrl.replaceFirst('http://localhost', 'http://127.0.0.1');
    }
    if (!fixedUrl.startsWith('http')) {
      fixedUrl = 'http://127.0.0.1$fixedUrl';
    }

    final uri = Uri.parse(fixedUrl);
    final pathOnly = uri.path;
    final safeTitle = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '').trim();

    final encodedPath = Uri.encodeComponent(pathOnly);
    final encodedTitle = Uri.encodeComponent(safeTitle);

    final downloadUrl =
        'http://127.0.0.1/ADET/backend/php/materials.php'
        '?download=1'
        '&file_url=$encodedPath'
        '&title=$encodedTitle';

    html.window.location.href = downloadUrl;
    return;
  }
}

  // ========== FILE VIEW & DOWNLOAD ==========
  Future<void> _viewMaterial(String fileUrl, String title) async {
    if (fileUrl.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No file associated.')));
      }
      return;
    }

    String fixedUrl = fileUrl;
    if (fileUrl.startsWith('uploads/') || fileUrl.startsWith('/uploads/')) {
      fixedUrl = 'http://127.0.0.1/ADET/backend/$fileUrl';
    } else if (fileUrl.contains('localhost')) {
      fixedUrl = fileUrl.replaceFirst('http://localhost', 'http://127.0.0.1');
    } else if (!fileUrl.startsWith('http')) {
      if (fileUrl.startsWith('/ADET/backend/')) {
        fixedUrl = 'http://127.0.0.1$fileUrl';
      } else if (fileUrl.startsWith('/ADET/')) {
        fixedUrl = 'http://127.0.0.1$fileUrl';
      } else if (fileUrl.startsWith('/')) {
        fixedUrl = 'http://127.0.0.1$fileUrl';
      } else {
        fixedUrl = 'http://127.0.0.1/ADET/backend/$fileUrl';
      }
    }

    if (kIsWeb) {
      html.window.open(fixedUrl, '_blank');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening $title in new tab...'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final ext = fixedUrl.split('.').last.split('?').first.toUpperCase();
    FileViewerDialog.show(
      context,
      fileUrl: fixedUrl,
      fileName: title,
      fileType: ext,
    );
  }

  Future<void> _downloadMaterialToDevice(
    String sourceUrl,
    String fileName,
  ) async {
    if (sourceUrl.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No file to download.')));
      }
      return;
    }

    if (kIsWeb) {
      try {
        String fixedUrl = sourceUrl;
        if (fixedUrl.contains('localhost')) {
          fixedUrl = fixedUrl.replaceFirst('http://localhost', 'http://127.0.0.1');
        }
        if (!fixedUrl.startsWith('http')) {
          fixedUrl = 'http://127.0.0.1/ADET/backend/$fixedUrl';
        }

        final anchor = html.AnchorElement()
          ..href = fixedUrl
          ..download = fileName
          ..style.display = 'none';
        html.document.body?.append(anchor);
        anchor.click();
        anchor.remove();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Downloading: $fileName'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Download failed: $e')),
          );
        }
      }
      return;
    }
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Downloading file...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      String fixedUrl = sourceUrl;
      if (fixedUrl.contains('localhost')) {
        fixedUrl = fixedUrl.replaceFirst('http://localhost', 'http://127.0.0.1');
      }
      if (!fixedUrl.startsWith('http')) {
        fixedUrl = 'http://127.0.0.1/ADET/backend/$fixedUrl';
      }

      final response = await http
          .get(Uri.parse(fixedUrl))
          .timeout(const Duration(seconds: 60));

      if (response.statusCode != 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to download file')),
          );
        }
        return;
      }

      final cleanFileName = fileName
          .replaceAll(' ', '_')
          .replaceAll(RegExp(r'[^\w.-]'), '');
      final fileExtension = sourceUrl.split('.').last.split('?').first;
      final finalFileName = '$cleanFileName.$fileExtension';

      if (io.Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Storage permission required.')),
            );
          }
          return;
        }
      }

      final destDir =
          await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();

      final destFile = io.File('${destDir.path}/$finalFileName');
      await destFile.writeAsBytes(response.bodyBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloaded: ${destFile.path}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
      }
    }
  }

  void _downloadFileWeb(Uint8List bytes, String fileName) {
    try {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);

      final anchor = html.AnchorElement()
        ..href = url
        ..download = fileName
        ..style.display = 'none';

      html.document.body?.append(anchor);
      anchor.click();

      html.Url.revokeObjectUrl(url);
      anchor.remove();
    } catch (e) {
      print('Web download error: $e');
    }
  }

  void _downloadMaterial(String id, String title) {
    final material = _materials.firstWhere((m) => m['id'].toString() == id);
    final filePath = material['file_url'] ?? '';
    final fileName = material['title'] ?? 'document';
    _downloadMaterialToDevice(filePath, fileName);
  }

  void _showEditMaterialDialog(
    String id,
    String title,
    String subject,
    String format,
  ) {
    final titleController = TextEditingController(text: title);
    final subjectController = TextEditingController(text: subject);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Learning Material'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: subjectController,
              decoration: const InputDecoration(labelText: 'Subject'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.trim().isEmpty ||
                  subjectController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill in all fields')),
                );
                return;
              }

              try {
                final response = await _api.post('materials.php', {
                  'action': 'edit',
                  'id': id,
                  'title': titleController.text.trim(),
                  'subject': subjectController.text.trim(),
                  'type': format,
                });

                if (!mounted) return;
                Navigator.pop(context);

                if (response['success'] == true) {
                  await _loadMaterials();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Material updated successfully!'),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(response['message'] ?? 'Update failed'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _deleteMaterial(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Learning Material'),
        content: const Text(
          'Are you sure you want to delete this material? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final response = await _api.post('materials.php', {
                  'action': 'delete',
                  'id': id,
                });

                if (!mounted) return;
                Navigator.pop(context);

                if (response['success'] == true) {
                  await _loadMaterials();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Material deleted successfully!'),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(response['message'] ?? 'Delete failed'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ========== ANNOUNCEMENTS API ==========
  Future<void> _createAnnouncement(
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
        await _loadAnnouncements();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Announcement posted!')));
        }
      } else {
        throw Exception(response['message'] ?? 'Failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deleteAnnouncementById(int id) async {
    try {
      final response = await _api.post('announcements.php', {
        'action': 'delete',
        'id': id,
      });
      if (response['success'] == true) {
        await _loadAnnouncements();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Announcement deleted!')),
          );
        }
      } else {
        throw Exception(response['message'] ?? 'Failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showAddAnnouncementDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String selectedColor = 'blue';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New Announcement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(labelText: 'Content'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedColor,
                decoration: const InputDecoration(labelText: 'Color Category'),
                items: const [
                  DropdownMenuItem(
                    value: 'blue',
                    child: Text('Blue - General'),
                  ),
                  DropdownMenuItem(
                    value: 'green',
                    child: Text('Green - Success'),
                  ),
                  DropdownMenuItem(
                    value: 'orange',
                    child: Text('Orange - Important'),
                  ),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    selectedColor = value ?? 'blue';
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty &&
                    contentController.text.isNotEmpty) {
                  Navigator.pop(context);
                  await _createAnnouncement(
                    titleController.text,
                    contentController.text,
                    selectedColor,
                  );
                }
              },
              child: const Text('Post'),
            ),
          ],
        ),
      ),
    );
  }

  // ========== MATERIALS API ==========
  Future<void> _addUploadedMaterial(UploadedMaterial uploadedMaterial) async {
    final fileExtension = uploadedMaterial.fileName
        .split('.')
        .last
        .toUpperCase();
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
    setState(() {
      _materials.insert(0, newMaterial);
    });

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
        print('API save failed: ${response['message']}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Database save failed: ${response['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${uploadedMaterial.title} added to Lesson Plans!'),
            ),
          );
        }
      }
    } catch (e) {
      print('API error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ========== ASSIGNMENTS API ==========
  Future<void> _createAssignment(
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
        await _loadAssignments();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Assignment created!')));
        }
      } else {
        throw Exception(response['message'] ?? 'Creation failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deleteAssignmentById(int id) async {
    try {
      final response = await _api.post('assignments.php', {
        'action': 'delete',
        'id': id,
      });
      if (response['success'] == true) {
        await _loadAssignments();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Assignment deleted!')));
        }
      } else {
        throw Exception(response['message'] ?? 'Delete failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showCreateAssignmentDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime? selectedDateTime;

    final List<String> subjects = [
      'Mathematics',
      'Science',
      'English',
      'Filipino',
      'AP',
      'ESP',
      'TLE',
      'MAPEH',
    ];
    String selectedSubject = 'Mathematics';

    Future<void> selectDateTime() async {
      final pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime(2030),
      );
      if (pickedDate != null) {
        final pickedTime = await showTimePicker(
          context: context,
          initialTime: const TimeOfDay(hour: 23, minute: 59),
        );
        if (pickedTime != null) {
          selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        }
      }
    }
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Create New Assignment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Assignment Title',
                    hintText: 'e.g., Chapter 5 Exercises',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedSubject,
                  decoration: const InputDecoration(labelText: 'Subject'),
                  items: subjects
                      .map(
                        (subject) => DropdownMenuItem(
                          value: subject,
                          child: Text(subject),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setStateDialog(() {
                      selectedSubject = value!;
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter assignment details...',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: const Text('Deadline'),
                  subtitle: Text(
                    selectedDateTime == null
                        ? 'Not set'
                        : selectedDateTime!.toLocal().toString(),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    await selectDateTime();
                    setStateDialog(() {});
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty &&
                    selectedDateTime != null) {
                  Navigator.pop(context);
                  await _createAssignment(
                    titleController.text,
                    descriptionController.text,
                    selectedDateTime!.toIso8601String(),
                    selectedSubject,
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in title and deadline'),
                    ),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  // ========== LOGOUT ==========
  Future<void> _logout() async {
    try {
      await _authService.logout();
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
      }
    }
  }

  int _getPendingSubmissionsCount() {
    return _submissions.where((s) => s['status'] == 'Pending').length;
  }

  String _getDisplayDate(Map<String, dynamic> material) {
    if (material['created_at_formatted'] != null) {
      return material['created_at_formatted'];
    }
    String rawDate =
        material['created_at']?.toString() ??
        material['date']?.toString() ??
        '';
    if (rawDate.isEmpty) return 'No date';
    if (rawDate.contains(' ')) return rawDate.split(' ')[0];
    if (rawDate.contains('T')) return rawDate.split('T')[0];
    return rawDate;
  }

  int _getUnreadNotificationCount() {
    return _notifications
        .where((n) => n['read_status'] == 0 || n['read_status'] == false)
        .length;
  }

  Future<void> _createNotification({
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

      // Reload notifications
      await _loadNotifications();
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  Future<void> _markNotificationAsRead(int notificationId) async {
    try {
      await _api.post('notifications.php', {
        'action': 'mark_read',
        'notification_id': notificationId,
      });

      // Update local list
      final index = _notifications.indexWhere((n) => n['id'] == notificationId);
      if (index != -1) {
        setState(() {
          _notifications[index]['read_status'] = 1;
        });
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> _deleteNotification(int notificationId) async {
    try {
      await _api.post('notifications.php', {
        'action': 'delete',
        'notification_id': notificationId,
      });

      // Remove from local list
      setState(() {
        _notifications.removeWhere((n) => n['id'] == notificationId);
      });
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    _isMobile = MediaQuery.of(context).size.width < 900;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _isMobile ? _buildMobileAppBar() : null,
      drawer: _isMobile ? _buildDrawer() : null,
      body: Row(
        children: [
          if (!_isMobile) _buildSidebar(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildMobileAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0d2b5c),
      foregroundColor: Colors.white,
      elevation: 0,
      title: Row(
        children: [
          Image.asset('assets/capstonelogo.png', width: 32, height: 32),
          const SizedBox(width: 12),
          const Text(
            'Teacher Portal',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
          ),
        ],
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications, size: 24),
              onPressed: _showNotificationsPanel,
            ),
            if (_getUnreadNotificationCount() > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _getUnreadNotificationCount().toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.account_circle, size: 28),
          onSelected: (value) {
            if (value == 'change_password') {
              Navigator.pushNamed(context, '/change-password');
            } else if (value == 'logout') {
              _logout();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'profile',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _authService.currentUserName ?? 'Teacher',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    _authService.currentUserEmail ?? '',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'change_password',
              child: Row(
                children: [
                  Icon(Icons.lock_outline, size: 18),
                  SizedBox(width: 8),
                  Text('Change Password'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Logout', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF0d2b5c)),
            child: Row(
              children: [
                Image.asset('assets/capstonelogo.png', width: 40, height: 40),
                const SizedBox(width: 12),
                const Text(
                  'Teacher Portal',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          _drawerItem(Icons.dashboard_outlined, 'Overview', 0),
          _drawerItem(Icons.people_outline, 'Students', 1),
          _drawerItem(Icons.upload_file_outlined, 'Lesson Plans', 2),
          _drawerItem(Icons.assignment_outlined, 'Assignments', 3),
          _drawerItem(Icons.calendar_today_outlined, 'Attendance', 4),
          _drawerItem(Icons.announcement_outlined, 'Announcements', 5),
          _drawerItem(Icons.quiz_outlined, 'Quizzes', 6),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? const Color(0xFF0d2b5c) : Colors.grey.shade600,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? const Color(0xFF0d2b5c) : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      tileColor: isSelected ? const Color(0xFF0d2b5c).withOpacity(0.08) : null,
      onTap: () {
        setState(() => _selectedIndex = index);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 260,
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/capstonelogo.png',
                      width: 40,
                      height: 40,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Teacher Portal',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Color(0xFF1a2b4a),
                      ),
                    ),
                  ],
                ),
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none, size: 20),
                      onPressed: _showNotificationsPanel,
                      padding: EdgeInsets.zero,
                    ),
                    if (_getUnreadNotificationCount() > 0)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getUnreadNotificationCount().toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _sidebarItem(Icons.dashboard_outlined, 'Overview', 0),
          _sidebarItem(Icons.people_outline, 'Students', 1),
          _sidebarItem(Icons.upload_file_outlined, 'Lesson Plans', 2),
          _sidebarItem(Icons.assignment_outlined, 'Assignments', 3),
          _sidebarItem(Icons.calendar_today_outlined, 'Attendance', 4),
          _sidebarItem(Icons.announcement_outlined, 'Announcements', 5),
          _sidebarItem(Icons.quiz_outlined, 'Quizzes', 6),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
            onTap: _logout,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _sidebarItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? const Color(0xFF0d2b5c) : Colors.grey.shade600,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? const Color(0xFF0d2b5c) : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      tileColor: isSelected ? const Color(0xFF0d2b5c).withOpacity(0.08) : null,
      onTap: () => setState(() => _selectedIndex = index),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildOverview();
      case 1:
        return _buildStudentList();
      case 2:
        return _buildLessonPlans();
      case 3:
        return _buildAssignments();
      case 4:
        return _buildAttendance();
      case 5:
        return _buildAnnouncements();
      case 6:
        return _buildQuizzes();
      default:
        return _buildOverview();
    }
  }

  // ==================== OVERVIEW ====================
  Widget _buildOverview() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(_isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0d2b5c), Color(0xFF1a5276)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, ${_authService.currentUserName ?? 'Teacher'}!',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Manage your classes and track student progress.',
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.person, color: Colors.white, size: 30),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth < 600 ? 2 : 4;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  _statCard('Total Students', '${_students.length}', 'Enrolled', Colors.blue, Icons.people),
                  _statCard('Assignments', '${_assignments.length}', 'Created', Colors.green, Icons.assignment),
                  _statCard('Pending Review', '${_getPendingSubmissionsCount()}', 'Submissions', Colors.orange, Icons.assignment_turned_in),
                  _statCard('Lesson Plans', '${_materials.length}', 'Uploaded', const Color(0xFF0d2b5c), Icons.book),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          if (_isMobile)
            Column(
              children: [
                _buildClassOverview(),
                const SizedBox(height: 12),
                _buildRecentActivity(),
                const SizedBox(height: 12),
                _buildAttendanceSummary(),
                const SizedBox(height: 12),
                _buildAnnouncementsPreview(),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      _buildClassOverview(),
                      const SizedBox(height: 12),
                      _buildAttendanceSummary(),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // RIGHT COLUMN
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      _buildRecentActivity(),
                      const SizedBox(height: 12),
                      _buildAnnouncementsPreview(),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ==================== STAT CARD ====================
  Widget _statCard(String title, String value, String subtitle, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Text(subtitle, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1a2b4a))),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        ],
      ),
    );
  }

  // ==================== CLASS OVERVIEW ====================
  Widget _buildClassOverview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Class Overview',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1a2b4a)),
          ),
          const SizedBox(height: 16),
          _classStatWithProgress('Attendance Rate', '92%', Colors.green, 0.92),
          const SizedBox(height: 12),
          _classStatWithProgress('Assignment Completion', '78%', Colors.orange, 0.78),
        ],
      ),
    );
  }

  Widget _classStatWithProgress(String label, String value, Color color, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF1a2b4a))),
            Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          borderRadius: BorderRadius.circular(4),
          minHeight: 6,
        ),
      ],
    );
  }

  // ==================== RECENT ACTIVITY ====================
  Widget _buildRecentActivity() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activity',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1a2b4a)),
          ),
          const SizedBox(height: 12),
          _activityItem('Pending Submissions', '${_getPendingSubmissionsCount()} to review', 'Now', Colors.orange),
          const Divider(),
          _activityItem('Uploaded Lesson Plan', _materials.isNotEmpty ? _materials.first['title'] : 'Sample', 'Recently', Colors.green),
          const Divider(),
          _activityItem('Created Assignment', _assignments.isNotEmpty ? _assignments.first['title'] : 'Sample', 'Recently', Colors.blue),
        ],
      ),
    );
  }

  Widget _activityItem(String action, String detail, String time, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(action, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1a2b4a))),
                Text(detail, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
          ),
          Text(time, style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
        ],
      ),
    );
  }

  // ==================== ATTENDANCE SUMMARY ====================
  Widget _buildAttendanceSummary() {
    final now = DateTime.now();
    final todayKey =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    Map<String, String> todayStatuses = {};
    final todayRecord = _attendanceRecords.firstWhere(
      (r) => r['date'] == todayKey,
      orElse: () => {},
    );
    if (todayRecord.isNotEmpty) {
      todayStatuses = Map<String, String>.from(todayRecord['statuses'] ?? {});
    }
    int present = todayStatuses.values.where((s) => s == 'Present').length;
    int late = todayStatuses.values.where((s) => s == 'Late').length;
    int absent = todayStatuses.values.where((s) => s == 'Absent').length;
    int total = present + late + absent;
    bool hasTodayAttendance = todayRecord.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Today's Attendance",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1a2b4a)),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _attendanceStat('$present', 'Present', Colors.green)),
              Expanded(child: _attendanceStat('$late', 'Late', Colors.orange)),
              Expanded(child: _attendanceStat('$absent', 'Absent', Colors.red)),
            ],
          ),
          const SizedBox(height: 10),
          if (total > 0)
            Text(
              '${((present / total) * 100).toStringAsFixed(1)}% attendance rate',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            )
          else
            Text(
              'No attendance marked yet',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (hasTodayAttendance) {
                  _markAttendanceForDate(todayKey);
                } else {
                  _createAttendanceRecord();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0d2b5c),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: Text(
                hasTodayAttendance ? 'Edit Today\'s Attendance' : 'Take Attendance',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _attendanceStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
      ],
    );
  }

  // ==================== ANNOUNCEMENTS PREVIEW ====================
  Widget _buildAnnouncementsPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Announcements',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1a2b4a)),
              ),
              TextButton(
                onPressed: () => setState(() => _selectedIndex = 5),
                child: const Text('Manage', style: TextStyle(color: Color(0xFF007bff), fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._announcements.take(3).map(
            (a) => _announcementPreviewItem(
              a['title'] ?? 'Untitled',
              a['created_at']?.toString().split(' ')[0] ?? '2026-06-14',
            ),
          ),
          if (_announcements.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'No announcements',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _announcementPreviewItem(String title, String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: Color(0xFF1a2b4a)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(date, style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
        ],
      ),
    );
  }


  // ==================== STUDENT LIST ====================
  Widget _buildStudentList() {
    String searchQuery = '';

    return StatefulBuilder(
      builder: (context, setState) {
        final filteredStudents = searchQuery.isEmpty
            ? _students
            : _students.where((student) {
                final name = (student['name'] ?? '').toLowerCase();
                final email = (student['email'] ?? '').toLowerCase();
                final query = searchQuery.toLowerCase();
                return name.contains(query) || email.contains(query);
              }).toList();

        return SingleChildScrollView(
          padding: EdgeInsets.all(_isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Student List',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1a2b4a),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.grey, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                          });
                        },
                        decoration: const InputDecoration(
                          hintText: 'Search students...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    if (searchQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                        onPressed: () {
                          setState(() {
                            searchQuery = '';
                          });
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${filteredStudents.length} student${filteredStudents.length != 1 ? 's' : ''} found',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: filteredStudents.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.search_off, size: 48, color: Colors.grey),
                              SizedBox(height: 12),
                              Text('No students found'),
                              Text(
                                'Try adjusting your search',
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          // Table Header
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF8F9FA),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'Student Name',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'Email',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Student Rows
                          ...filteredStudents.map((student) => _studentRow(student)),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _studentRow(Map<String, dynamic> student) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFF0d2b5c).withOpacity(0.1),
                  child: Text(
                    (student['name'] ?? '?')[0],
                    style: const TextStyle(
                      color: Color(0xFF0d2b5c),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  student['name'] ?? 'Unknown',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1a2b4a),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              student['email'] ?? '',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== ASSIGNMENTS ====================
  Widget _buildAssignments() {
    final pendingCount = _getPendingSubmissionsCount();
    return SingleChildScrollView(
      padding: EdgeInsets.all(_isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Assignments',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Create and manage assignments for students',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TeacherReviewPage(),
                        ),
                      ).then((_) => _loadSubmissions());
                    },
                    icon: const Icon(Icons.assignment_turned_in, size: 18),
                    label: pendingCount > 0
                        ? Text('Review ($pendingCount)')
                        : const Text('View Submissions'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0d2b5c),
                      side: const BorderSide(color: Color(0xFF0d2b5c)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _showCreateAssignmentDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Create Assignment'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0d2b5c),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_assignments.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text('No assignments created yet'),
              ),
            )
          else
            for (var a in _assignments) _assignmentCard(a),
        ],
      ),
    );
  }

  Widget _assignmentCard(Map<String, dynamic> assignment) {
    final String id = assignment['id']?.toString() ?? '';
    final String title = assignment['title'] ?? 'Untitled';
    final String subject = assignment['subject'] ?? 'No Subject';
    final String description = assignment['description'] ?? 'No description';
    final String deadlineFormatted = assignment['deadline_formatted'] ?? assignment['deadline'] ?? 'No deadline';

    final bool isActive = (assignment['is_active'] ?? 1) == 1;
    
    final submissionCount = _submissions
        .where((s) => s['assignment_id'].toString() == id)
        .length;
    final pendingForThis = _submissions
        .where(
          (s) => s['assignment_id'].toString() == id && s['status'] == 'Pending',
        )
        .length;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1a2b4a),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subject,
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  if (submissionCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: pendingForThis > 0
                            ? Colors.orange.withValues(alpha: 0.1)
                            : Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$submissionCount submission${submissionCount != 1 ? 's' : ''}',
                        style: TextStyle(
                          color: pendingForThis > 0
                              ? Colors.orange
                              : Colors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  // Status Chip - Active or Closed
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isActive ? 'Active' : 'Closed',
                      style: TextStyle(
                        color: isActive ? Colors.green : Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                'Deadline: $deadlineFormatted',  
                style: TextStyle(
                  color: isActive ? Colors.orange : Colors.red.shade400,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => _deleteAssignmentById(int.parse(id)),
                icon: const Icon(Icons.delete, size: 16),
                label: const Text('Delete'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== LESSON PLANS ====================
  Widget _buildLessonPlans() {
    String searchQuery = '';
    String selectedSubject = 'All';
    List<String> subjects = [
      'All',
      'AP',
      'ESP',
      'TLE',
      'Mathematics',
      'Science',
      'Filipino',
      'English',
      'MAPEH',
    ];

    return StatefulBuilder(
      builder: (context, setState) {
        List<Map<String, dynamic>> getFilteredMaterials() {
          return _materials.where((material) {
            bool matchesSearch =
                searchQuery.isEmpty ||
                material['title'].toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ) ||
                material['subject'].toLowerCase().contains(
                  searchQuery.toLowerCase(),
                );
            bool matchesSubject =
                selectedSubject == 'All' ||
                material['subject'] == selectedSubject;
            return matchesSearch && matchesSubject;
          }).toList();
        }

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            _isMobile ? 16 : 24,
            0,
            _isMobile ? 16 : 24,
            _isMobile ? 16 : 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: _isMobile ? 16 : 24),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: TextField(
                        onChanged: (value) =>
                            setState(() => searchQuery = value),
                        decoration: InputDecoration(
                          hintText: 'Search lesson plans...',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey.shade400,
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => Dialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        insetPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 40,
                        ),
                        child: const SizedBox(
                          width: 600,
                          child: UploadMaterialPage(),
                        ),
                      ),
                    ).then((uploadedMaterial) {
                      if (uploadedMaterial is UploadedMaterial) {
                        _loadMaterials();
                      }
                    });
                  },
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: const Text('Upload File'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0d2b5c),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    elevation: 0,
                  ),
                ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: subjects.map((subject) {
                    final bool isSelected = selectedSubject == subject;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: FilterChip(
                        label: Text(subject),
                        selected: isSelected,
                        onSelected: (_) =>
                            setState(() => selectedSubject = subject),
                        backgroundColor: Colors.white,
                        selectedColor: const Color(0xFF0d2b5c),
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Colors.grey.shade700,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? const Color(0xFF0d2b5c)
                              : Colors.grey.shade300,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '${getFilteredMaterials().length} materials found',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 16),
              getFilteredMaterials().isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: Column(
                          children: [
                            Icon(
                              Icons.folder_open,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text('No materials found'),
                          ],
                        ),
                      ),
                    )
                  : Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: getFilteredMaterials()
                          .map((material) => _lessonPlanCard(material))
                          .toList(),
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _lessonPlanCard(Map<String, dynamic> material) {
    final String id = material['id']?.toString() ?? '';
    final String title = material['title'] ?? 'Untitled';
    final String subject = material['subject'] ?? 'No Subject';
    final String format = material['type'] ?? 'PDF';
    final String filePath = material['file_url'] ?? '';
    final String displayDate = _getDisplayDate(material);

    Color getFormatColor(String f) {
      switch (f.toUpperCase()) {
        case 'PDF':
          return Colors.red;
        case 'DOCX':
          return Colors.blue;
        case 'PPTX':
          return Colors.orange;
        default:
          return Colors.grey;
      }
    }

    return Container(
      width: _isMobile ? double.infinity : 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: getFormatColor(format).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  format.toUpperCase(),
                  style: TextStyle(
                    color: getFormatColor(format),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditMaterialDialog(id, title, subject, format);
                  } else if (value == 'delete') {
                    _deleteMaterial(id);
                  } else if (value == 'download') {
                    _downloadMaterial(id, title);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),

                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color(0xFF1a2b4a),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subject,
            style: TextStyle(
              color: getFormatColor(format),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Text(
                displayDate,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _viewFilePreview(filePath, title),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('View', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0d2b5c),
                    side: const BorderSide(color: Color(0xFF0d2b5c)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _downloadFileToDevice(filePath, title),
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Download', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== ATTENDANCE UI ====================
  Widget _buildAttendance() {
    final now = DateTime.now();
    final todayKey =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final bool hasTodayRecord = _attendanceRecords.any((r) => r['date'] == todayKey);

    return SingleChildScrollView(
      padding: EdgeInsets.all(_isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Attendance Management',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1a2b4a),
                ),
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      if (hasTodayRecord) {
                        _markAttendanceForDate(todayKey);
                      } else {
                        _createAttendanceRecord();
                      }
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(
                      hasTodayRecord ? 'Edit Today' : 'Create Record',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0d2b5c),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _viewAttendanceHistory,
                    icon: const Icon(Icons.history, size: 18),
                    label: const Text('History'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0d2b5c),
                      side: const BorderSide(color: Color(0xFF0d2b5c)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Mark Today',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (hasTodayRecord) {
                          _markAttendanceForDate(todayKey);
                        } else {
                          await _createAttendanceRecord();
                        }
                      },
                      icon: const Icon(Icons.edit_calendar),
                      label: Text(
                        hasTodayRecord
                            ? 'Edit Today\'s Attendance'
                            : 'Mark Today\'s Attendance',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0d2b5c),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Recent Records',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  if (_attendanceRecords.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Text('No attendance records yet'),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _attendanceRecords.length > 3
                          ? 3
                          : _attendanceRecords.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final record = _attendanceRecords.reversed
                            .toList()[index];
                        final date = record['displayDate'] ?? record['date'];
                        final statuses = Map<String, String>.from(
                          record['statuses'],
                        );
                        int present = statuses.values
                            .where((s) => s == 'Present')
                            .length;
                        int late = statuses.values
                            .where((s) => s == 'Late')
                            .length;
                        int absent = statuses.values
                            .where((s) => s == 'Absent')
                            .length;
                        bool isToday = record['date'] == todayKey;

                        return ListTile(
                          leading: const Icon(
                            Icons.calendar_today,
                            color: Color(0xFF0d2b5c),
                          ),
                          title: Text(
                            date,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text('P: $present  L: $late  A: $absent'),
                          // ✅ Edit button LANG kung ngayon
                          trailing: isToday
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Color(0xFF0d2b5c),
                                  ),
                                  onPressed: () => _markAttendanceForDate(record['date']),
                                )
                              : null,
                        );
                      },
                    ),
                  if (_attendanceRecords.length > 3)
                    TextButton(
                      onPressed: _viewAttendanceHistory,
                      child: const Text('View all records →'),
                    ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _generateAttendanceSummary,
                      icon: const Icon(Icons.summarize),
                      label: const Text('Generate Attendance Summary'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0d2b5c),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== ANNOUNCEMENTS ====================
  Widget _buildAnnouncements() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(_isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Announcements',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _showAddAnnouncementDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Create Announcement'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0d2b5c),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_announcements.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'No announcements yet. Create one to get started!',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            for (var announcement in _announcements)
              _teacherAnnouncementCard(announcement),
        ],
      ),
    );
  }

  Widget _teacherAnnouncementCard(Map<String, dynamic> announcement) {
    final id = announcement['id'];
    final title = announcement['title'];
    final content = announcement['content'];
    final date = announcement['created_at']?.toString().split(' ')[0] ?? '';
    final colorValue = announcement['color'] ?? 'blue';
    Color color = colorValue == 'blue' ? Colors.blue : (colorValue == 'green' ? Colors.green : Colors.orange);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.announcement, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF1a2b4a))),
                    const SizedBox(height: 4),
                    Text(date, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18, color: Color(0xFF94A3B8)),
                onSelected: (value) {
                  if (value == 'delete') {
                    _deleteAnnouncementById(id);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(content, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }

  // ==================== QUIZZES ====================
  Widget _buildQuizzes() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(_isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Quizzes',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1a2b4a),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _createQuiz,
                icon: const Icon(Icons.add),
                label: const Text('Create Quiz'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0d2b5c),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_quizzes.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(child: Text('No quizzes created yet.')),
            )
          else
            for (var quiz in _quizzes)
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ExpansionTile(
                  title: Text(
                    quiz['title'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Row(
                    children: [
                      Text(
                        quiz['subject'] ?? 'No Subject',
                        style: const TextStyle(
                          color: Colors.blue, 
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('• ${quiz['questions'].length} questions'),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (quiz['description'] != null && quiz['description'].isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                quiz['description'],
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ),
                          ...List.generate(quiz['questions'].length, (idx) {
                            final q = quiz['questions'][idx];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${idx + 1}. ${q['text']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (q['type'] == 'Multiple Choice') ...[
                                    ...List.generate(
                                      q['choices'].length,
                                      (i) => Text(
                                        '   ${String.fromCharCode(65 + i)}. ${q['choices'][i]}',
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Correct Answer: ${q['correctAnswer']}. ${q['choices'][q['correctAnswer'].codeUnitAt(0) - 65]}',
                                      style: TextStyle(
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                  if (q['type'] == 'Identification') ...[
                                    Text(
                                      'Answer: ${q['answer']}',
                                      style: TextStyle(
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                  if (q['type'] == 'Essay') ...[
                                    Text(
                                      'Sample Answer: ${q['sampleAnswer'] ?? 'N/A'}',
                                      style: TextStyle(
                                        color: Colors.blue.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                  const Divider(),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _viewQuizSubmissions(quiz),
                              icon: const Icon(Icons.people, size: 18),
                              label: const Text('View Student Submissions'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF0d2b5c),
                                side: const BorderSide(color: Color(0xFF0d2b5c)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => _editQuizQuestions(quiz),
                                icon: const Icon(Icons.edit),
                                label: const Text('Edit Questions'),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: () => showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete Quiz'),
                                    content: Text(
                                      'Are you sure you want to delete "${quiz['title']}"?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () async {
                                          try {
                                            final response = await _api.post(
                                              'quizzes.php',
                                              {
                                                'action': 'delete',
                                                'id': quiz['id'],
                                              },
                                            );

                                            if (response['success'] == true) {
                                              setState(
                                                () => _quizzes.removeWhere(
                                                  (q) => q['id'] == quiz['id'],
                                                ),
                                              );
                                              Navigator.pop(ctx);
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Quiz deleted'),
                                                ),
                                              );
                                            } else {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Error: ${response['message']}',
                                                  ),
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Error deleting quiz: $e',
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                label: const Text(
                                  'Delete Quiz',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  // ==================== QUIZ SUBMISSIONS ====================
  void _viewQuizSubmissions(Map<String, dynamic> quiz) async {
    final attempts = await _fetchQuizAttempts(quiz['id'].toString());
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _QuizSubmissionsDialog(
        quiz: quiz,
        initialAttempts: attempts,
        onSaveScore: _saveEssayScore,
        onRefresh: () => _fetchQuizAttempts(quiz['id'].toString()),
      ),
    );
  }


  Future<void> _saveEssayScore(String quizId, String studentEmail, String questionKey, int score) async {
    try {
      final response = await _api.post('save_essay_score.php', {
        'quiz_id': quizId,
        'student_email': studentEmail,
        'question_key': questionKey,
        'score': score.toString(),
      });
      print('Essay score saved: $response');
    } catch (e) {
      print('Error saving essay score: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _fetchQuizAttempts(String quizId) async {
    try {
      final response = await _api.get('quiz_attempts.php?quiz_id=$quizId');
      if (response['success'] == true) {
        final attempts = List<Map<String, dynamic>>.from(response['attempts'] ?? []);
        
        for (var attempt in attempts) {
          final studentEmail = attempt['student_email'] ?? '';
          if (studentEmail.isNotEmpty) {
            try {
              final scoreResponse = await _api.get('essay_scores.php?quiz_id=$quizId&student_email=$studentEmail');
              if (scoreResponse['success'] == true) {
                attempt['essay_scores'] = Map<String, int>.from(scoreResponse['scores'] ?? {});
              }
            } catch (e) {
              print('Error loading essay scores: $e');
            }
          }
        }
        
        return attempts;
      }
      return [];
    } catch (e) {
      print('Error fetching quiz attempts: $e');
      return [];
    }
  }

  void _showNotificationsPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.7,
                maxChildSize: 0.9,
                minChildSize: 0.5,
                builder: (context, scrollController) {
                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Notifications (${_notifications.length})',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1a2b4a),
                              ),
                            ),
                            Row(
                              children: [
                                if (_getUnreadNotificationCount() > 0)
                                  TextButton(
                                    onPressed: () async {
                                      await _api.post('notifications.php', {
                                        'action': 'mark_all_read',
                                        'user_id':
                                            _authService.currentUserId ?? 0,
                                      });
                                      setSheetState(() {
                                        for (var n in _notifications) {
                                          n['read_status'] = 1;
                                        }
                                      });
                                    },
                                    child: const Text('Mark all read'),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _notifications.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.notifications_none,
                                      size: 48,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No notifications',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: _notifications.length,
                                itemBuilder: (ctx, index) {
                                  final notification = _notifications[index];
                                  final isRead =
                                      notification['read_status'] == 1 ||
                                      notification['read_status'] == true;
                                  final type = notification['type'] ?? 'info';

                                  Color typeColor = Colors.blue;
                                  IconData typeIcon = Icons.info;

                                  if (type == 'success') {
                                    typeColor = Colors.green;
                                    typeIcon = Icons.check_circle;
                                  } else if (type == 'warning') {
                                    typeColor = Colors.orange;
                                    typeIcon = Icons.warning;
                                  } else if (type == 'error') {
                                    typeColor = Colors.red;
                                    typeIcon = Icons.error;
                                  }

                                  return Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isRead
                                          ? Colors.white
                                          : Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isRead
                                            ? const Color(0xFFE2E8F0)
                                            : typeColor.withValues(alpha: 0.3),
                                        width: isRead ? 1 : 2,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Icon(
                                              typeIcon,
                                              color: typeColor,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          notification['title'] ??
                                                              '',
                                                          style: TextStyle(
                                                            fontWeight: isRead
                                                                ? FontWeight
                                                                      .w500
                                                                : FontWeight
                                                                      .bold,
                                                            color: const Color(
                                                              0xFF1a2b4a,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      if (!isRead)
                                                        Container(
                                                          width: 8,
                                                          height: 8,
                                                          decoration:
                                                              BoxDecoration(
                                                                color:
                                                                    typeColor,
                                                                shape: BoxShape
                                                                    .circle,
                                                              ),
                                                        ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    notification['message'] ??
                                                        '',
                                                    style: TextStyle(
                                                      color:
                                                          Colors.grey.shade700,
                                                      fontSize: 13,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            PopupMenuButton(
                                              itemBuilder: (ctx) => [
                                                if (!isRead)
                                                  PopupMenuItem(
                                                    child: const Text(
                                                      'Mark as read',
                                                    ),
                                                    onTap: () {
                                                      _markNotificationAsRead(
                                                        notification['id'],
                                                      );
                                                    },
                                                  ),
                                                PopupMenuItem(
                                                  child: const Text('Delete'),
                                                  onTap: () {
                                                    _deleteNotification(
                                                      notification['id'],
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _formatNotificationTime(
                                            notification['created_at'],
                                          ),
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  String _formatNotificationTime(String? timestamp) {
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
}

class _QuizSubmissionsDialog extends StatefulWidget {
  final Map<String, dynamic> quiz;
  final List<Map<String, dynamic>> initialAttempts;
  final Future<void> Function(String quizId, String email, String key, int score) onSaveScore;
  final Future<List<Map<String, dynamic>>> Function() onRefresh;

  const _QuizSubmissionsDialog({
    required this.quiz,
    required this.initialAttempts,
    required this.onSaveScore,
    required this.onRefresh,
  });

  @override
  State<_QuizSubmissionsDialog> createState() => _QuizSubmissionsDialogState();
}

class _QuizSubmissionsDialogState extends State<_QuizSubmissionsDialog> {
  late List<Map<String, dynamic>> attempts;
  final Map<String, Map<String, int>> _pendingScores = {};
  final Map<String, Map<String, bool>> _saving = {};

  @override
  void initState() {
    super.initState();
    attempts = widget.initialAttempts;
    _initPendingScores();
  }

  void _initPendingScores() {
    for (final attempt in attempts) {
      final email = attempt['student_email']?.toString() ?? '';
      final existingScores = _safeEssayScores(attempt['essay_scores']);
      _pendingScores[email] = Map<String, int>.from(existingScores);
      _saving[email] = {};
    }
  }

  Map<String, int> _safeEssayScores(dynamic raw) {
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(k.toString(), int.tryParse(v.toString()) ?? 0));
    }
    return {};
  }

  Map<String, String> _safeEssayAnswers(dynamic rawAnswers) {
    dynamic answers = rawAnswers;
    if (answers is String) {
      try { answers = jsonDecode(answers); } catch (_) { return {}; }
    }
    if (answers is! Map) return {};
    final essay = answers['essay'];
    if (essay is Map) {
      return essay.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
    }
    return {};
  }

  List<Map<String, dynamic>> _getEssayQuestions() {
    final questions = List<Map<String, dynamic>>.from(widget.quiz['questions'] ?? []);
    return questions
        .asMap()
        .entries
        .where((e) => e.value['type']?.toString() == 'Essay')
        .map((e) => {'index': e.key, 'question': e.value})
        .toList();
  }

  Future<void> _saveScore(String email, String questionKey, int score) async {
    setState(() {
      _saving[email] ??= {};
      _saving[email]![questionKey] = true;
    });

    try {
      await widget.onSaveScore(
        widget.quiz['id'].toString(),
        email,
        questionKey,
        score,
      );

      final updated = await widget.onRefresh();
      if (mounted) {
        setState(() {
          attempts = updated;
          _initPendingScores();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Score saved successfully!'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving score: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving[email]?[questionKey] = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final essayQuestions = _getEssayQuestions();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 700),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0d2b5c), Color(0xFF1a5276)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.people, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Submissions: ${widget.quiz['title']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${attempts.length} student(s) submitted',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ────────────────────────────────────────────────────
            Expanded(
              child: attempts.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inbox, size: 48, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('No submissions yet', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: attempts.length,
                      itemBuilder: (context, index) {
                        final attempt = attempts[index];
                        final email = attempt['student_email']?.toString() ?? '';
                        final name = attempt['student_name']?.toString() ?? email;
                        final scoreCorrect = attempt['score_correct'] ?? 0;
                        final scoreTotal = attempt['score_total'] ?? 0;
                        final essayScores = _safeEssayScores(attempt['essay_scores']);
                        final essayTotal = attempt['essay_score_total'] ?? essayScores.values.fold(0, (a, b) => a + b);
                        final essayAnswers = _safeEssayAnswers(attempt['answers']);
                        final allScored = essayQuestions.isNotEmpty &&
                            essayQuestions.every((eq) {
                              final key = eq['index'].toString();
                              return (essayScores[key] ?? 0) > 0;
                            });

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: allScored
                                  ? Colors.green.shade200
                                  : const Color(0xFFE2E8F0),
                              width: allScored ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Student header
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: const Color(0xFF0d2b5c).withValues(alpha: 0.1),
                                      child: Text(
                                        (name.isNotEmpty ? name[0] : '?').toUpperCase(),
                                        style: const TextStyle(
                                          color: Color(0xFF0d2b5c),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(name,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF1a2b4a))),
                                          Text(email,
                                              style: TextStyle(
                                                  color: Colors.grey.shade600, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    // Score badges
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.blue.shade200),
                                          ),
                                          child: Text(
                                            'Objective: $scoreCorrect/$scoreTotal',
                                            style: TextStyle(
                                                color: Colors.blue.shade700,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                        if (essayQuestions.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: allScored
                                                  ? Colors.green.shade50
                                                  : Colors.orange.shade50,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: allScored
                                                    ? Colors.green.shade200
                                                    : Colors.orange.shade200,
                                              ),
                                            ),
                                            child: Text(
                                              allScored
                                                  ? 'Essay: $essayTotal pts ✓'
                                                  : 'Essay: needs scoring',
                                              style: TextStyle(
                                                color: allScored
                                                    ? Colors.green.shade700
                                                    : Colors.orange.shade700,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Essay questions scoring
                              if (essayQuestions.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    'No essay questions in this quiz.',
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                                  ),
                                )
                              else
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: essayQuestions.map((eq) {
                                      final qIndex = eq['index'] as int;
                                      final question = eq['question'] as Map<String, dynamic>;
                                      final qKey = qIndex.toString();
                                      final answer = essayAnswers[qKey] ?? '(blank)';
                                      final existing = essayScores[qKey] ?? 0;
                                      final pending = _pendingScores[email]?[qKey] ?? existing;
                                      final isSaving = _saving[email]?[qKey] ?? false;
                                      final isScored = existing > 0;

                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: isScored
                                              ? Colors.green.shade50
                                              : Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: isScored
                                                ? Colors.green.shade200
                                                : Colors.grey.shade200,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Question text
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF0d2b5c).withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    'Q${qIndex + 1}',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF0d2b5c),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    question['text']?.toString() ?? '',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 13,
                                                      color: Color(0xFF1a2b4a),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),

                                            // Student answer
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: Colors.grey.shade200),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text('Student Answer:',
                                                      style: TextStyle(
                                                          fontSize: 11,
                                                          color: Colors.grey.shade500,
                                                          fontWeight: FontWeight.w600)),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    answer,
                                                    style: const TextStyle(
                                                        fontSize: 14,
                                                        color: Color(0xFF1a2b4a),
                                                        height: 1.4),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 12),

                                            // ── SCORE INPUT ROW (FIXED) ──
                                            SizedBox(
                                              width: double.infinity,
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  // Slider section
                                                  Expanded(
                                                    flex: 3,
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Row(
                                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                          children: [
                                                            Text(
                                                              'Score:',
                                                              style: TextStyle(
                                                                fontSize: 13,
                                                                fontWeight: FontWeight.w600,
                                                                color: Colors.grey.shade700,
                                                              ),
                                                            ),
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                                              decoration: BoxDecoration(
                                                                color: pending == 0
                                                                    ? Colors.grey.shade100
                                                                    : const Color(0xFF0d2b5c).withValues(alpha: 0.1),
                                                                borderRadius: BorderRadius.circular(8),
                                                              ),
                                                              child: Text(
                                                                pending == 0 ? 'Not set' : '$pending / 10',
                                                                style: TextStyle(
                                                                  fontSize: 14,
                                                                  fontWeight: FontWeight.bold,
                                                                  color: pending == 0 ? Colors.grey : const Color(0xFF0d2b5c),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(height: 4),
                                                        SliderTheme(
                                                          data: SliderTheme.of(context).copyWith(
                                                            trackHeight: 4,
                                                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                                                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
                                                            activeTrackColor: const Color(0xFF0d2b5c),
                                                            inactiveTrackColor: Colors.grey.shade200,
                                                            thumbColor: const Color(0xFF0d2b5c),
                                                          ),
                                                          child: Slider(
                                                            min: 5,
                                                            max: 10,
                                                            divisions: 5,
                                                            value: (pending >= 5 && pending <= 10) ? pending.toDouble() : 5.0,
                                                            onChanged: (val) {
                                                              setState(() {
                                                                _pendingScores[email] ??= {};
                                                                _pendingScores[email]![qKey] = val.round();
                                                              });
                                                            },
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding: const EdgeInsets.symmetric(horizontal: 4),
                                                          child: Row(
                                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                            children: List.generate(6, (i) {
                                                              final val = 5 + i;
                                                              return Text(
                                                                '$val',
                                                                style: TextStyle(
                                                                  fontSize: 11,
                                                                  color: pending == val ? const Color(0xFF0d2b5c) : Colors.grey.shade400,
                                                                  fontWeight: pending == val ? FontWeight.bold : FontWeight.normal,
                                                                ),
                                                              );
                                                            }),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),

                                                  // Save button
                                                  SizedBox(
                                                    width: 80,
                                                    height: 44,
                                                    child: ElevatedButton(
                                                      onPressed: isSaving ? null : () => _saveScore(email, qKey, pending >= 5 ? pending : 5),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: isScored && existing == pending
                                                            ? Colors.green.shade600
                                                            : const Color(0xFF0d2b5c),
                                                        disabledBackgroundColor: Colors.grey.shade300,
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                        elevation: 0,
                                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                                      ),
                                                      child: isSaving
                                                          ? const SizedBox(
                                                              width: 18,
                                                              height: 18,
                                                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                                            )
                                                          : Row(
                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                              children: [
                                                                Icon(
                                                                  isScored && existing == pending ? Icons.check : Icons.save,
                                                                  size: 14,
                                                                  color: Colors.white,
                                                                ),
                                                                const SizedBox(width: 4),
                                                                Text(
                                                                  isScored && existing == pending ? 'Saved' : 'Save',
                                                                  style: const TextStyle(
                                                                    fontSize: 11,
                                                                    color: Colors.white,
                                                                    fontWeight: FontWeight.w600,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            // ── Footer ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0d2b5c),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: const Text('Close',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

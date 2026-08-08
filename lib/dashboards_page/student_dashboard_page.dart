import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
import '/security_service/auth_service.dart';
import '/services/api_client.dart';
import '../pages/quiz_take_page.dart';
import '../pages/quiz_result_page.dart';
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../pages/file_viewer_widget.dart';

class StudentDashboardPage extends StatefulWidget {
  const StudentDashboardPage({super.key});

  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  final _authService = AuthService();
  final ApiClient _api = ApiClient();

  int _selectedIndex = 0;
  bool _isMobile = false;
  bool _isLoadingAssignments = false;

  List<Map<String, dynamic>> _assignments = [];
  List<Map<String, dynamic>> _submissions = [];
  List<Map<String, dynamic>> _attendanceRecords = [];
  List<Map<String, dynamic>> _announcements = [];
  List<Map<String, dynamic>> _materials = [];
  int _newAnnouncementCount = 0;
  Set<String> _readAnnouncementIds = {};

  List<Map<String, dynamic>> _quizzes = [];
  List<Map<String, dynamic>> _quizAttempts = [];

  @override
  void initState() {
    super.initState();
    _loadAssignmentsWithStatus();
    _loadAttendanceData();  
    _loadAnnouncementsFromTeacher();
    _loadMaterials();
    _loadTeacherQuizzes();
    _loadStudentQuizAttempts();
  }
    
  // ==================== MATERIALS (Lesson Plans) ====================
  Future<void> _loadMaterials() async {
    try {
      final response = await _api.get('materials.php');
      if (response['success'] == true) {
        setState(() {
          _materials = List<Map<String, dynamic>>.from(response['materials'] ?? []);
        });
      } else {
        _materials = [];
      }
    } catch (e) {
      print('Error loading materials: $e');
      _materials = [];
    }
  }

// ==================== ATTENDANCE METHODS ====================
Future<void> _loadAttendanceData() async {
  try {
    final response = await _api.get('attendance.php');
    if (response['success'] == true) {
      final records = List<Map<String, dynamic>>.from(response['attendance_records'] ?? []);
      
      final studentEmail = _authService.currentUserEmail ?? '';
      final studentId = _authService.currentUserId?.toString() ?? '';
      
      print('📡 Student Email: $studentEmail');
      print('📡 Student ID: $studentId');
      
      if (studentEmail.isEmpty && studentId.isEmpty) {
        print('⚠️ No student email or ID found');
        setState(() => _attendanceRecords = []);
        return;
      }

      final List<Map<String, dynamic>> filtered = [];

      for (var record in records) {
        final statusesRaw = record['statuses'];
        Map<String, String> statuses = {};
        
        if (statusesRaw is Map) {
          statuses = Map<String, String>.from(statusesRaw);
        } else if (statusesRaw is String) {
          try {
            statuses = Map<String, String>.from(jsonDecode(statusesRaw));
          } catch (e) {
            print('Error parsing statuses JSON: $e');
            continue;
          }
        } else {
          continue;
        }

        // Try to find the student's status using email or ID
        String? status;

        // Try exact email match
        if (studentEmail.isNotEmpty && statuses.containsKey(studentEmail)) {
          status = statuses[studentEmail];
        }
        // Try student ID match (as string)
        else if (studentId.isNotEmpty && statuses.containsKey(studentId)) {
          status = statuses[studentId];
        }
        // Try partial email match (for cases where email has extra characters)
        else if (studentEmail.isNotEmpty) {
          for (var key in statuses.keys) {
            if (key.contains(studentEmail) || studentEmail.contains(key)) {
              status = statuses[key];
              break;
            }
          }
        }

        // If found, add to filtered list
        if (status != null) {
          filtered.add({
            'date': record['date'] ?? '',
            'displayDate': record['display_date'] ?? record['date'] ?? '',
            'status': status,
          });
        }
      }

      // Sort by date (newest first)
      filtered.sort((a, b) => (b['date'] ?? '').compareTo(a['date'] ?? ''));

      print('📡 Found ${filtered.length} attendance records for student');
      setState(() => _attendanceRecords = filtered);
      
    } else {
      print('❌ Failed to load attendance: ${response['message']}');
      setState(() => _attendanceRecords = []);
    }
  } catch (e) {
    print('❌ Error loading attendance: $e');
    setState(() => _attendanceRecords = []);
  }
}

  // ==================== ANNOUNCEMENT METHODS ====================
  Future<void> _loadAnnouncementsFromTeacher() async {
    final prefs = await SharedPreferences.getInstance();
    final studentEmail = _authService.currentUserEmail ?? 'student';
    final readKey = 'read_announcements_${studentEmail.replaceAll('.', '_')}';

    try {
      final response = await _api.get('announcements.php');
      if (response['success'] == true) {
        final loadedAnnouncements = List<Map<String, dynamic>>.from(response['announcements'] ?? []);

        final readIdsJson = prefs.getString(readKey);
        if (readIdsJson != null) {
          _readAnnouncementIds = Set<String>.from(jsonDecode(readIdsJson) as List);
        }

        setState(() {
          _announcements = loadedAnnouncements;
          _newAnnouncementCount = _announcements
              .where((a) => !_readAnnouncementIds.contains(a['id'].toString()))
              .length;
        });
      } else {
        setState(() {
          _announcements = [];
          _newAnnouncementCount = 0;
        });
      }
    } catch (e) {
      print('Error loading announcements: $e');
      setState(() {
        _announcements = [];
        _newAnnouncementCount = 0;
      });
    }
  }

  Future<void> _markAnnouncementAsRead(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final studentEmail = _authService.currentUserEmail ?? 'student';
    final readKey = 'read_announcements_${studentEmail.replaceAll('.', '_')}';

    if (!_readAnnouncementIds.contains(id)) {
      _readAnnouncementIds.add(id);
      await prefs.setString(readKey, jsonEncode(_readAnnouncementIds.toList()));

      setState(() {
        _newAnnouncementCount = _announcements
            .where((a) => !_readAnnouncementIds.contains(a['id'].toString()))
            .length;
      });
    }
  }

    // ==================== ASSIGNMENT METHODS ====================
  Future<void> _loadAssignmentsWithStatus() async {
    setState(() {
      _isLoadingAssignments = true;
    });

    try {
      final assignmentsResponse = await _api.get('assignments.php');
      if (assignmentsResponse['success'] == true) {
        _assignments = List<Map<String, dynamic>>.from(assignmentsResponse['assignments'] ?? []);
      } else {
        _assignments = [];
      }

      final submissionsResponse = await _api.get('submission.php');
      if (submissionsResponse['success'] == true) {
        final allSubmissions = List<Map<String, dynamic>>.from(submissionsResponse['submissions'] ?? []);
        final studentEmail = _authService.currentUserEmail ?? 'student';
        _submissions = allSubmissions.where((s) => s['student_email'] == studentEmail).toList();
        
        print('📡 Loaded ${_submissions.length} submissions for student: $studentEmail');
      } else {
        print('❌ Failed to load submissions: ${submissionsResponse['message']}');
        _submissions = [];
      }
      
      print('📡 Loaded ${_assignments.length} assignments');
    } catch (e) {
      print('❌ Error loading data: $e');
      _assignments = [];
      _submissions = [];
    } finally {
      setState(() {
        _isLoadingAssignments = false;
      });
    }
  }

  bool _isAssignmentSubmitted(String assignmentId) {
    return _submissions.any((sub) => sub['assignment_id'] == assignmentId);
  }
  Map<String, dynamic>? _getSubmission(String assignmentId) {
    try {
      return _submissions.firstWhere((sub) => sub['assignment_id'] == assignmentId);
    } catch (e) {
      return null;
    }
  }

  Future<void> _submitAssignment(
    String assignmentId,
    String comment,
    String fileName,
    Uint8List? fileBytes,
  ) async {
    final studentEmail = _authService.currentUserEmail ?? 'student';

    print('📤 Sending: assignment_id=$assignmentId, comment="$comment", fileName="$fileName"');

    try {
      final response = await _api.uploadFile(
        'submit_assignment.php',
        'file',
        '',
        fields: {
          'assignment_id': assignmentId,
          'student_email': studentEmail,
          'comment': comment,
          'file_name': fileName,
        },
        fileBytes: fileBytes,
        fileName: fileName,
      );
      
      print('📡 Submit response: $response');
      
      if (response['success'] == true) {
        await _loadAssignmentsWithStatus();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Assignment submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Submission failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Submit error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    try {
      await _authService.logout();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
      }
    }
  }


  void _navigateToSubmitAssignment(String assignmentId, String assignmentTitle) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: _SubmitAssignmentModal(
          assignmentId: assignmentId,
          assignmentTitle: assignmentTitle,
          onSubmit: (comment, fileName, fileBytes) async {
            await _submitAssignment(assignmentId, comment, fileName, fileBytes);
          },
        ),
      ),
    ).then((_) => _loadAssignmentsWithStatus());
  }

  void _navigateToSubmissionStatus() {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: _SubmissionStatusModal(
          submissions: _submissions,
          assignments: _assignments,
          singleView: false,
        ),
      ),
    );
  }

  // ==================== QUIZ METHODS ====================
  Future<void> _loadTeacherQuizzes() async {
    try {
      final response = await _api.get('quizzes.php');
      print('📡 Quizzes API response: $response'); 
      if (response['success'] == true) {
        final List<Map<String, dynamic>> quizzesList = 
            List<Map<String, dynamic>>.from(response['quizzes'] ?? []);
        for (var quiz in quizzesList) {
          if (quiz['questions'] is String) {
            try {
              quiz['questions'] = jsonDecode(quiz['questions']);
            } catch (e) {
              quiz['questions'] = [];
            }
          }
          if (quiz['questions'] is! List) {
            quiz['questions'] = [];
          }
        }
        print('📡 Loaded ${quizzesList.length} quizzes from server'); 
        setState(() => _quizzes = quizzesList);
      } else {
        print('❌ Failed to load quizzes: ${response['message']}');
        _quizzes = [];
      }
    } catch (e) {
      print('❌ Error loading quizzes: $e');
      _quizzes = [];
    }
  }

  Future<void> _loadStudentQuizAttempts() async {
    final studentEmail = _authService.currentUserEmail ?? 'student';

    try {
      final response = await _api.get(
        'quiz_attempts.php?student_email=${Uri.encodeComponent(studentEmail)}',
      );
      if (response['success'] == true) {
        final apiAttempts = List<Map<String, dynamic>>.from(response['attempts'] ?? []);
        if (apiAttempts.isNotEmpty) {
          setState(() => _quizAttempts = apiAttempts);
          return;
        }
      }
    } catch (e) {
      debugPrint('Error loading quiz attempts from API: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    final key   = studentEmail.replaceAll('.', '_');
    final json  = prefs.getString('quiz_attempts_$key');
    setState(() {
      _quizAttempts = json != null
          ? List<Map<String, dynamic>>.from(jsonDecode(json))
          : [];
    });
  }

  Map<String, dynamic>? _getQuizById(String id) {
    try {
      return _quizzes.firstWhere((quiz) => quiz['id'].toString() == id);
    } catch (_) {
      return null;
    }
  }

  // ==================== BUILD ====================
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

  // ==================== APP BAR & DRAWER ====================
  PreferredSizeWidget _buildMobileAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0d2b5c),
      foregroundColor: Colors.white,
      elevation: 0,
      title: Row(
        children: [
          Image.asset('assets/capstonelogo.png', width: 32, height: 32),
          const SizedBox(width: 12),
          const Text('Student Portal', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        ],
      ),
      actions: [
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
                  Text(_authService.currentUserName ?? 'Student', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(_authService.currentUserEmail ?? '', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(value: 'change_password', child: Row(children: [Icon(Icons.lock_outline, size: 18), SizedBox(width: 8), Text('Change Password')])),
            const PopupMenuItem(value: 'logout', child: Row(children: [Icon(Icons.logout, size: 18, color: Colors.red), SizedBox(width: 8), Text('Logout', style: TextStyle(color: Colors.red))])),
          ],
        ),
        const SizedBox(width: 16),
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
                const Text('Student Portal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18)),
              ],
            ),
          ),
          _drawerItem(Icons.dashboard_outlined, 'Overview', 0),
          _drawerItem(Icons.folder, 'Materials', 1),   // NEW
          _drawerItem(Icons.assignment_outlined, 'Assignments', 2),
          _drawerItem(Icons.quiz_outlined, 'Quizzes', 3),
          _drawerItem(Icons.calendar_today_outlined, 'Attendance', 4),
          _drawerItem(Icons.announcement_outlined, 'Announcements', 5),
          const Spacer(),
          const Divider(),
          ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)), onTap: _logout),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    final hasNotification = index == 5 && _newAnnouncementCount > 0;
    return ListTile(
      leading: Stack(
        children: [
          Icon(icon, color: isSelected ? const Color(0xFF0d2b5c) : Colors.grey.shade600),
          if (hasNotification)
            Positioned(
              right: 0,
              top: 0,
              child: Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
            ),
        ],
      ),
      title: Text(label, style: TextStyle(color: isSelected ? const Color(0xFF0d2b5c) : Colors.grey.shade700, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
      trailing: hasNotification
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
              child: Text('$_newAnnouncementCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            )
          : null,
      tileColor: isSelected ? const Color(0xFF0d2b5c).withValues(alpha: 0.08) : null,
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
              children: [
                Image.asset('assets/capstonelogo.png', width: 40, height: 40),
                const SizedBox(width: 12),
                const Text('Student Portal', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF1a2b4a))),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _sidebarItem(Icons.dashboard_outlined, 'Overview', 0),
          _sidebarItem(Icons.folder, 'Materials', 1),
          _sidebarItem(Icons.assignment_outlined, 'Assignments', 2),
          _sidebarItem(Icons.quiz_outlined, 'Quizzes', 3),
          _sidebarItem(Icons.calendar_today_outlined, 'Attendance', 4),
          _sidebarItem(Icons.announcement_outlined, 'Announcements', 5),
          const Spacer(),
          const Divider(),
          ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)), onTap: _logout),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _sidebarItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    final hasNotification = index == 5 && _newAnnouncementCount > 0;
    return ListTile(
      leading: Stack(
        children: [
          Icon(icon, color: isSelected ? const Color(0xFF0d2b5c) : Colors.grey.shade600),
          if (hasNotification)
            Positioned(
              right: 0,
              top: 0,
              child: Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
            ),
        ],
      ),
      title: Text(label, style: TextStyle(color: isSelected ? const Color(0xFF0d2b5c) : Colors.grey.shade700, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
      trailing: hasNotification
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
              child: Text('$_newAnnouncementCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            )
          : null,
      tileColor: isSelected ? const Color(0xFF0d2b5c).withValues(alpha: 0.08) : null,
      onTap: () => setState(() => _selectedIndex = index),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0: return _buildOverview();
      case 1: return _buildMaterials();
      case 2: return _buildAssignments();
      case 3: return _buildQuizzes();
      case 4: return _buildAttendance();
      case 5: return _buildAnnouncements();
      default: return _buildOverview();
    }
  }

  // ==================== MATERIALS PAGE ====================
  Widget _buildMaterials() {
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

    List<Map<String, dynamic>> getFilteredMaterials() {
      return _materials.where((material) {
        bool matchesSearch = searchQuery.isEmpty ||
            material['title'].toLowerCase().contains(searchQuery.toLowerCase()) ||
            material['subject'].toLowerCase().contains(searchQuery.toLowerCase());
        bool matchesSubject = selectedSubject == 'All' || material['subject'] == selectedSubject;
        return matchesSearch && matchesSubject;
      }).toList();
    }

    return StatefulBuilder(
      builder: (context, setState) {
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(_isMobile ? 16 : 24, 0, _isMobile ? 16 : 24, _isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              // Page Title
              const Text(
                'Lesson Materials',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1a2b4a),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'View all learning materials uploaded by your teacher',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 20),
              // Search Bar (no Upload button)
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search materials...',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Filter Chips
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
                        onSelected: (_) {
                          setState(() {
                            selectedSubject = subject;
                          });
                        },
                        backgroundColor: Colors.white,
                        selectedColor: const Color(0xFF0d2b5c),
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey.shade700,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        side: BorderSide(
                          color: isSelected ? const Color(0xFF0d2b5c) : Colors.grey.shade300,
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
              if (getFilteredMaterials().isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Column(
                      children: [
                        Icon(Icons.folder_open, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No materials found',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: getFilteredMaterials().map((material) => _materialCard(material)).toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  // ==================== MATERIAL CARD ====================
  Widget _materialCard(Map<String, dynamic> material) {
    final String id = material['id']?.toString() ?? '';
    final String title = material['title'] ?? 'Untitled';
    final String subject = material['subject'] ?? 'No Subject';
    final String date = _getDisplayDate(material);
    final String format = material['type'] ?? 'PDF';
    final String filePath = material['file_url'] ?? '';

    Color getFormatColor(String format) {
      switch (format.toUpperCase()) {
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                icon: const Icon(Icons.more_vert, size: 20, color: Color(0xFF64748B)),
                onSelected: (value) {
                  if (value == 'download') {
                    _downloadMaterial(id, title);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'download',
                    child: Row(
                      children: [
                        Icon(Icons.download, size: 18),
                        SizedBox(width: 8),
                        Text('Download'),
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
                date,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Use filePath for viewing
                    _viewMaterial(filePath, title);
                  },
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
                  onPressed: () {
                    _downloadMaterial(id, title);
                  },
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

  // ==================== HELPER METHODS ====================
  String _getDisplayDate(Map<String, dynamic> material) {
    if (material['created_at_formatted'] != null && material['created_at_formatted'].toString().isNotEmpty) {
      return material['created_at_formatted'];
    }
    String rawDate = material['created_at']?.toString() ?? material['date']?.toString() ?? '';
    if (rawDate.isEmpty) return 'No date';
    if (rawDate.contains(' ')) return rawDate.split(' ')[0];
    if (rawDate.contains('T')) return rawDate.split('T')[0];
    return rawDate;
  }

Future<void> _viewMaterial(String filePath, String title) async {
  if (filePath.isEmpty) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No file associated with this material.')),
      );
    }
    return;
  }

  String fixedUrl = filePath;
  if (filePath.contains('localhost')) {
    fixedUrl = filePath.replaceFirst('http://localhost', 'http://127.0.0.1');
  }
  if (!fixedUrl.startsWith('http')) {
    if (fixedUrl.startsWith('/ADET/backend/')) {
      fixedUrl = 'http://127.0.0.1$fixedUrl';
    } else if (fixedUrl.startsWith('/ADET/')) {
      fixedUrl = 'http://127.0.0.1$fixedUrl';
    } else if (fixedUrl.startsWith('/')) {
      fixedUrl = 'http://127.0.0.1$fixedUrl';
    } else {
      fixedUrl = 'http://127.0.0.1/ADET/backend/$fixedUrl';
    }
  }

  final ext = fixedUrl.split('.').last.split('?').first.toUpperCase();
  FileViewerDialog.show(
    context,
    fileUrl: fixedUrl,
    fileName: title,
    fileType: ext,
  );
}

void _downloadMaterial(String id, String title) {
  final material = _materials.firstWhere((m) => m['id'].toString() == id);
  final filePath = material['file_url'] ?? '';

  if (filePath.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No file to download.')),
    );
    return;
  }

  if (kIsWeb) {
    String fixedUrl = filePath;
    if (fixedUrl.contains('localhost')) {
      fixedUrl = fixedUrl.replaceFirst('http://localhost', 'http://127.0.0.1');
    }
    if (!fixedUrl.startsWith('http')) {
      fixedUrl = 'http://127.0.0.1$fixedUrl';
    }

    final uri = Uri.parse(fixedUrl);
    final pathOnly = uri.path;
    final safeTitle = title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '').trim();

    final encodedPath = Uri.encodeComponent(pathOnly);
    final encodedTitle = Uri.encodeComponent(safeTitle);

    final downloadUrl =
        'http://127.0.0.1/ADET/backend/php/materials.php'
        '?download=1'
        '&file_url=$encodedPath'
        '&title=$encodedTitle';

    html.window.location.href = downloadUrl;
  }
}

  // ==================== OVERVIEW ====================
  Widget _buildOverview() {
    final pendingCount = _assignments.where((a) {
      final isSubmitted = _isAssignmentSubmitted(a['id']);
      if (!isSubmitted) return true; 
      final sub = _getSubmission(a['id']);
      return sub?['status'] == 'Pending'; 
    }).length;

    final submittedCount = _submissions.where((s) => s['status'] == 'Approved').length;
    final materialsCount = _materials.length;
    final announcementCount = _announcements.length;

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
                        'Welcome back, ${_authService.currentUserName ?? 'Student'}!',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Track your academic progress and stay updated with your classes.',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
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
                  _statCard('Assignments', '$pendingCount', 'Pending', Colors.orange, Icons.assignment),
                  _statCard('Submitted', '$submittedCount', 'Done', Colors.green, Icons.check_circle),
                  _statCard('Materials', '$materialsCount', 'Lesson Plans', Colors.purple, Icons.folder),
                  _statCard('Announcements', '$announcementCount', 'Updates', Colors.blue, Icons.announcement),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Bottom area
          if (_isMobile)
            Column(
              children: [
                _buildRecentAssignments(),
                const SizedBox(height: 16),
                _buildQuizzesSection(isTall: false),
                const SizedBox(height: 16),
                _buildAttendanceSummary(),
              ],
            )
          else
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        Expanded(child: _buildRecentAssignments()),
                        const SizedBox(height: 16),
                        Expanded(child: _buildAttendanceSummary()),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: _buildQuizzesSection(isTall: true),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  int _getAttendancePercentage() {
    if (_attendanceRecords.isEmpty) return 0;
    int present = _attendanceRecords.where((r) => r['status'] == 'Present').length;
    return ((present / _attendanceRecords.length) * 100).round();
  }

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
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
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

  // ==================== RECENT ASSIGNMENTS ====================
  Widget _buildRecentAssignments() {
    final recentAssignments = _assignments.take(3).toList();
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Assignments', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1a2b4a))),
              TextButton(
                onPressed: () => setState(() => _selectedIndex = 2),
                child: const Text('View All', style: TextStyle(color: Color(0xFF007bff), fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (recentAssignments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('No assignments yet', style: TextStyle(color: Colors.grey)),
            )
          else
            ...recentAssignments.map((assignment) {
              final isSubmitted = _isAssignmentSubmitted(assignment['id']);
              final submission = _getSubmission(assignment['id']);
              final status = submission?['status'] ?? '';
              final title = assignment['title'] ?? 'Untitled';
              final subject = assignment['subject'] ?? 'No Subject';

              String displayStatus = '';
              Color statusColor = Colors.orange;

              if (isSubmitted) {
                if (status == 'Approved') {
                  displayStatus = 'Done';
                  statusColor = Colors.green;
                } else if (status == 'Rejected') {
                  displayStatus = 'Rejected';
                  statusColor = Colors.red;
                } else {
                  displayStatus = 'Pending';
                  statusColor = Colors.orange;
                }
              } else {
                displayStatus = 'Active';
                statusColor = Colors.blue;
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1a2b4a))),
                          const SizedBox(height: 2),
                          Text(subject, style: TextStyle(color: isSubmitted ? statusColor : Colors.orange, fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    if (isSubmitted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          displayStatus,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ==================== QUIZZES SECTION ====================
  Widget _buildQuizzesSection({bool isTall = false}) {
    final availableQuizzes = _quizzes.take(3).toList();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      height: isTall ? double.infinity : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Quizzes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1a2b4a))),
              TextButton(
                onPressed: () => setState(() => _selectedIndex = 3),
                child: const Text('View All', style: TextStyle(color: Color(0xFF007bff), fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (availableQuizzes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('No quizzes available', style: TextStyle(color: Colors.grey)),
            )
          else
            ...availableQuizzes.map((quiz) {
              final title = quiz['title'] ?? 'Quiz';
              final questionCount = (quiz['questions'] as List?)?.length ?? 0;
              final info = '$questionCount question${questionCount != 1 ? 's' : ''}';
              return _quizPreviewItem(title, quiz['description'] ?? 'General', info, Colors.blue);
            }),
        ],
      ),
    );
  }

  Widget _quizPreviewItem(String title, String subject, String info, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.quiz, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1a2b4a))),
                Text(info, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Text(subject, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
        ],
      ),
    );
  }

  // ==================== ATTENDANCE SUMMARY ====================
Widget _buildAttendanceSummary() {
  int present = 0;
  int late = 0;
  int absent = 0;
  
  // Debug: print records count
  print('📊 Attendance records count: ${_attendanceRecords.length}');
  for (var r in _attendanceRecords) {
    print('📊 Record: ${r['date']} - ${r['status']}');
  }

  for (var record in _attendanceRecords) {
    final status = record['status'] ?? 'Absent';
    if (status == 'Present') {
      present++;
    } else if (status == 'Late') {
      late++;
    } else {
      absent++;
    }
  }

  int total = present + late + absent;
  double rate = total > 0 ? (present / total) * 100 : 0;

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
          'Attendance Summary',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1a2b4a)),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _attendanceStat('Present', present.toString(), Colors.green)),
            Expanded(child: _attendanceStat('Late', late.toString(), Colors.orange)),
            Expanded(child: _attendanceStat('Absent', absent.toString(), Colors.red)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: total > 0 ? present / total : 0,
          backgroundColor: Colors.grey.shade200,
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
          minHeight: 6,
        ),
        const SizedBox(height: 4),
        Text(
          '${rate.toStringAsFixed(1)}% attendance rate',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        if (_attendanceRecords.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'No attendance records found. Please check with your teacher.',
              style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
            ),
          ),
      ],
    ),
  );
}

  Widget _attendanceStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      ],
    );
  }

  // ==================== ASSIGNMENTS PAGE ====================
  Widget _buildAssignments() {
    // Original assignments page – unchanged
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
                  const Text('Assignments', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1a2b4a))),
                  const SizedBox(height: 4),
                  Text('Track and manage your assignments', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                ],
              ),
              TextButton.icon(
                onPressed: _navigateToSubmissionStatus,
                icon: const Icon(Icons.history, size: 18),
                label: const Text('Submission History'),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFF0d2b5c)),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (_isLoadingAssignments)
            const Center(child: CircularProgressIndicator())
          else if (_assignments.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: const Column(
                children: [
                  Icon(Icons.assignment_turned_in, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No assignments yet'),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _assignments.length,
              itemBuilder: (context, index) {
                final assignment = _assignments[index];
                final isSubmitted = _isAssignmentSubmitted(assignment['id']);
                final submission = _getSubmission(assignment['id']);
                final submissionStatus = submission?['status'];
                final title = assignment['title'] ?? 'Untitled';
                final subject = assignment['subject'] ?? 'No Subject';
                final deadline = assignment['deadline_formatted'] ?? assignment['deadline'] ?? 'No deadline';
                final description = assignment['description'] ?? 'No description';
               return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _assignmentCard(
                    title,
                    subject,
                    deadline,
                    description,
                    isSubmitted: isSubmitted,
                    submissionStatus: submissionStatus,
                    assignmentId: assignment['id'].toString(),
                    assignmentTitle: title,
                    isActive: assignment['is_active'] == 1,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _assignmentCard(
    String title,
    String subject,
    String due,
    String description, {
    bool isSubmitted = false,
    String? submissionStatus,
    required String assignmentId,
    required String assignmentTitle,
    bool isActive = true,
  }) {
    String displayStatus;
    Color statusColor;
    IconData statusIcon;

    if (isSubmitted) {
      if (submissionStatus == 'Approved') {
        displayStatus = 'Approved';
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
      } else if (submissionStatus == 'Rejected') {
        displayStatus = 'Rejected';
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
      } else {
        displayStatus = 'Pending';
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
      }
    } else {
      if (isActive) {
        displayStatus = 'Active';
        statusColor = Colors.green;
        statusIcon = Icons.assignment;
      } else {
        displayStatus = 'Closed';
        statusColor = Colors.grey;
        statusIcon = Icons.lock;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: (isSubmitted ? Colors.green : Colors.blue).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isSubmitted ? Icons.check_circle : Icons.assignment,
                  color: isSubmitted ? Colors.green : Colors.blue,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF1a2b4a),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        subject,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      displayStatus,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Description ──
          Text(
            description,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          // ── Due date ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                due,
                style: TextStyle(
                  color: isActive && !isSubmitted ? Colors.red.shade400 : Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Action buttons ──
          Row(
            children: [
              Expanded(
                child: isSubmitted
                    ? OutlinedButton.icon(
                        onPressed: () {
                          final sub = _getSubmission(assignmentId);
                          showDialog(
                            context: context,
                            barrierDismissible: true,
                            barrierColor: Colors.black.withOpacity(0.5),
                            builder: (dialogContext) => Dialog(
                              backgroundColor: Colors.transparent,
                              elevation: 0,
                              insetPadding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 40,
                              ),
                              child: _SubmissionStatusModal(
                                submissions: sub != null ? [sub] : [],
                                assignments: _assignments,
                                singleView: true,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.visibility, size: 20),
                        label: const Text('View Submission'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0d2b5c),
                          side: const BorderSide(color: Color(0xFF0d2b5c)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: isActive
                            ? () => _navigateToSubmitAssignment(assignmentId, assignmentTitle)
                            : null,
                        icon: Icon(
                          isActive ? Icons.upload_file : Icons.lock,
                          size: 20,
                        ),
                        label: Text(
                          isActive ? 'Submit Assignment' : 'Closed',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isActive ? const Color(0xFF2563EB) : Colors.grey,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
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

  String _formatDateTimeForStudent(String dateTimeString) {
    if (dateTimeString.isEmpty || dateTimeString == 'No deadline') return 'No deadline';
    try {
      if (dateTimeString.contains('AM') || dateTimeString.contains('PM')) {
        return dateTimeString;
      }
      final dateTime = DateTime.parse(dateTimeString);
      final phTime = dateTime.toLocal();
      final hour = phTime.hour;
      final minute = phTime.minute;
      final amPm = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return '${phTime.year}-${phTime.month.toString().padLeft(2, '0')}-${phTime.day.toString().padLeft(2, '0')} $displayHour:${minute.toString().padLeft(2, '0')} $amPm';
    } catch (e) {
      return dateTimeString;
    }
  }

  // ==================== QUIZZES PAGE ====================
  Widget _buildQuizzes() {
    print('📊 _quizzes.length: ${_quizzes.length}');
    print('📊 _quizAttempts.length: ${_quizAttempts.length}');

    final completedQuizIds = _quizAttempts
        .map((a) => a['quiz_id']?.toString())
        .whereType<String>()
        .toSet();

    print('📊 completedQuizIds: $completedQuizIds');
    final available = _quizzes
        .where((q) {
          final id = q['id']?.toString();
          return id != null && !completedQuizIds.contains(id);
        })
        .toList();

    final completed = _quizzes
        .where((q) {
          final id = q['id']?.toString();
          return id != null && completedQuizIds.contains(id);
        })
        .toList();

    print('📊 available: ${available.length}, completed: ${completed.length}');

    return SingleChildScrollView(
      padding: EdgeInsets.all(_isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available Quizzes',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1a2b4a),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Take quizzes to test your knowledge',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 24),
          if (available.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('No available quizzes. You\'ve completed all! 🎉'),
              ),
            )
          else
            ...available.map((quiz) {
              final attempt = _quizAttempts.firstWhere(
                (a) => a['quiz_id']?.toString() == quiz['id']?.toString(),
                orElse: () => {},
              );
              final completed = attempt.isNotEmpty;
              final scoreText = completed
                  ? '${attempt['score_correct']}/${attempt['score_total']}'
                  : null;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _quizCard(
                  quiz['title']?.toString() ?? 'Quiz',
                  quiz['description']?.toString() ?? 'No description',
                  '${(quiz['questions'] as List).length} questions',
                  '',
                  Colors.blue,
                  completed,
                  score: scoreText,
                  quizId: quiz['id']?.toString() ?? '',
                ),
              );
            }),
          const SizedBox(height: 28),
          const Text(
            'Completed Quizzes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1a2b4a),
            ),
          ),
          const SizedBox(height: 16),
          if (completed.isEmpty)
            const Text(
              'No completed quizzes yet.',
              style: TextStyle(color: Colors.grey),
            )
          else
            ...completed.map((quiz) {
              final attempt = _quizAttempts.firstWhere(
                (a) => a['quiz_id']?.toString() == quiz['id']?.toString(),
              );
              final scoreText =
                  '${attempt['score_correct']}/${attempt['score_total']}';
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _quizCard(
                  quiz['title']?.toString() ?? 'Quiz',
                  quiz['description']?.toString() ?? '',
                  '${(quiz['questions'] as List).length} questions',
                  '',
                  Colors.green,
                  true,
                  score: scoreText,
                  quizId: quiz['id']?.toString() ?? '',
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _quizCard(
    String title,
    String subject,
    String info,
    String date,
    Color color,
    bool isCompleted, {
    String? score,
    required String quizId,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(isCompleted ? Icons.check_circle : Icons.quiz, color: isCompleted ? Colors.green : color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF1a2b4a))),
                const SizedBox(height: 4),
                Text(subject, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(info, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isCompleted && score != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text(score, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w700)),
                )
              else
                Text(date, style: TextStyle(color: Colors.red.shade400, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: isCompleted
                    ? () {
                        final quizData = _getQuizById(quizId);
                        final attempt = _quizAttempts.firstWhere(
                          (a) => a['quiz_id']?.toString() == quizId,
                          orElse: () => {},
                        );
                        if (quizData != null && attempt.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => QuizResultPage(
                                quiz: quizData,
                                attempt: attempt,
                              ),
                            ),
                          );
                        }
                      }
                    : () {
                        final quiz = _getQuizById(quizId);
                        if (quiz != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => QuizTakePage(
                                quiz: quiz,
                                studentEmail: _authService.currentUserEmail ?? 'student',
                                studentName: _authService.currentUserName ?? 'Student',
                              ),
                            ),
                          ).then((_) => _loadStudentQuizAttempts());
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCompleted ? const Color(0xFF0d2b5c) : color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  elevation: 0,
                ),
                child: Text(isCompleted ? 'Review' : 'Start', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== ATTENDANCE PAGE ====================
Widget _buildAttendance() {
  int present = 0;
  int late = 0;
  int absent = 0;

  // Debug: I-print ang lahat ng records
  print('📊 _attendanceRecords count: ${_attendanceRecords.length}');
  for (var r in _attendanceRecords) {
    print('📊 Record: ${r['date']} - ${r['status']} - displayDate: ${r['displayDate']}');
  }

  for (var record in _attendanceRecords) {
    final status = record['status'] ?? 'Absent';
    if (status == 'Present') {
      present++;
    } else if (status == 'Late') late++;
    else absent++;
  }

  int total = present + late + absent;
  double rate = total > 0 ? (present / total) * 100 : 0;

  final todayKey = DateTime.now().toLocal().toString().split(' ')[0];

  return RefreshIndicator(
    onRefresh: _loadAttendanceData,
    child: SingleChildScrollView(
      padding: EdgeInsets.all(_isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Attendance Record',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1a2b4a)),
          ),
          const SizedBox(height: 4),
          Text(
            'Your attendance history (Present, Late, Absent)',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                _attendanceBigStat(present.toString(), 'Present', Colors.green),
                _attendanceBigStat(late.toString(), 'Late', Colors.orange),
                _attendanceBigStat(absent.toString(), 'Absent', Colors.red),
                _attendanceBigStat('${rate.toStringAsFixed(1)}%', 'Rate', const Color(0xFF0d2b5c)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Daily Attendance Log',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1a2b4a)),
              ),
              if (_attendanceRecords.any((r) => r['date'] == todayKey))
                Builder(
                  builder: (context) {
                    final todayRecord = _attendanceRecords.firstWhere(
                      (r) => r['date'] == todayKey,
                      orElse: () => {},
                    );
                    final todayStatus = todayRecord['status'] ?? 'Absent';
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: todayStatus == 'Present'
                            ? Colors.green.withOpacity(0.1)
                            : todayStatus == 'Late'
                                ? Colors.orange.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            todayStatus == 'Present'
                                ? Icons.check_circle
                                : todayStatus == 'Late'
                                    ? Icons.access_time
                                    : Icons.cancel,
                            color: todayStatus == 'Present'
                                ? Colors.green
                                : todayStatus == 'Late'
                                    ? Colors.orange
                                    : Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Today: $todayStatus',
                            style: TextStyle(
                              color: todayStatus == 'Present'
                                  ? Colors.green
                                  : todayStatus == 'Late'
                                      ? Colors.orange
                                      : Colors.red,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'No record today',
                    style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_attendanceRecords.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  'No attendance records found.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _attendanceRecords.length,
              itemBuilder: (context, index) {
                final record = _attendanceRecords[index];
                final status = record['status'] ?? 'Absent';
                
                // ✅ GAMITIN ANG 'date' DIRECTLY, HINDI 'displayDate'
                final date = record['date'] ?? 'No date';
                final isToday = date == todayKey;

                Color statusColor;
                IconData statusIcon;
                if (status == 'Present') {
                  statusColor = Colors.green;
                  statusIcon = Icons.check_circle;
                } else if (status == 'Late') {
                  statusColor = Colors.orange;
                  statusIcon = Icons.access_time;
                } else {
                  statusColor = Colors.red;
                  statusIcon = Icons.cancel;
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: isToday ? 3 : 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isToday ? BorderSide(color: statusColor, width: 2) : BorderSide.none,
                  ),
                  child: ListTile(
                    leading: Icon(statusIcon, color: statusColor, size: 28),
                    title: Text(
                      date,  // ✅ DATE LUMALABAS DITO
                      style: TextStyle(
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        color: isToday ? statusColor : Colors.black87,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        if (isToday) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Today',
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    ),
  );
}

  Widget _attendanceBigStat(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        ],
      ),
    );
  }

  // ==================== ANNOUNCEMENTS PAGE ====================
    Widget _buildAnnouncements() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(_isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Announcements', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1a2b4a))),
          const SizedBox(height: 4),
          Text('Stay updated with school news', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          const SizedBox(height: 24),
          if (_announcements.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Icons.announcement_outlined, size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text('No announcements yet', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                  ],
                ),
              ),
            )
          else
            for (int i = 0; i < _announcements.length; i++)
              Column(
                children: [
                  _announcementCard(
                    _announcements[i]['title'] ?? 'Announcement',
                    _announcements[i]['content'] ?? '',
                    _announcements[i]['created_at']?.toString().split(' ')[0] ?? 'Recently',
                    _announcements[i]['color'] ?? 'blue',
                    !_readAnnouncementIds.contains(_announcements[i]['id'].toString()),
                    _announcements[i]['id'].toString(),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
        ],
      ),
    );
  }

  Widget _announcementCard(String title, String content, String date, String colorValue, bool isNew, String id) {
    Color color = colorValue == 'blue'
        ? Colors.blue
        : (colorValue == 'green' ? Colors.green : Colors.orange);

    return GestureDetector(
      onTap: () => _markAnnouncementAsRead(id),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isNew ? color.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isNew ? color.withValues(alpha: 0.3) : const Color(0xFFE2E8F0)),
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
                      Text(date, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                if (isNew)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Text('NEW', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(content, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.5)),
          ],
        ),
      ),
    );
  }
}

  // ==================== SUBMIT ASSIGNMENT MODAL ====================
  class _SubmitAssignmentModal extends StatefulWidget {
    final String assignmentId;
    final String assignmentTitle;
    final Future<void> Function(
      String comment,
      String fileName,
      Uint8List? fileBytes,
    ) onSubmit;

    const _SubmitAssignmentModal({
      required this.assignmentId,
      required this.assignmentTitle,
      required this.onSubmit,
    });

    @override
    State<_SubmitAssignmentModal> createState() => _SubmitAssignmentModalState();
    }

  class _SubmitAssignmentModalState extends State<_SubmitAssignmentModal> {
    final TextEditingController _commentController = TextEditingController();
    String? _selectedFileName;
    Uint8List? _selectedFileBytes;
    bool _isSubmitting = false;
    bool _isDragging = false;
    String? _errorMessage;

    @override
    void dispose() {
      _commentController.dispose();
      super.dispose();
    }

    String _formatFileSize(int bytes) {
      if (bytes <= 0) return '0 B';
      const suffixes = ['B', 'KB', 'MB', 'GB'];
      int index = 0;
      double size = bytes.toDouble();
      while (size > 1024 && index < suffixes.length - 1) {
        size /= 1024;
        index++;
      }
      return '${size.toStringAsFixed(1)} ${suffixes[index]}';
    }

    String _getFileExtension() {
      if (_selectedFileName == null) return '';
      final parts = _selectedFileName!.split('.');
      return parts.length > 1 ? parts.last.toUpperCase() : '';
    }

    IconData _getFileIcon() {
      final ext = _getFileExtension().toLowerCase();
      switch (ext) {
        case 'pdf': return Icons.picture_as_pdf;
        case 'doc':
        case 'docx': return Icons.description;
        case 'ppt':
        case 'pptx': return Icons.slideshow;
        case 'jpg':
        case 'jpeg':
        case 'png':
        case 'gif': return Icons.image;
        case 'txt': return Icons.text_snippet;
        default: return Icons.insert_drive_file;
      }
    }

    Color _getFileIconColor() {
      final ext = _getFileExtension().toLowerCase();
      switch (ext) {
        case 'pdf': return const Color(0xFFD85A30);
        case 'doc':
        case 'docx': return Colors.blue;
        case 'ppt':
        case 'pptx': return Colors.orange;
        case 'jpg':
        case 'jpeg':
        case 'png':
        case 'gif': return Colors.purple;
        default: return Colors.grey;
      }
    }

    String _getShortMimeType() {
      final ext = _getFileExtension().toLowerCase();
      switch (ext) {
        case 'pdf': return 'PDF';
        case 'doc': return 'DOC';
        case 'docx': return 'DOCX';
        case 'ppt': return 'PPT';
        case 'pptx': return 'PPTX';
        case 'jpg':
        case 'jpeg': return 'JPEG';
        case 'png': return 'PNG';
        case 'txt': return 'TXT';
        default: return _getFileExtension();
      }
    }

    Future<void> _pickFile() async {
      try {
        final result = await FilePicker.platform.pickFiles(
          withData: true,
          type: FileType.custom,
          allowedExtensions: [
            'pdf', 'doc', 'docx', 'ppt', 'pptx',
            'txt', 'jpg', 'png', 'jpeg',
          ],
        );
        if (result != null && result.files.isNotEmpty) {
          final picked = result.files.first;
          setState(() {
            _selectedFileName = picked.name;
            _selectedFileBytes = picked.bytes;
            _isDragging = false;
            _errorMessage = null;
          });
        }
      } catch (e) {
        setState(() => _errorMessage = 'Error picking file: ${e.toString()}');
      }
    }

    @override
Widget build(BuildContext context) {
  return Container(
    width: 580,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 30,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,  // ✅ ETO ANG SUSI — hindi nag-scroll
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ===== HEADER =====
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
                Icons.assignment_outlined,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Submit Assignment',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Upload your completed assignment',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
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

        // ===== ASSIGNMENT DETAILS =====
        const Text(
          'Assignment Details',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0d2b5c),
          ),
        ),
        const SizedBox(height: 12),

        // Assignment Title - read-only
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0d2b5c).withOpacity(0.06),
            border: Border.all(
              color: const Color(0xFF0d2b5c).withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Icon(
                Icons.assignment,
                color: Color(0xFF0d2b5c),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assignment',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0d2b5c).withOpacity(0.6),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.assignmentTitle,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0d2b5c),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF0d2b5c).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Auto-filled',
                  style: TextStyle(
                    fontSize: 10,
                    color: const Color(0xFF0d2b5c).withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Comment Field
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _commentController,
            decoration: const InputDecoration(
              labelText: 'Add Comment / Note (optional)',
              hintText: 'e.g., "I have attached my solution in PDF format"',
              prefixIcon: Icon(
                Icons.comment,
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
            maxLines: 2,  // ✅ BINABO NG 2 PARA HINDI MASYADONG MALAKI
          ),
        ),
        const SizedBox(height: 20),

        // ===== FILE SELECTION =====
        const Text(
          'Select File',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0d2b5c),
          ),
        ),
        const SizedBox(height: 12),

        // Drag and Drop File Selection
        GestureDetector(
          onTap: _pickFile,
          child: Container(
            height: 130,  // ✅ BINABA ng 130 para kasya
            decoration: BoxDecoration(
              border: Border.all(
                color: _isDragging
                    ? const Color(0xFF0d2b5c)
                    : (_selectedFileName != null
                        ? const Color(0xFF0d2b5c)
                        : Colors.grey.shade300),
                width: _isDragging ? 3 : 2,
              ),
              borderRadius: BorderRadius.circular(12),
              color: _isDragging
                  ? const Color(0xFF0d2b5c).withOpacity(0.1)
                  : (_selectedFileName != null
                      ? const Color(0xFF0d2b5c).withOpacity(0.03)
                      : Colors.grey.shade50),
            ),
            child: Center(
              child: _selectedFileName == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isDragging
                              ? Icons.cloud_download_outlined
                              : Icons.cloud_upload_outlined,
                          size: 40,
                          color: _isDragging
                              ? const Color(0xFF0d2b5c)
                              : const Color(0xFF0d2b5c).withOpacity(0.6),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isDragging
                              ? 'Drop file here'
                              : 'Drag & Drop or Click to Select',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF0d2b5c),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'PDF, DOC, DOCX, PPT, PPTX, TXT, JPG, PNG',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _getFileIconColor().withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _getFileIcon(),
                              size: 24,
                              color: _getFileIconColor(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _selectedFileName!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      _formatFileSize(
                                        _selectedFileBytes?.length ?? 0,
                                      ),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 3,
                                      height: 3,
                                      decoration: const BoxDecoration(
                                        color: Colors.grey,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _getShortMimeType(),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    border: Border.all(
                                      color: Colors.green.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Ready to upload',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedFileName = null;
                                _selectedFileBytes = null;
                              });
                            },
                            child: Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Error Message
        if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              border: Border.all(color: Colors.red.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),

        // ===== SUBMIT BUTTON =====
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            onPressed: _isSubmitting
                ? null
                : () async {
                    if (_selectedFileName == null ||
                        _selectedFileBytes == null) {
                      setState(
                        () => _errorMessage =
                            'Please select a file to upload.',
                      );
                      return;
                    }
                    setState(() {
                      _isSubmitting = true;
                      _errorMessage = null;
                    });
                    await widget.onSubmit(
                      _commentController.text,
                      _selectedFileName!,
                      _selectedFileBytes,
                    );
                    if (mounted) setState(() => _isSubmitting = false);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0d2b5c),
              disabledBackgroundColor: Colors.grey.shade300,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
            ),
            child: _isSubmitting
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Submitting...',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 18,
                        color: Colors.white,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Submit Assignment',
                        style: TextStyle(
                          fontSize: 14,
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
}
  }

  // ==================== SUBMISSION STATUS MODAL ====================
  class _SubmissionStatusModal extends StatelessWidget {
    final List<Map<String, dynamic>> submissions;
    final List<Map<String, dynamic>> assignments;
    final bool singleView;

    const _SubmissionStatusModal({
      required this.submissions,
      required this.assignments,
      this.singleView = false,
    });

    String _formatDateTime(String isoString) {
      try {
        final dateTime = DateTime.parse(isoString);
        return '${_monthAbbr(dateTime.month)} ${dateTime.day}, ${dateTime.year} ${_formatTime(dateTime)}';
      } catch (e) {
        return isoString;
      }
    }

    String _monthAbbr(int month) {
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return months[month - 1];
    }

    String _formatTime(DateTime dt) {
      int hour = dt.hour;
      int minute = dt.minute;
      String period = hour >= 12 ? 'PM' : 'AM';
      int displayHour = hour % 12;
      if (displayHour == 0) displayHour = 12;
      return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
    }

    String _getAssignmentTitle(String assignmentId) {
      try {
        final assignment = assignments.firstWhere(
          (a) => a['id'].toString() == assignmentId,
        );
        return assignment['title'] ?? 'Unknown';
      } catch (e) {
        return 'Unknown';
      }
    }

    String _formatFileSize(dynamic size) {
      final sizeInBytes =
          size is int ? size : int.tryParse(size?.toString() ?? '0') ?? 0;
      if (sizeInBytes < 1024) return '$sizeInBytes B';
      if (sizeInBytes < 1024 * 1024) {
        return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
      }
      return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }

    void _close(BuildContext context) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    double _calcHeight() {
      if (submissions.isEmpty) return 320;
      double base = 220; // header + close button + padding
      for (var sub in submissions) {
        final hasFeedback = (sub['feedback'] ?? '').toString().isNotEmpty;
        base += hasFeedback ? 210 : 165;
      }
      return base.clamp(300, 650);
    }

    @override
    Widget build(BuildContext context) {
      return Container(
        width: 580,
        height: _calcHeight(),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ===== HEADER =====
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
                    Icons.assignment_turned_in_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          singleView
                              ? 'Submission Details'
                              : 'Submission History',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          singleView
                              ? 'View your submitted work'
                              : 'Track all your submitted assignments',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // X close button
                  GestureDetector(
                    onTap: () => _close(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
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
            const SizedBox(height: 16),

            // ===== CONTENT =====
            Expanded(
              child: submissions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.folder_open,
                            size: 56,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No submissions yet',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: submissions.map((submission) {
                        final status = submission['status'] ?? 'Pending';
                        final isApproved = status == 'Approved';
                        final isPending = status == 'Pending';

                        Color statusColor = isPending
                            ? Colors.orange
                            : isApproved
                                ? Colors.green
                                : Colors.red;
                        IconData statusIcon = isPending
                            ? Icons.pending_outlined
                            : isApproved
                                ? Icons.check_circle_outline
                                : Icons.cancel_outlined;

                        final assignmentTitle = _getAssignmentTitle(
                          submission['assignment_id']?.toString() ?? '',
                        );
                        final fileName = submission['file_name'] ?? 'No file';
                        final comment = submission['comment'] ?? '';
                        final feedback = submission['feedback'] ?? '';
                        final submittedAtRaw = submission['submitted_at'] ??
                            DateTime.now().toIso8601String();
                        final submittedAt =
                            submission['submitted_at_formatted'] ??
                                _formatDateTime(submittedAtRaw);
                        final fileSize =
                            _formatFileSize(submission['file_size'] ?? 0);
                        final hasFeedback = feedback.isNotEmpty;

                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title + status badge
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      statusIcon,
                                      color: statusColor,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          assignmentTitle,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1a2b4a),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color:
                                                  statusColor.withOpacity(0.3),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(statusIcon,
                                                  size: 12,
                                                  color: statusColor),
                                              const SizedBox(width: 4),
                                              Text(
                                                status,
                                                style: TextStyle(
                                                  color: statusColor,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(
                                  height: 1, color: Color(0xFFE2E8F0)),
                              const SizedBox(height: 10),

                              // Info rows
                              _infoRow(
                                Icons.insert_drive_file_outlined,
                                'File',
                                '$fileName ($fileSize)',
                                Colors.blue,
                              ),
                              const SizedBox(height: 6),
                              _infoRow(
                                Icons.comment_outlined,
                                'Comment',
                                comment.trim().isEmpty
                                    ? 'No comment'
                                    : comment,
                                Colors.grey.shade600,
                              ),
                              const SizedBox(height: 6),
                              _infoRow(
                                Icons.calendar_today_outlined,
                                'Submitted',
                                submittedAt,
                                Colors.grey.shade600,
                              ),

                              // Feedback
                              if (hasFeedback) ...[
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.blue.shade200),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.feedback_outlined,
                                          size: 15,
                                          color: Colors.blue.shade700),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Teacher Feedback',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.blue.shade700,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              feedback,
                                              style: TextStyle(
                                                color: Colors.blue.shade800,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 12),

            // ===== CLOSE BUTTON =====
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () => _close(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0d2b5c),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget _infoRow(IconData icon, String label, String value, Color color) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      );
    }
  }
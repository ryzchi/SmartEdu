import 'package:flutter/material.dart';
import 'package:smartedu/security_service/auth_service.dart';

class TeacherDashboardPage extends StatefulWidget {
  const TeacherDashboardPage({super.key});

  @override
  State<TeacherDashboardPage> createState() => _TeacherDashboardPageState();
}

class _TeacherDashboardPageState extends State<TeacherDashboardPage> {
  final _authService = AuthService();
  int _selectedIndex = 0;
  bool _isMobile = false;

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
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
          _drawerItem(Icons.description_outlined, 'Worksheets', 3),
          _drawerItem(Icons.grade_outlined, 'Grades', 4),
          _drawerItem(Icons.calendar_today_outlined, 'Attendance', 5),
          _drawerItem(Icons.announcement_outlined, 'Announcements', 6),
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
              children: [
                Image.asset('assets/capstonelogo.png', width: 40, height: 40),
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
          ),
          const SizedBox(height: 24),
          _sidebarItem(Icons.dashboard_outlined, 'Overview', 0),
          _sidebarItem(Icons.people_outline, 'Students', 1),
          _sidebarItem(Icons.upload_file_outlined, 'Lesson Plans', 2),
          _sidebarItem(Icons.description_outlined, 'Worksheets', 3),
          _sidebarItem(Icons.grade_outlined, 'Grades', 4),
          _sidebarItem(Icons.calendar_today_outlined, 'Attendance', 5),
          _sidebarItem(Icons.announcement_outlined, 'Announcements', 6),
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
        return _buildWorksheets();
      case 4:
        return _buildGrades();
      case 5:
        return _buildAttendance();
      case 6:
        return _buildAnnouncements();
      default:
        return _buildOverview();
    }
  }

  // ==================== OVERVIEW PANEL ====================
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
                        'Welcome, ${_authService.currentUserName ?? 'Teacher'}!',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Manage your classes and track student progress.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 30,
                  ),
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
                  _statCard(
                    'Total Students',
                    '42',
                    'Grade 10-A',
                    Colors.blue,
                    Icons.people,
                  ),
                  _statCard(
                    'Lesson Plans',
                    '8',
                    'This week',
                    Colors.green,
                    Icons.book,
                  ),
                  _statCard(
                    'Worksheets',
                    '12',
                    'Generated',
                    Colors.orange,
                    Icons.description,
                  ),
                  _statCard(
                    'Pending Grades',
                    '5',
                    'To review',
                    Colors.red,
                    Icons.grade,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 700) {
                return Column(
                  children: [
                    _buildClassOverview(),
                    const SizedBox(height: 16),
                    _buildRecentActivity(),
                    const SizedBox(height: 16),
                    _buildAttendanceSummary(),
                    const SizedBox(height: 16),
                    _buildAnnouncementsPreview(),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildClassOverview()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildRecentActivity()),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 700) {
                return const SizedBox.shrink();
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildAttendanceSummary()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildAnnouncementsPreview()),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    String title,
    String value,
    String subtitle,
    Color color,
    IconData icon,
  ) {
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
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1a2b4a),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }

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
        children: [
          const Text(
            'Class Overview',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1a2b4a),
            ),
          ),
          const SizedBox(height: 16),
          _classStat('Average Grade', '84%', Colors.blue, 0.84),
          const SizedBox(height: 12),
          _classStat('Attendance Rate', '92%', Colors.green, 0.92),
          const SizedBox(height: 12),
          _classStat('Assignment Completion', '78%', Colors.orange, 0.78),
          const SizedBox(height: 12),
          _classStat('Quiz Average', '81%', Colors.purple, 0.81),
        ],
      ),
    );
  }

  Widget _classStat(String label, String value, Color color, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF1a2b4a)),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
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
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1a2b4a),
            ),
          ),
          const SizedBox(height: 12),
          _activityItem(
            'Graded Math Quiz',
            '35 students',
            '2 hours ago',
            Colors.blue,
          ),
          const Divider(),
          _activityItem(
            'Uploaded Lesson Plan',
            'Science - Cell Biology',
            '5 hours ago',
            Colors.green,
          ),
          const Divider(),
          _activityItem(
            'Generated Worksheet',
            'English - Grammar',
            'Yesterday',
            Colors.orange,
          ),
          const Divider(),
          _activityItem(
            'Updated Attendance',
            'Oct 25, 2024',
            'Yesterday',
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _activityItem(String action, String detail, String time, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFF1a2b4a),
                  ),
                ),
                Text(
                  detail,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceSummary() {
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
            'Today\'s Attendance',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1a2b4a),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _attendanceStat('38', 'Present', Colors.green)),
              Expanded(child: _attendanceStat('3', 'Late', Colors.orange)),
              Expanded(child: _attendanceStat('1', 'Absent', Colors.red)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(() => _selectedIndex = 5),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0d2b5c),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Take Attendance',
                style: TextStyle(fontSize: 13),
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
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
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

  Widget _buildAnnouncementsPreview() {
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
              const Text(
                'Announcements',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1a2b4a),
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _selectedIndex = 6),
                child: const Text(
                  'Manage',
                  style: TextStyle(color: Color(0xFF007bff), fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _announcementPreviewItem(
            'Midterm Exam Schedule',
            'Oct 25, 2024',
            true,
          ),
          const Divider(),
          _announcementPreviewItem('Science Fair 2024', 'Oct 24, 2024', true),
          const Divider(),
          _announcementPreviewItem(
            'Semestral Break Notice',
            'Oct 20, 2024',
            false,
          ),
        ],
      ),
    );
  }

  Widget _announcementPreviewItem(String title, String date, bool isNew) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (isNew)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            )
          else
            const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xFF1a2b4a),
              ),
            ),
          ),
          Text(
            date,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ==================== STUDENTS PAGE ====================
  Widget _buildStudentList() {
    final students = [
      {
        'name': 'Juan Dela Cruz',
        'id': '2024-0001',
        'grade': 'Grade 10-A',
        'avg': '92%',
        'attendance': '95%',
      },
      {
        'name': 'Maria Santos',
        'id': '2024-0002',
        'grade': 'Grade 10-A',
        'avg': '95%',
        'attendance': '98%',
      },
      {
        'name': 'Pedro Reyes',
        'id': '2024-0003',
        'grade': 'Grade 10-A',
        'avg': '78%',
        'attendance': '85%',
      },
      {
        'name': 'Ana Garcia',
        'id': '2024-0004',
        'grade': 'Grade 10-A',
        'avg': '88%',
        'attendance': '92%',
      },
      {
        'name': 'Jose Lim',
        'id': '2024-0005',
        'grade': 'Grade 10-A',
        'avg': '85%',
        'attendance': '90%',
      },
      {
        'name': 'Carmen Tan',
        'id': '2024-0006',
        'grade': 'Grade 10-A',
        'avg': '91%',
        'attendance': '96%',
      },
      {
        'name': 'Miguel Cruz',
        'id': '2024-0007',
        'grade': 'Grade 10-A',
        'avg': '73%',
        'attendance': '80%',
      },
      {
        'name': 'Sofia Reyes',
        'id': '2024-0008',
        'grade': 'Grade 10-A',
        'avg': '96%',
        'attendance': '100%',
      },
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.all(_isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Student List',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1a2b4a),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Student'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0d2b5c),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search students...',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
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
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'ID',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (!_isMobile)
                        Expanded(
                          child: Text(
                            'Attendance',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          'Average',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 60),
                    ],
                  ),
                ),
                ...students.map((s) => _studentRow(s)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _studentRow(Map<String, String> student) {
    final avg = int.parse(student['avg']!.replaceAll('%', ''));
    final color = avg >= 90
        ? Colors.green
        : avg >= 80
        ? Colors.blue
        : avg >= 75
        ? Colors.orange
        : Colors.red;

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
                    student['name']![0],
                    style: const TextStyle(
                      color: Color(0xFF0d2b5c),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  student['name']!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1a2b4a),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              student['id']!,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          if (!_isMobile)
            Expanded(
              child: Text(
                student['attendance']!,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                student['avg']!,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 60,
            child: IconButton(
              icon: const Icon(
                Icons.more_vert,
                size: 18,
                color: Color(0xFF94A3B8),
              ),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  // ==================== LESSON PLANS PAGE ====================
  Widget _buildLessonPlans() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(_isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Lesson Plans',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1a2b4a),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('Upload New'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0d2b5c),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _lessonPlanCard(
                'Quadratic Equations',
                'Mathematics',
                'Grade 10',
                'Oct 25, 2024',
                'PDF',
                Colors.blue,
              ),
              _lessonPlanCard(
                'Cell Division',
                'Science',
                'Grade 10',
                'Oct 28, 2024',
                'PDF',
                Colors.green,
              ),
              _lessonPlanCard(
                'Philippine Literature',
                'Filipino',
                'Grade 10',
                'Nov 2, 2024',
                'DOCX',
                Colors.orange,
              ),
              _lessonPlanCard(
                'World War II',
                'History',
                'Grade 10',
                'Nov 5, 2024',
                'PDF',
                Colors.red,
              ),
              _lessonPlanCard(
                'Grammar Review',
                'English',
                'Grade 10',
                'Nov 8, 2024',
                'DOCX',
                Colors.teal,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _lessonPlanCard(
    String title,
    String subject,
    String grade,
    String date,
    String format,
    Color color,
  ) {
    return Container(
      width: _isMobile ? double.infinity : 320,
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  format,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(
                  Icons.more_vert,
                  size: 18,
                  color: Color(0xFF94A3B8),
                ),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF1a2b4a),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subject,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
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
              const SizedBox(width: 16),
              Icon(Icons.grade, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Text(
                grade,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('View', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0d2b5c),
                    side: const BorderSide(color: Color(0xFF0d2b5c)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Download', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
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

  // ==================== WORKSHEETS PAGE ====================
  Widget _buildWorksheets() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(_isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Generated Worksheets',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1a2b4a),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Generate New'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0d2b5c),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0d2b5c).withOpacity(0.03),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Generate New Worksheet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1a2b4a),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _dropdownField('Subject', [
                      'Mathematics',
                      'Science',
                      'English',
                      'Filipino',
                      'History',
                    ]),
                    _dropdownField('Grade Level', [
                      'Grade 7',
                      'Grade 8',
                      'Grade 9',
                      'Grade 10',
                    ]),
                    _dropdownField('Topic', [
                      'Algebra',
                      'Geometry',
                      'Statistics',
                      'Calculus',
                    ]),
                    _dropdownField('Difficulty', ['Easy', 'Medium', 'Hard']),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(
                      width: 200,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Number of items',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.auto_awesome, size: 18),
                      label: const Text('Generate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0d2b5c),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
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
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Recent Worksheets',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1a2b4a),
            ),
          ),
          const SizedBox(height: 16),
          _worksheetCard(
            'Algebra Practice Set A',
            'Mathematics',
            'Grade 10',
            '20 items',
            'Oct 24, 2024',
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _worksheetCard(
            'Cell Biology Review',
            'Science',
            'Grade 10',
            '15 items',
            'Oct 22, 2024',
            Colors.green,
          ),
          const SizedBox(height: 12),
          _worksheetCard(
            'Verb Tenses Exercise',
            'English',
            'Grade 10',
            '25 items',
            'Oct 20, 2024',
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _dropdownField(String label, List<String> items) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(6),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                hint: Text(
                  'Select $label',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                ),
                isExpanded: true,
                items: items
                    .map(
                      (i) => DropdownMenuItem(
                        value: i,
                        child: Text(i, style: const TextStyle(fontSize: 13)),
                      ),
                    )
                    .toList(),
                onChanged: (v) {},
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _worksheetCard(
    String title,
    String subject,
    String grade,
    String items,
    String date,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.description, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1a2b4a),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      subject,
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('•', style: TextStyle(color: Colors.grey.shade400)),
                    const SizedBox(width: 12),
                    Text(
                      grade,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('•', style: TextStyle(color: Colors.grey.shade400)),
                    const SizedBox(width: 12),
                    Text(
                      items,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            date,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(
              Icons.download,
              size: 18,
              color: Color(0xFF94A3B8),
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.print, size: 18, color: Color(0xFF94A3B8)),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  // ==================== GRADES PAGE ====================
  Widget _buildGrades() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(_isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Grades & Scores',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1a2b4a),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        hint: const Text(
                          'Select Subject',
                          style: TextStyle(fontSize: 13),
                        ),
                        items:
                            [
                                  'Mathematics',
                                  'Science',
                                  'English',
                                  'Filipino',
                                  'History',
                                ]
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(
                                      s,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) {},
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Grade'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0d2b5c),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
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
                          'Student',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Quiz 1',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Quiz 2',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Exam',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Project',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Average',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
                _gradeRow('Juan Dela Cruz', '85', '90', '88', '92', '88.75'),
                _gradeRow('Maria Santos', '95', '92', '96', '94', '94.25'),
                _gradeRow('Pedro Reyes', '72', '75', '78', '80', '76.25'),
                _gradeRow('Ana Garcia', '88', '85', '90', '87', '87.50'),
                _gradeRow('Jose Lim', '80', '82', '85', '88', '83.75'),
                _gradeRow('Carmen Tan', '92', '94', '91', '95', '93.00'),
                _gradeRow('Miguel Cruz', '68', '70', '72', '75', '71.25'),
                _gradeRow('Sofia Reyes', '98', '96', '97', '99', '97.50'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Container(
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
                        'Class Performance',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1a2b4a),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _performanceBar('A (90-100)', 3, Colors.green),
                      const SizedBox(height: 8),
                      _performanceBar('B (80-89)', 3, Colors.blue),
                      const SizedBox(height: 8),
                      _performanceBar('C (75-79)', 2, Colors.orange),
                      const SizedBox(height: 8),
                      _performanceBar('D (Below 75)', 1, Colors.red),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Container(
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
                        'Quick Grade Entry',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1a2b4a),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Student Name or ID',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          filled: true,
                          fillColor: const Color(0xFFF8F9FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Score',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF8F9FA),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Total',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF8F9FA),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0d2b5c),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            elevation: 0,
                          ),
                          child: const Text('Submit Grade'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _gradeRow(
    String name,
    String q1,
    String q2,
    String exam,
    String proj,
    String avg,
  ) {
    final average = double.parse(avg);
    final color = average >= 90
        ? Colors.green
        : average >= 80
        ? Colors.blue
        : average >= 75
        ? Colors.orange
        : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF1a2b4a),
              ),
            ),
          ),
          Expanded(
            child: Text(q1, style: TextStyle(color: Colors.grey.shade700)),
          ),
          Expanded(
            child: Text(q2, style: TextStyle(color: Colors.grey.shade700)),
          ),
          Expanded(
            child: Text(exam, style: TextStyle(color: Colors.grey.shade700)),
          ),
          Expanded(
            child: Text(proj, style: TextStyle(color: Colors.grey.shade700)),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                avg,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: IconButton(
              icon: const Icon(Icons.edit, size: 16, color: Color(0xFF94A3B8)),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _performanceBar(String label, int count, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: count / 8,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$count',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  // ==================== ATTENDANCE PAGE ====================
  Widget _buildAttendance() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(_isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Attendance Management',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1a2b4a),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Track and manage student attendance',
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
            child: Column(
              children: [
                Row(
                  children: [
                    _attendanceBigStat('38', 'Present', Colors.green),
                    _attendanceBigStat('3', 'Late', Colors.orange),
                    _attendanceBigStat('1', 'Absent', Colors.red),
                    _attendanceBigStat('90%', 'Rate', const Color(0xFF0d2b5c)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
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
                    const Text(
                      'Today\'s Attendance - Oct 25, 2024',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1a2b4a),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.save, size: 18),
                      label: const Text('Save'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0d2b5c),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _attendanceStudentRow(
                  'Juan Dela Cruz',
                  '2024-0001',
                  true,
                  false,
                  false,
                ),
                _attendanceStudentRow(
                  'Maria Santos',
                  '2024-0002',
                  true,
                  false,
                  false,
                ),
                _attendanceStudentRow(
                  'Pedro Reyes',
                  '2024-0003',
                  false,
                  true,
                  false,
                ),
                _attendanceStudentRow(
                  'Ana Garcia',
                  '2024-0004',
                  true,
                  false,
                  false,
                ),
                _attendanceStudentRow(
                  'Jose Lim',
                  '2024-0005',
                  true,
                  false,
                  false,
                ),
                _attendanceStudentRow(
                  'Carmen Tan',
                  '2024-0006',
                  true,
                  false,
                  false,
                ),
                _attendanceStudentRow(
                  'Miguel Cruz',
                  '2024-0007',
                  false,
                  false,
                  true,
                ),
                _attendanceStudentRow(
                  'Sofia Reyes',
                  '2024-0008',
                  true,
                  false,
                  false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _attendanceBigStat(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _attendanceStudentRow(
    String name,
    String id,
    bool present,
    bool late,
    bool absent,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
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
                    name[0],
                    style: const TextStyle(
                      color: Color(0xFF0d2b5c),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      id,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _attendanceToggle('Present', present, Colors.green),
          _attendanceToggle('Late', late, Colors.orange),
          _attendanceToggle('Absent', absent, Colors.red),
        ],
      ),
    );
  }

  Widget _attendanceToggle(String label, bool isSelected, Color color) {
    return Expanded(
      child: InkWell(
        onTap: () {},
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey.shade600,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Announcements',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1a2b4a),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Announcement'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0d2b5c),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Create and manage class announcements',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 24),
          _teacherAnnouncementCard(
            'Midterm Exam Schedule',
            'The midterm examination will be held on November 15-20, 2024. All students must bring their school ID and examination permit. Please review the schedule posted on the bulletin board.',
            'Oct 25, 2024',
            Colors.blue,
            true,
            views: 42,
          ),
          const SizedBox(height: 12),
          _teacherAnnouncementCard(
            'Science Fair 2024',
            'Join us for the annual Science Fair on November 10, 2024. Students are encouraged to showcase their innovative projects. Registration deadline is November 5.',
            'Oct 24, 2024',
            Colors.green,
            true,
            views: 38,
          ),
          const SizedBox(height: 12),
          _teacherAnnouncementCard(
            'Semestral Break Notice',
            'Classes will be suspended from October 28 to November 3 for the semestral break. Classes will resume on November 4, 2024.',
            'Oct 20, 2024',
            Colors.orange,
            false,
            views: 42,
          ),
        ],
      ),
    );
  }

  Widget _teacherAnnouncementCard(
    String title,
    String content,
    String date,
    Color color,
    bool isActive, {
    required int views,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.announcement, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Color(0xFF1a2b4a),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Icon(Icons.visibility, size: 14, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text(
                    '$views',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  size: 18,
                  color: Color(0xFF94A3B8),
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '/security_service/auth_service.dart';

class StudentDashboardPage extends StatefulWidget {
  const StudentDashboardPage({super.key});

  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  final _authService = AuthService();
  int _selectedIndex = 0;
  bool _isMobile = false;

  final List<Map<String, String>> _demoAssignments = [
    {
      'title': 'Math Homework',
      'subject': 'Mathematics',
      'deadline': 'May 30, 2026',
      'description': 'Complete problems 1-20 on page 42.',
    },
    {
      'title': 'Science Project',
      'subject': 'Science',
      'deadline': 'June 2, 2026',
      'description': 'Build a simple volcano model and write a short report.',
    },
    {
      'title': 'English Essay',
      'subject': 'English',
      'deadline': 'June 5, 2026',
      'description': 'Write a 300-word essay on your favorite book.',
    },
  ];

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
            'Student Portal',
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
                    _authService.currentUserName ?? 'Student',
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
                  'Student Portal',
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
          _drawerItem(Icons.assignment_outlined, 'Assignments', 1),
          _drawerItem(Icons.quiz_outlined, 'Quizzes', 2),
          _drawerItem(Icons.calendar_today_outlined, 'Attendance', 3),
          _drawerItem(Icons.announcement_outlined, 'Announcements', 4),
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
                  'Student Portal',
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
          _sidebarItem(Icons.assignment_outlined, 'Assignments', 1),
          _sidebarItem(Icons.quiz_outlined, 'Quizzes', 2),
          _sidebarItem(Icons.calendar_today_outlined, 'Attendance', 3),
          _sidebarItem(Icons.announcement_outlined, 'Announcements', 4),
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
        return _buildAssignments();
      case 2:
        return _buildQuizzes();
      case 3:
        return _buildAttendance();
      case 4:
        return _buildAnnouncements();
      default:
        return _buildOverview();
    }
  }

  // ==================== OVERVIEW PANEL (SPRINT 2) ====================
  Widget _buildOverview() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(_isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Header
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
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Track your academic progress and stay updated with your classes.',
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

          // Stats Grid - Responsive
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
                    'Assignments',
                    '5',
                    'Pending',
                    Colors.orange,
                    Icons.assignment,
                  ),
                  _statCard(
                    'Quizzes',
                    '3',
                    'Available',
                    Colors.blue,
                    Icons.quiz,
                  ),
                  _statCard(
                    'Attendance',
                    '92%',
                    'Present',
                    Colors.green,
                    Icons.calendar_today,
                  ),
                  _statCard(
                    'Grade Average',
                    '87%',
                    'B+',
                    const Color(0xFF0d2b5c),
                    Icons.grade,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Two Column Layout - Responsive
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 700) {
                return Column(
                  children: [
                    _buildRecentAssignments(),
                    const SizedBox(height: 16),
                    _buildUpcomingQuizzes(),
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
                  Expanded(child: _buildRecentAssignments()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildUpcomingQuizzes()),
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

  Widget _buildRecentAssignments() {
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
                'Recent Assignments',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1a2b4a),
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _selectedIndex = 1),
                child: const Text(
                  'View All',
                  style: TextStyle(color: Color(0xFF007bff), fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _assignmentItem(
            'Math Problem Set',
            'Mathematics',
            'Due Oct 28',
            Colors.orange,
            0.75,
          ),
          const Divider(),
          _assignmentItem(
            'Science Lab Report',
            'Science',
            'Due Oct 30',
            Colors.green,
            0.30,
          ),
          const Divider(),
          _assignmentItem(
            'English Essay',
            'English',
            'Due Nov 2',
            Colors.blue,
            0.0,
          ),
        ],
      ),
    );
  }

  Widget _assignmentItem(
    String title,
    String subject,
    String due,
    Color color,
    double progress,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF1a2b4a),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subject,
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                due,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            borderRadius: BorderRadius.circular(4),
            minHeight: 6,
          ),
          const SizedBox(height: 4),
          Text(
            '${(progress * 100).toInt()}% complete',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingQuizzes() {
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
                'Upcoming Quizzes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1a2b4a),
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _selectedIndex = 2),
                child: const Text(
                  'View All',
                  style: TextStyle(color: Color(0xFF007bff), fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _quizPreviewItem(
            'Algebra Quiz',
            'Mathematics',
            'Oct 28, 10:00 AM',
            Colors.blue,
          ),
          const Divider(),
          _quizPreviewItem(
            'Cell Biology',
            'Science',
            'Oct 30, 1:00 PM',
            Colors.green,
          ),
          const Divider(),
          _quizPreviewItem(
            'Grammar Test',
            'English',
            'Nov 2, 9:00 AM',
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _quizPreviewItem(
    String title,
    String subject,
    String schedule,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.quiz, color: color, size: 20),
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
                    fontSize: 13,
                    color: Color(0xFF1a2b4a),
                  ),
                ),
                Text(
                  subject,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            schedule,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
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
            'Attendance Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1a2b4a),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _attendanceStat('Present', '23', Colors.green)),
              Expanded(child: _attendanceStat('Late', '2', Colors.orange)),
              Expanded(child: _attendanceStat('Absent', '1', Colors.red)),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'This Month',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1a2b4a),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: List.generate(26, (index) {
              final colors = [
                Colors.green,
                Colors.green,
                Colors.green,
                Colors.orange,
                Colors.green,
                Colors.green,
                Colors.red,
                Colors.green,
                Colors.green,
                Colors.green,
                Colors.orange,
                Colors.green,
                Colors.green,
                Colors.green,
                Colors.green,
                Colors.green,
                Colors.green,
                Colors.orange,
                Colors.green,
                Colors.green,
                Colors.green,
                Colors.green,
                Colors.green,
                Colors.green,
                Colors.green,
                Colors.green,
              ];
              return Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: colors[index],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _attendanceStat(String label, String value, Color color) {
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '2 New',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _announcementItem(
            'Midterm Exam Schedule',
            'The midterm examination will be held on November 15-20, 2024. Please prepare accordingly.',
            'Oct 25, 2024',
            true,
          ),
          const Divider(),
          _announcementItem(
            'Science Fair 2024',
            'Join us for the annual Science Fair on November 10. Register your projects by Nov 5.',
            'Oct 24, 2024',
            true,
          ),
          const Divider(),
          _announcementItem(
            'Holiday Break',
            'Classes will resume on November 4 after the semestral break.',
            'Oct 20, 2024',
            false,
          ),
        ],
      ),
    );
  }

  Widget _announcementItem(
    String title,
    String content,
    String date,
    bool isNew,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isNew)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 6, right: 8),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            )
          else
            const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFF1a2b4a),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== ASSIGNMENTS PAGE ====================
 Widget _buildAssignments() {
  return SingleChildScrollView(
    padding: EdgeInsets.all(_isMobile ? 16 : 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Assignments',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1a2b4a),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Track and manage your assignments',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        const SizedBox(height: 24),

        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _demoAssignments.length,
          itemBuilder: (context, index) {
            final doc = _demoAssignments[index];

            return Column(
              children: [
                _assignmentCard(
                  doc['title']!,
                  doc['subject'] ?? 'No Subject',
                  'Due ${doc['deadline']}',
                  doc['description'] ?? '',
                  0.0,
                  Colors.blue,
                ),
                const SizedBox(height: 12),
              ],
            );
          },
        )
      ],
    ),
  );
}

  Widget _assignmentCard(
    String title,
    String subject,
    String due,
    String description,
    double progress,
    Color color,
  ) {
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
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.assignment, color: color, size: 24),
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
                        fontSize: 15,
                        color: Color(0xFF1a2b4a),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subject,
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: progress == 1.0
                      ? Colors.green.withOpacity(0.1)
                      : progress > 0
                      ? Colors.orange.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  progress == 1.0
                      ? 'Completed'
                      : progress > 0
                      ? 'In Progress'
                      : 'Not Started',
                  style: TextStyle(
                    color: progress == 1.0
                        ? Colors.green
                        : progress > 0
                        ? Colors.orange
                        : Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            borderRadius: BorderRadius.circular(4),
            minHeight: 8,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).toInt()}% complete',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
              Text(
                due,
                style: TextStyle(
                  color: Colors.red.shade400,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== QUIZZES PAGE ====================
  Widget _buildQuizzes() {
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
          _quizCard(
            'Algebraic Expressions',
            'Mathematics',
            '15 items • 30 mins',
            'Oct 28, 2024',
            Colors.blue,
            false,
          ),
          const SizedBox(height: 12),
          _quizCard(
            'Cell Structure & Function',
            'Science',
            '20 items • 40 mins',
            'Oct 30, 2024',
            Colors.green,
            false,
          ),
          const SizedBox(height: 12),
          _quizCard(
            'Grammar & Composition',
            'English',
            '25 items • 45 mins',
            'Nov 2, 2024',
            Colors.orange,
            false,
          ),
          const SizedBox(height: 24),
          const Text(
            'Completed Quizzes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1a2b4a),
            ),
          ),
          const SizedBox(height: 16),
          _quizCard(
            'Philippine Literature',
            'Filipino',
            '20 items',
            'Oct 20, 2024',
            Colors.teal,
            true,
            score: '92%',
          ),
          const SizedBox(height: 12),
          _quizCard(
            'World War II History',
            'History',
            '25 items',
            'Oct 18, 2024',
            Colors.red,
            true,
            score: '85%',
          ),
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
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isCompleted ? Icons.check_circle : Icons.quiz,
              color: isCompleted ? Colors.green : color,
              size: 28,
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
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Color(0xFF1a2b4a),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subject,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  info,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isCompleted && score != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    score,
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                Text(
                  date,
                  style: TextStyle(
                    color: Colors.red.shade400,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: isCompleted ? null : () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCompleted ? Colors.grey.shade300 : color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isCompleted ? 'Done' : 'Start',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
            'Attendance Record',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1a2b4a),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'View your attendance history',
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
                    _attendanceBigStat('23', 'Present', Colors.green),
                    _attendanceBigStat('2', 'Late', Colors.orange),
                    _attendanceBigStat('1', 'Absent', Colors.red),
                    _attendanceBigStat('92%', 'Rate', const Color(0xFF0d2b5c)),
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
                const Text(
                  'October 2024',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1a2b4a),
                  ),
                ),
                const SizedBox(height: 16),
                _buildAttendanceCalendar(),
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
                const Text(
                  'Recent History',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1a2b4a),
                  ),
                ),
                const SizedBox(height: 12),
                _attendanceHistoryItem(
                  'Oct 25, 2024',
                  'Present',
                  'On time',
                  Colors.green,
                ),
                const Divider(),
                _attendanceHistoryItem(
                  'Oct 24, 2024',
                  'Present',
                  'On time',
                  Colors.green,
                ),
                const Divider(),
                _attendanceHistoryItem(
                  'Oct 23, 2024',
                  'Late',
                  'Arrived 15 mins late',
                  Colors.orange,
                ),
                const Divider(),
                _attendanceHistoryItem(
                  'Oct 22, 2024',
                  'Present',
                  'On time',
                  Colors.green,
                ),
                const Divider(),
                _attendanceHistoryItem(
                  'Oct 20, 2024',
                  'Absent',
                  'Sick leave',
                  Colors.red,
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

  Widget _buildAttendanceCalendar() {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final status = [
      Colors.green,
      Colors.green,
      Colors.green,
      Colors.orange,
      Colors.green,
      null,
      null,
      Colors.green,
      Colors.green,
      Colors.green,
      Colors.green,
      Colors.green,
      null,
      null,
      Colors.green,
      Colors.red,
      Colors.green,
      Colors.green,
      Colors.green,
      null,
      null,
      Colors.green,
      Colors.green,
      Colors.orange,
      Colors.green,
      Colors.green,
      null,
      null,
    ];

    return Column(
      children: [
        Row(
          children: days
              .map(
                (d) => Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(25, (index) {
            final s = status[index];
            return Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: s ?? Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: s != null
                  ? Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : null,
            );
          }),
        ),
      ],
    );
  }

  Widget _attendanceHistoryItem(
    String date,
    String status,
    String note,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  note,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
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
          const Text(
            'Announcements',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1a2b4a),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Stay updated with school news',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 24),
          _announcementCard(
            'Midterm Exam Schedule',
            'The midterm examination will be held on November 15-20, 2024. All students must bring their school ID and examination permit. Please review the schedule posted on the bulletin board.',
            'Oct 25, 2024',
            Colors.blue,
            true,
          ),
          const SizedBox(height: 12),
          _announcementCard(
            'Science Fair 2024',
            'Join us for the annual Science Fair on November 10, 2024. Students are encouraged to showcase their innovative projects. Registration deadline is November 5. Prizes will be awarded to the top 3 projects.',
            'Oct 24, 2024',
            Colors.green,
            true,
          ),
          const SizedBox(height: 12),
          _announcementCard(
            'Semestral Break',
            'Classes will be suspended from October 28 to November 3 for the semestral break. Classes will resume on November 4, 2024. Have a safe and restful break!',
            'Oct 20, 2024',
            Colors.orange,
            false,
          ),
          const SizedBox(height: 12),
          _announcementCard(
            'Parent-Teacher Conference',
            'The Parent-Teacher Conference is scheduled for November 8, 2024. Parents are invited to discuss their child\'s academic progress with teachers.',
            'Oct 18, 2024',
            Colors.purple,
            false,
          ),
        ],
      ),
    );
  }

  Widget _announcementCard(
    String title,
    String content,
    String date,
    Color color,
    bool isNew,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: isNew
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
              if (isNew)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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

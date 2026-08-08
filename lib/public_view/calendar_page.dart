import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  void _prevMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
  }

  // Returns list of day numbers (0 = empty/filler) for a 5-row grid (35 cells)
  List<int?> _buildCalendarDays() {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    ).day;
    // weekday: Mon=1..Sun=7, we need Sun=0
    final startOffset = firstDay.weekday % 7;

    final cells = <int?>[];
    for (int i = 0; i < startOffset; i++) {
      cells.add(null);
    }
    for (int d = 1; d <= daysInMonth; d++) {
      cells.add(d);
    }
    // Pad to full rows
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    return cells;
  }

  // Sample events — keyed by day number, only for current displayed month
  Map<int, CalendarEvent> _eventsForMonth() {
    final m = _focusedMonth.month;
    final y = _focusedMonth.year;

    // Static sample events — you can replace with dynamic data later
    if (y == 2024 && m == 10) {
      return {
        4: CalendarEvent(
          "TEACHERS' DAY\nCELEBRATION",
          const Color(0xFFB8860B),
          Colors.white,
        ),
        11: CalendarEvent(
          'MID-TERM\nASSESSMENT',
          const Color(0xFF1B3A6B),
          Colors.white,
        ),
        12: CalendarEvent('', const Color(0xFF1B3A6B), Colors.white),
        14: CalendarEvent('', const Color(0xFF1B3A6B), Colors.white),
        15: CalendarEvent('', const Color(0xFF1B3A6B), Colors.white),
        18: CalendarEvent(
          'DISTRICT\nSPORTS MEET',
          const Color(0xFF8B4513),
          Colors.white,
        ),
        24: CalendarEvent('UN DAY', const Color(0xFFFFA000), Colors.white),
      };
    }
    return {};
  }

  String _monthLabel() {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[_focusedMonth.month - 1]} ${_focusedMonth.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 1100;
          return Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 100),
                    _buildTitleSection(context, isMobile),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 20 : 100,
                        vertical: 20,
                      ),
                      child: isMobile
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildCalendarSection(),
                                const SizedBox(height: 30),
                                _buildSidebar(),
                              ],
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 7,
                                  child: _buildCalendarSection(),
                                ),
                                const SizedBox(width: 30),
                                Expanded(flex: 3, child: _buildSidebar()),
                              ],
                            ),
                    ),
                    _buildFooter(),
                  ],
                ),
              ),
              _buildTopNavBar(context, isMobile),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopNavBar(BuildContext context, bool isMobile) {
    return Container(
      height: 80,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 60),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/'),
            child: Row(
              children: [
                Image.asset('assets/capstonelogo.png', height: 40),
                const SizedBox(width: 12),
                if (!isMobile)
                  Text(
                    'Dela Paz National High School',
                    style: GoogleFonts.workSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: const Color(0xFF1E3A8A),
                    ),
                  ),
              ],
            ),
          ),
          if (!isMobile)
            Flexible(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _navLink(context, 'HOME', '/', false),
                    _navLink(context, 'NEWS', '/news', false),
                    _navLink(context, 'CALENDAR', '/calendar', true),
                    const SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003178),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: Text(
                        'Portal Login',
                        style: GoogleFonts.workSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.menu, color: Color(0xFF1E3A8A)),
              onPressed: () {},
            ),
        ],
      ),
    );
  }

  Widget _navLink(
    BuildContext context,
    String title,
    String route,
    bool isActive,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: InkWell(
        onTap: () {
          if (route != '#') Navigator.pushNamed(context, route);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: GoogleFonts.workSans(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive
                    ? const Color(0xFF1E3A8A)
                    : const Color(0xFF64748B),
              ),
            ),
            if (isActive)
              Container(
                margin: const EdgeInsets.only(top: 4),
                height: 2,
                width: 20,
                color: const Color(0xFFFEB300),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSection(BuildContext context, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 100,
        vertical: 30,
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitleText(),
                const SizedBox(height: 20),
                _buildMonthNavigation(),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: _buildTitleText()),
                Expanded(flex: 3, child: _buildMonthNavigation()),
              ],
            ),
    );
  }

  Widget _buildTitleText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'THE INSTITUTIONAL RECORD',
          style: GoogleFonts.workSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFB8860B),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Academic Year\n2025—2026',
          style: GoogleFonts.workSans(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1B3A6B),
            height: 1.1,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Navigating the milestones of excellence. Our comprehensive calendar outlines examination periods, cultural festivals, and key administrative deadlines.',
          style: GoogleFonts.publicSans(
            fontSize: 14,
            color: const Color(0xFF64748B),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthNavigation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        GestureDetector(
          onTap: _prevMonth,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Icon(Icons.chevron_left, size: 16, color: Colors.grey[600]),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          _monthLabel(),
          style: GoogleFonts.workSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1B3A6B),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: _nextMonth,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Icon(Icons.chevron_right, size: 16, color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarSection() {
    final days = _buildCalendarDays();
    final events = _eventsForMonth();
    final today = DateTime.now();
    final isCurrentMonth =
        _focusedMonth.year == today.year && _focusedMonth.month == today.month;

    // Split into rows of 7
    final rows = <List<int?>>[];
    for (int i = 0; i < days.length; i += 7) {
      rows.add(days.sublist(i, i + 7));
    }

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            children: [
              // Day headers
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF0D2240),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    'SUN',
                    'MON',
                    'TUE',
                    'WED',
                    'THU',
                    'FRI',
                    'SAT',
                  ].map((d) => _buildDayHeader(d)).toList(),
                ),
              ),
              // Calendar rows
              ...rows.asMap().entries.map((entry) {
                final isLast = entry.key == rows.length - 1;
                return _buildCalendarRow(
                  entry.value.map((day) {
                    if (day == null) return _buildEmptyCell();
                    final event = events[day];
                    final isToday = isCurrentMonth && day == today.day;
                    return _buildDayCell(day, event, isToday);
                  }).toList(),
                  isLast: isLast,
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            _buildLegendItem(const Color(0xFF1B3A6B), 'ACADEMICS'),
            const SizedBox(width: 24),
            _buildLegendItem(const Color(0xFFFFA000), 'HOLIDAY / OBSERVANCE'),
            const SizedBox(width: 24),
            _buildLegendItem(const Color(0xFF8B4513), 'SPORTS & CULTURE'),
            const SizedBox(width: 24),
            _buildLegendItem(Colors.grey, 'ADMINISTRATIVE'),
          ],
        ),
      ],
    );
  }

  Widget _buildDayHeader(String day) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        child: Text(
          day,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarRow(List<Widget> children, {bool isLast = false}) {
    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(children: children),
    );
  }

  Widget _buildEmptyCell() {
    return Expanded(
      child: Container(height: 80, color: const Color(0xFFF9FAFB)),
    );
  }

  Widget _buildDayCell(int day, CalendarEvent? event, bool isToday) {
    return Expanded(
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: event != null && event.title.isNotEmpty
              ? event.backgroundColor.withOpacity(0.08)
              : Colors.transparent,
          border: event != null && event.title.isEmpty
              ? Border.all(color: event.backgroundColor, width: 2)
              : null,
        ),
        child: Stack(
          children: [
            Positioned(
              top: 8,
              left: 8,
              child: isToday
                  ? Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Color(0xFF003178),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$day',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : Text(
                      '$day',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1B3A6B),
                      ),
                    ),
            ),
            if (event != null && event.title.isNotEmpty)
              Positioned(
                top: 28,
                left: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: event.backgroundColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: event.textColor,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildSidebar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'UPCOMING\nMILESTONES',
                style: GoogleFonts.workSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFB8860B),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '04',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B3A6B),
                ),
              ),
              Text(
                'DAYS UNTIL MID-TERMS',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '12',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B3A6B),
                ),
              ),
              Text(
                'PLANNED FACULTY\nREVIEWS',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: const DecorationImage(
              image: AssetImage('assets/capstonebackground.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  const Color(0xFF1B3A6B).withOpacity(0.9),
                ],
              ),
            ),
            padding: const EdgeInsets.all(16),
            alignment: Alignment.bottomLeft,
            child: Text(
              'Preserving our\nhistory, crafting your\nfuture.',
              style: GoogleFonts.workSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'INSTITUTIONAL EVENTS',
          style: GoogleFonts.workSans(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1B3A6B),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        _buildEventItem(
          'OCT',
          '24',
          'United Nations Day\nObservance',
          'Multi-cultural parade and auditorium assembly at 8:00 AM.',
        ),
        const SizedBox(height: 16),
        _buildEventItem(
          'NOV',
          '02',
          'Parent-Teacher\nConference',
          'First Quarter performance reviews. Registration required.',
        ),
        const SizedBox(height: 16),
        _buildEventItem(
          'NOV',
          '15',
          'Science & Tech Fair\n2024',
          'Showcasing student-led research and engineering prototypes.',
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'DOWNLOAD ACADEMIC\nPLANNER (PDF)',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(width: 8),
              Icon(Icons.download, size: 14, color: Colors.grey[700]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEventItem(
    String month,
    String day,
    String title,
    String description,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 40,
          child: Column(
            children: [
              Text(
                month,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[500],
                ),
              ),
              Text(
                day,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B3A6B),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1B3A6B),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DELA PAZ NATIONAL HIGH SCHOOL',
                style: GoogleFonts.workSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1B3A6B),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '© 2024 Dela Paz National High School. Office of the Registrar.',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
          Row(
            children: [
              _buildFooterLink('Academic Regulations'),
              const SizedBox(width: 24),
              _buildFooterLink('Campus Directory'),
              const SizedBox(width: 24),
              _buildFooterLink('Portal Privacy'),
              const SizedBox(width: 24),
              _buildFooterLink('Accessibility'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLink(String text) {
    return Text(text, style: TextStyle(fontSize: 11, color: Colors.grey[600]));
  }
}

class CalendarEvent {
  final String title;
  final Color backgroundColor;
  final Color textColor;

  CalendarEvent(this.title, this.backgroundColor, this.textColor);
}
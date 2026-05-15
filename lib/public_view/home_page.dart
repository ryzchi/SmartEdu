import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  int _currentPage = 0;

  final List<String> _carouselImages = [
    'assets/capstonebackground.jpg',
    'assets/capstoneimage1.jpg',
    'assets/capstoneimage2.jpg',
    'assets/capstoneimage3.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _startAutoSlide();
  }

  void _startAutoSlide() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _nextPage();
      }
    });
  }

  void _nextPage() {
    if (!mounted) return;

    int nextPage = _currentPage + 1;
    if (nextPage >= _carouselImages.length) {
      nextPage = 0;
    }

    _pageController.animateToPage(
      nextPage,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
    );

    setState(() {
      _currentPage = nextPage;
    });

    _startAutoSlide();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 1100;
          return Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeroSection(context, isMobile),
                    _buildFooter(isMobile),
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
      height: 106,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/capstonelogo.png',
                height: isMobile ? 50 : 74,
              ),
              if (!isMobile) ...[
                const SizedBox(width: 16),
                Text(
                  'Dela Paz National High School',
                  style: GoogleFonts.workSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: const Color(0xFF172554),
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ],
          ),
          if (!isMobile)
            Flexible(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _navLink('HOME', true, '/', context),
                    _navLink('NEWS', false, '/news', context),
                    _navLink('CALENDAR', false, '/calendar', context),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.search,
                      size: 20,
                      color: Color(0xFF475569),
                    ),
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
    String title,
    bool isActive,
    String route,
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: InkWell(
        onTap: () {
          if (route != '#') {
            Navigator.pushNamed(context, route);
          }
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
                    : const Color(0xFF475569),
              ),
            ),
            if (isActive)
              Container(
                margin: const EdgeInsets.only(top: 2),
                height: 2,
                width: 20,
                color: const Color(0xFFF59E0B),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, bool isMobile) {
    return SizedBox(
      height: 870,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _carouselImages.length,
              itemBuilder: (context, index) {
                return Image.asset(_carouselImages[index], fit: BoxFit.cover);
              },
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF001D4E).withOpacity(0.9),
                    const Color(0xFF001D4E).withOpacity(0.4),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 60),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEB300),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    'EST. 2003 • ACADEMIC EXCELLENCE',
                    style: GoogleFonts.workSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: const Color(0xFF6A4800),
                      letterSpacing: 2.4,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Academic\nToward\nExcellence',
                  style: GoogleFonts.workSans(
                    fontSize: isMobile ? 48 : 72,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1,
                    letterSpacing: -3.6,
                  ),
                ),
                const SizedBox(height: 76),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    InkWell(
                      onTap: () => Navigator.pushNamed(context, '/admission'),
                      child: _heroButton(
                        'APPLY FOR ADMISSION',
                        const Color(0xFFFEB300),
                        const Color(0xFF6A4800),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/academics'),
                      child: Container(
                        height: 58,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 1.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'LEARN MORE',
                              style: GoogleFonts.workSans(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.4,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_right_alt,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 120,
            left: isMobile ? 20 : 60,
            child: Row(
              children: List.generate(
                _carouselImages.length,
                (index) => Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? const Color(0xFFFEB300)
                        : Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          if (!isMobile)
            Positioned(right: 0, bottom: 0, child: _buildVisionCard()),
        ],
      ),
    );
  }

  Widget _heroButton(String label, Color bg, Color text) {
    return Container(
      width: 250,
      height: 58,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x337E5700),
            blurRadius: 25,
            offset: Offset(0, 20),
          ),
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.workSans(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: text,
            letterSpacing: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildVisionCard() {
    return Container(
      width: 447,
      height: 438,
      padding: const EdgeInsets.all(40),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'OUR VISION',
            style: GoogleFonts.workSans(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: const Color(0xFF7E5700),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'II',
                style: GoogleFonts.workSans(
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                  color: const Color(0xFF001D4E),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'We dream of Filipinos who passionately love their country and whose values and competencies enable them to realize their full potential and contribute meaningfully to building the nation.\n\nAs a learner-centered public institution, the Department of Education continuously improves itself to better serve its stakeholders..',
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF505050),
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(width: 48, height: 4, color: const Color(0xFFFEB300)),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isMobile) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF1F5F9),
      padding: EdgeInsets.fromLTRB(
        isMobile ? 20 : 48,
        65,
        isMobile ? 20 : 48,
        32,
      ),
      child: Column(
        children: [
          Wrap(
            spacing: 100,
            runSpacing: 40,
            children: [
              _footerBrand(),
              _footerLinkSection('NAVIGATION', ['Home', 'News', 'Calendar']),
              _footerLinkSection('RESOURCES', [
                'Faculty Portal',
                'Alumni',
                'Privacy Policy',
                'Terms of Service',
              ]),
              _footerContact(),
            ],
          ),
          const SizedBox(height: 60),
          const Divider(color: Color(0x1A64748B)),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '© 2024 Dela Paz National High School. All rights reserved.',
                style: GoogleFonts.publicSans(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
              const Row(
                children: [
                  Icon(Icons.face, size: 18, color: Color(0xFF64748B)),
                  SizedBox(width: 16),
                  Icon(Icons.book, size: 18, color: Color(0xFF64748B)),
                  SizedBox(width: 16),
                  Icon(Icons.public, size: 18, color: Color(0xFF64748B)),
                  SizedBox(width: 16),
                  Icon(Icons.people, size: 18, color: Color(0xFF64748B)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _footerBrand() {
    return SizedBox(
      width: 260,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.school, size: 40, color: Color(0xFF64748B)),
          const SizedBox(height: 16),
          Text(
            'DELA PAZ NHS',
            style: GoogleFonts.workSans(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: const Color(0xFF172554),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Inspiring excellence and shaping futures through quality secondary education in a nurturing environment.',
            style: GoogleFonts.publicSans(
              fontSize: 14,
              color: const Color(0xFF64748B),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerLinkSection(String title, List<String> links) {
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.workSans(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: const Color(0xFF1E3A8A),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          ...links.map(
            (link) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                link,
                style: GoogleFonts.publicSans(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerContact() {
    return SizedBox(
      width: 260,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CONTACT US',
            style: GoogleFonts.workSans(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: const Color(0xFF1E3A8A),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          _contactItem(Icons.location_on, 'Brgy. Dela Paz, binan City'),
          _contactItem(Icons.email, 'admissions@delapaznhs.edu.ph'),
          _contactItem(Icons.phone, '(02) 8642-1234'),
        ],
      ),
    );
  }

  Widget _contactItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF64748B)),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.publicSans(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

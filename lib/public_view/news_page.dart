import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NewsPage extends StatelessWidget {
  const NewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 1100;
          return Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 100),
                    _buildHeroSection(context, isMobile),
                    _buildLatestNewsSection(context, isMobile),
                    _buildStayConnectedSection(isMobile),
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
                    _navLink(context, 'NEWS', '/news', true),
                    _navLink(context, 'CALENDAR', '/calendar', false),
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

  Widget _buildHeroSection(BuildContext context, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 100,
        vertical: 40,
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroTextContent(context, isMobile),
                const SizedBox(height: 30),
                _buildHeroImage(isMobile),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildHeroTextContent(context, isMobile),
                ),
                const SizedBox(width: 40),
                Expanded(flex: 2, child: _buildHeroImage(isMobile)),
              ],
            ),
    );
  }

  Widget _buildHeroTextContent(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFEB300).withOpacity(0.15),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            'CAMPUS LIFE',
            style: GoogleFonts.workSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF7E5700),
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'May 24, 2024',
          style: GoogleFonts.publicSans(
            fontSize: 13,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Celebrating Academic Excellence: The 45th Annual Commencement Exercises',
          style: GoogleFonts.workSans(
            fontSize: isMobile ? 32 : 48,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1E3A8A),
            height: 1.1,
            letterSpacing: -1.5,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: isMobile ? double.infinity : 500,
          child: Text(
            'In a momentous ceremony held at the Main Pavilion, DPNHS honored over 400 graduates who displayed exceptional resilience and scholarly achievement throughout their high school journey.',
            style: GoogleFonts.publicSans(
              fontSize: 16,
              color: const Color(0xFF64748B),
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 30),
        InkWell(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFEB300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Read the full Story',
                  style: GoogleFonts.workSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF6A4800),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward,
                  size: 16,
                  color: Color(0xFF6A4800),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroImage(bool isMobile) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        'assets/capstoneimage1.jpg',
        height: isMobile ? 250 : 400,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildLatestNewsSection(BuildContext context, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 100,
        vertical: 60,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 3,
                    width: 40,
                    color: const Color(0xFFFEB300),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Latest News',
                    style: GoogleFonts.workSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E3A8A),
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {},
                child: Row(
                  children: [
                    Text(
                      'BROWSE ALL ARTICLES',
                      style: GoogleFonts.workSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF64748B),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.open_in_new,
                      size: 14,
                      color: Color(0xFF64748B),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          isMobile
              ? Column(
                  children: [
                    _newsCard(
                      'assets/news_math.jpg',
                      'ACADEMIC',
                      'May 16, 2024',
                      'Mathinking',
                      'Brainsik bakbakchegchegkwakwakkwakchegkwakwakwak',
                    ),
                    const SizedBox(height: 24),
                    _newsCard(
                      'assets/capstoneimage2.jpg',
                      'SPORTS',
                      'May 15, 2024',
                      'Sport and E Sport',
                      'Sports focus on physical strength, while esports focus on mental skills—both offer entertainment, competition, and growth opportunities.',
                    ),
                    const SizedBox(height: 24),
                    _newsCard(
                      'assets/capstoneimage3.jpg',
                      'HERITAGE',
                      'May 10, 2024',
                      'The Digital Archive: Preserving School History',
                      'DPNHS launches its first comprehensive digital library, cataloging over five decades of photographs, records, and student achievements for future...',
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _newsCard(
                        'assets/capstoneimage1.jpg',
                        'ACADEMIC',
                        'May 16, 2024',
                        'Mathinking',
                        'Brainsik bakbakchegchegkwakwakkwakchegkwakwakwak',
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _newsCard(
                        'assets/capstoneimage2.jpg',
                        'SPORTS',
                        'May 15, 2024',
                        'Sport and E Sport',
                        'Sports focus on physical strength, while esports focus on mental skills—both offer entertainment, competition, and growth opportunities.',
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _newsCard(
                        'assets/capstoneimage3.jpg',
                        'HERITAGE',
                        'May 10, 2024',
                        'The Digital Archive: Preserving School History',
                        'DPNHS launches its first comprehensive digital library, cataloging over five decades of photographs, records, and student achievements for future...',
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _newsCard(
    String imagePath,
    String category,
    String date,
    String title,
    String description,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            imagePath,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              category,
              style: GoogleFonts.workSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFFEB300),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              date,
              style: GoogleFonts.publicSans(
                fontSize: 12,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: GoogleFonts.workSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E3A8A),
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: GoogleFonts.publicSans(
            fontSize: 14,
            color: const Color(0xFF64748B),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildStayConnectedSection(bool isMobile) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 100),
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: const Color(0xFF001D4E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStayConnectedText(),
                const SizedBox(height: 30),
                _buildNewsletterForm(),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 2, child: _buildStayConnectedText()),
                Expanded(flex: 3, child: _buildNewsletterForm()),
              ],
            ),
    );
  }

  Widget _buildStayConnectedText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STAY CONNECTED.',
          style: GoogleFonts.workSans(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: 350,
          child: Text(
            'Subscribe to our weekly editorial digest to receive the latest academic journals, campus events, and administrative updates directly in your inbox.',
            style: GoogleFonts.publicSans(
              fontSize: 14,
              color: const Color(0xFF94A3B8),
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewsletterForm() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F2D5E),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF1E3A8A)),
            ),
            child: const Center(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Enter your academic email',
                  hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFEB300),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          child: Text(
            'Join Circular',
            style: GoogleFonts.workSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF6A4800),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(bool isMobile) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
        isMobile ? 20 : 100,
        60,
        isMobile ? 20 : 100,
        32,
      ),
      child: Column(
        children: [
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _footerContent(),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _footerContent(),
                ),
          const SizedBox(height: 40),
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '© 2024 Dela Paz National High School. Empowering excellence through heritage and innovation.',
                style: GoogleFonts.publicSans(
                  fontSize: 12,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const Row(
                children: [
                  Text(
                    'REPUBLIC OF THE PHILIPPINES',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(width: 24),
                  Text(
                    'DEPARTMENT OF EDUCATION',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _footerContent() {
    return [
      SizedBox(
        width: 260,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dela Paz National High School',
              style: GoogleFonts.workSans(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: const Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'A tradition of excellence, a legacy of service. Dedicated to the holistic development of the Filipino learner.',
              style: GoogleFonts.publicSans(
                fontSize: 14,
                color: const Color(0xFF64748B),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            const Row(
              children: [
                Icon(Icons.facebook, size: 18, color: Color(0xFF94A3B8)),
                SizedBox(width: 16),
                Icon(Icons.language, size: 18, color: Color(0xFF94A3B8)),
                SizedBox(width: 16),
                Icon(Icons.email, size: 18, color: Color(0xFF94A3B8)),
              ],
            ),
          ],
        ),
      ),
      _footerLinkColumn('Quick Links', [
        'Campus Map',
        'Accessibility',
        'Careers',
        'Transparency Seal',
      ]),
      _footerLinkColumn('Support', [
        'Contact Us',
        'Privacy Policy',
        'Terms of Service',
        'Data Privacy',
      ]),
      _footerLinkColumn('Office Address', [
        'Dela Paz, Antipolo City',
        'Rizal, Philippines 1870',
        '☎ +63 2 8123 4567',
        '✉ info@delapaznhs.edu.ph',
      ]),
    ];
  }

  Widget _footerLinkColumn(String title, List<String> links) {
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.workSans(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: const Color(0xFF1E3A8A),
            ),
          ),
          const SizedBox(height: 20),
          ...links.map(
            (link) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                link,
                style: GoogleFonts.publicSans(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

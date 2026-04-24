import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            isDesktop
                ? IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(child: _buildLeftPanel()),
                        Expanded(child: _buildRightPanel()),
                      ],
                    ),
                  )
                : Column(children: [_buildLeftPanel(), _buildRightPanel()]),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Image.asset('assets/capstonelogo.png', width: 50, height: 50),
              const SizedBox(width: 14),
              const Text(
                'Dela Paz National High School',
                style: TextStyle(
                  color: Color(0xFF1a2b4a),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Row(
            children: [
              _navItem('HOME', isActive: true),
              const SizedBox(width: 32),
              _navItem('NEWS'),
              const SizedBox(width: 32),
              _navItem('CALENDAR'),
              const SizedBox(width: 24),
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.search,
                  color: Color(0xFF4a5568),
                  size: 22,
                ),
                splashRadius: 20,
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {},
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
                child: const Text(
                  'Portal Login',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _navItem(String label, {bool isActive = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isActive ? const Color(0xFF1a2b4a) : const Color(0xFF4a5568),
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        if (isActive)
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 24,
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xFFd4a843),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
      ],
    );
  }

  Widget _buildLeftPanel() {
    return Container(
      height: MediaQuery.of(context).size.height > 700
          ? MediaQuery.of(context).size.height - 82
          : 700,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/capstonebackground.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.3),
              Colors.black.withOpacity(0.5),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.school,
                      color: Color(0xFF1a5276),
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dela Paz',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'National High School',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              const Text(
                'Welcome Back.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Access your academic progress, resources,\nand campus news through the unified student\nportal.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  _socialIcon(Icons.facebook),
                  const SizedBox(width: 8),
                  _socialIcon(Icons.camera_alt),
                  const SizedBox(width: 8),
                  _socialIcon(Icons.chat_bubble),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.people, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'JOIN 5,550+ ACTIVE STUDENTS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _socialIcon(IconData icon) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, color: Colors.white, size: 16),
    );
  }

  Widget _buildRightPanel() {
    return Container(
      color: const Color(0xFFF8F9FA),
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Circular Logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  image: const DecorationImage(
                    image: AssetImage('assets/capstonelogo.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Greeting
              const Text(
                'Hi, DPNHSian!',
                style: TextStyle(
                  color: Color(0xFF2c3e50),
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Subtitle
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.arrow_downward,
                    color: Colors.grey.shade600,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Please click or tap your destination.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Student Button — NAKA-CONNECT NA TO
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/student-login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007bff),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Student',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Faculty Button — NAKA-CONNECT NA TO
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/faculty-login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 246, 242, 14),
                    foregroundColor: const Color(0xFF2c3e50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Faculty',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Terms Text
              Text.rich(
                TextSpan(
                  text:
                      'By using this service, you understood and agree to the Dela Paz Online Services ',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    height: 1.5,
                  ),
                  children: const [
                    TextSpan(
                      text: 'Terms of Use',
                      style: TextStyle(
                        color: Color(0xFF007bff),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Statement',
                      style: TextStyle(
                        color: Color(0xFF007bff),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      color: const Color(0xFFedf2f7),
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
      child: Column(
        children: [
          Wrap(
            spacing: 60,
            runSpacing: 30,
            alignment: WrapAlignment.spaceBetween,
            children: [
              _footerColumn(
                title: 'Dela Paz National High School',
                items: [
                  'Dedicated to excellence in education\nand community empowerment since its\nfounding.',
                ],
                isDescription: true,
              ),
              _footerColumn(
                title: 'RESOURCES',
                items: ['Faculty Portal', 'Alumni', 'Careers'],
                isLink: true,
              ),
              _footerColumn(
                title: 'SUPPORT',
                items: ['Privacy Policy', 'Terms of Service'],
                isLink: true,
              ),
              _footerColumn(
                title: 'CONTACT',
                items: [
                  'R. Dela Paz St., Pasig City',
                  '(02) 8641-XXXX',
                  'info@delapaz.edu.ph',
                ],
              ),
            ],
          ),
          const SizedBox(height: 30),
          const Divider(color: Color(0xFFdee2e6)),
          const SizedBox(height: 20),
          const Text(
            '© 2024 Dela Paz National High School. All rights reserved.',
            style: TextStyle(color: Color(0xFFadb5bd), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _footerColumn({
    required String title,
    required List<String> items,
    bool isLink = false,
    bool isDescription = false,
  }) {
    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isDescription
                  ? const Color(0xFF2c3e50)
                  : Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: isLink
                  ? MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {},
                        child: Text(
                          item,
                          style: const TextStyle(
                            color: Color(0xFF6c757d),
                            fontSize: 12,
                            height: 1.5,
                            decoration: TextDecoration.underline,
                            decorationColor: Color(0xFFadb5bd),
                          ),
                        ),
                      ),
                    )
                  : Text(
                      item,
                      style: TextStyle(
                        color: const Color(0xFF6c757d),
                        fontSize: 12,
                        height: isDescription ? 1.6 : 1.5,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _selectedRole = 'Student';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  String _emailHint = 'name@gmail.com';

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  void _updateEmailHint() {
    setState(() {
      _emailHint = _selectedRole.toLowerCase() == 'student'
          ? 'name@gmail.com'
          : 'name@dpnhs.edu.ph';
    });
  }

  @override
  void initState() {
    super.initState();
    _updateEmailHint();
  }

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final fullName = '$firstName $lastName'.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Validate First Name
    if (firstName.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Please enter your first name';
      });
      return;
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(firstName)) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'First name should only contain letters';
      });
      return;
    }

    // Validate Last Name
    if (lastName.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Please enter your last name';
      });
      return;
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(lastName)) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Last name should only contain letters';
      });
      return;
    }

    // Validate Email
    if (email.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Please enter your email address';
      });
      return;
    }
    if (!_isValidEmail(email)) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Please enter a valid email address';
      });
      return;
    }

    // Validate Password
    if (password.length < 8) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Password must be at least 8 characters';
      });
      return;
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Password must contain at least one uppercase letter';
      });
      return;
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Password must contain at least one special character';
      });
      return;
    }

    // Validate Confirm Password
    if (password != confirmPassword) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Passwords do not match';
      });
      return;
    }

    // Register
    final result = await AuthService().register(
      fullName,
      email,
      password,
      confirmPassword,
      _selectedRole,
    );

    setState(() => _isLoading = false);

    if (result['success']) {
      if (mounted) {
        _showPinDialog(result['email']!, result['pin']!);
      }
    } else {
      setState(() => _errorMessage = result['message']);
    }
  }

  void _showPinDialog(String email, String pin) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.verified_user, color: Color(0xFF0d2b5c)),
            SizedBox(width: 12),
            Text(
              'Verify Your Account',
              style: TextStyle(color: Color(0xFF1a2b4a), fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A verification code has been generated for:',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              email,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Color(0xFF0d2b5c),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0d2b5c).withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF0d2b5c).withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'YOUR VERIFICATION CODE',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pin,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0d2b5c),
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'In a real system, this code would be sent to your email. For this demo, please copy the code above and proceed to verification.',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                '/verify-email',
                arguments: {'email': email, 'pin': pin},
              );
            },
            child: const Text(
              'Proceed to Verify',
              style: TextStyle(
                color: Color(0xFF0d2b5c),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/capstonebackground.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: Colors.black.withOpacity(0.6),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/capstonelogo.png',
                              width: 50,
                              height: 50,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1a2b4a),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 40,
                              height: 3,
                              color: const Color(0xFFd4a843),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFfee2e2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Color(0xFFdc3545),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Color(0xFFdc3545),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      _buildLabel('FIRST NAME'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _firstNameController,
                        decoration: _inputDecoration(
                          Icons.person_outline,
                          'Juan',
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('LAST NAME'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _lastNameController,
                        decoration: _inputDecoration(
                          Icons.person_outline,
                          'Dela Cruz',
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('EMAIL ADDRESS'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _inputDecoration(
                          Icons.email_outlined,
                          _emailHint,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('ROLE'),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedRole,
                            isExpanded: true,
                            items: ['Student', 'Faculty']
                                .map((r) => DropdownMenuItem(
                                      value: r,
                                      child: Text(
                                        r,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() {
                                  _selectedRole = v;
                                  _updateEmailHint();
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('PASSWORD'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: _inputDecoration(
                          Icons.lock_outline,
                          'Min. 8 characters',
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.grey.shade400,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('CONFIRM PASSWORD'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirm,
                        decoration: _inputDecoration(
                          Icons.lock_outline,
                          'Re-enter password',
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.grey.shade400,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0d2b5c),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Register',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text.rich(
                            TextSpan(
                              text: "Already have an account? ",
                              style: TextStyle(
                                color: Color(0xFF4a5568),
                                fontSize: 13,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Sign in',
                                  style: TextStyle(
                                    color: Color(0xFF007bff),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.grey.shade600,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
      ),
    );
  }

  InputDecoration _inputDecoration(IconData icon, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFF1a5276), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
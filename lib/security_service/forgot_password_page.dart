import 'package:flutter/material.dart';
import 'auth_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  final String role;
  const ForgotPasswordPage({super.key, required this.role});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _pinController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _pinSent = false;
  bool _isVerified = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _message;
  bool _isSuccess = false;
  int _step = 1; // 1 = email, 2 = verify code, 3 = new password

  late String _emailHint;

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  @override
  void initState() {
    super.initState();
    _emailHint = widget.role.toLowerCase() == 'student'
        ? 'name@gmail.com'
        : 'name@dpnhs.edu.ph';
  }

  Future<void> _requestPin() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _message = 'Please enter your email address';
        _isSuccess = false;
      });
      return;
    }
    if (!_isValidEmail(email)) {
      setState(() {
        _message = 'Please enter a valid email address';
        _isSuccess = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    final result = await AuthService().forgotPassword(email);

    setState(() {
      _isLoading = false;
      _pinSent = result['success'];
    });

    if (result['success'] && mounted) {
      _showPinDialog(result['pin']!);
    } else {
      setState(() {
        _message = result['message'];
        _isSuccess = false;
      });
    }
  }

  void _showPinDialog(String pin) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          'Reset Code Sent',
          style: TextStyle(color: Color(0xFF1a2b4a), fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'A password reset code has been sent to your email.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 12),
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
              child: Text(
                pin,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0d2b5c),
                  letterSpacing: 4,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please enter this code below to verify your identity.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _step = 2;
                _message = null;
              });
            },
            child: const Text(
              'Enter Code',
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

  Future<void> _verifyCode() async {
    final pin = _pinController.text.trim();

    if (pin.length != 6) {
      setState(() {
        _message = 'Please enter the 6-digit reset code';
        _isSuccess = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    final result = await AuthService().verifyPin(
      _emailController.text.trim(),
      pin,
    );

    setState(() {
      _isLoading = false;
      _isVerified = result['success'];
      if (!_isVerified) {
        _message = result['message'] ?? 'Invalid reset code';
        _isSuccess = false;
      } else {
        // ✅ WALANG MESSAGE — diretso na sa password reset
        _message = null;
        _isSuccess = false;
        _step = 3;
      }
    });
  }

  Future<void> _resetPassword() async {
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    setState(() {
      _message = null;
      _isSuccess = false;
    });

    if (newPass != confirmPass) {
      setState(() {
        _message = 'Passwords do not match';
        _isSuccess = false;
      });
      return;
    }

    if (newPass.length < 8) {
      setState(() {
        _message = 'Password must be at least 8 characters';
        _isSuccess = false;
      });
      return;
    }
    if (!RegExp(r'[A-Z]').hasMatch(newPass)) {
      setState(() {
        _message = 'Password must contain at least one uppercase letter';
        _isSuccess = false;
      });
      return;
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(newPass)) {
      setState(() {
        _message = 'Password must contain at least one special character';
        _isSuccess = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    final result = await AuthService().resetPassword(
      _emailController.text.trim(),
      _pinController.text,
      newPass,
      confirmPass,
    );

    setState(() {
      _isLoading = false;
      _isSuccess = result['success'];
      if (_isSuccess) {
        _message = 'Password reset successfully. Please login.';
      } else {
        _message = result['message'] ?? 'Failed to reset password';
      }
    });
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
                constraints: const BoxConstraints(maxWidth: 420),
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
                              'Forgot Password',
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
                      const SizedBox(height: 24),

                      // Message Display
                      if (_message != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: _isSuccess
                                ? const Color(0xFFd1fae5)
                                : const Color(0xFFfee2e2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isSuccess
                                    ? Icons.check_circle_outline
                                    : Icons.error_outline,
                                color: _isSuccess
                                    ? const Color(0xFF059669)
                                    : const Color(0xFFdc3545),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _message!,
                                  style: TextStyle(
                                    color: _isSuccess
                                        ? const Color(0xFF059669)
                                        : const Color(0xFFdc3545),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // ===== STEP 1: EMAIL =====
                      if (_step == 1) ...[
                        Text(
                          'Enter your email to receive a password reset code.',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildLabel('EMAIL ADDRESS'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: _emailHint,
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: Colors.grey.shade400,
                              size: 20,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8F9FA),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(
                                color: Colors.grey.shade200,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(
                                color: Colors.grey.shade200,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(
                                color: Color(0xFF1a5276),
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _requestPin,
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
                                    'Send Reset Code',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],

                      // ===== STEP 2: VERIFY CODE =====
                      if (_step == 2) ...[
                        Text(
                          'Enter the 6-digit reset code sent to your email.',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildLabel('RESET CODE'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _pinController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 8,
                          ),
                          decoration: InputDecoration(
                            hintText: '000000',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 20,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8F9FA),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(
                                color: Colors.grey.shade200,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(
                                color: Colors.grey.shade200,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(
                                color: Color(0xFF1a5276),
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            counterText: '',
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _verifyCode,
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
                                    'Verify Code',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                _step = 1;
                                _message = null;
                                _pinController.clear();
                              });
                            },
                            child: const Text(
                              '← Resend code',
                              style: TextStyle(
                                color: Color(0xFF6c757d),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],

                      // ===== STEP 3: NEW PASSWORD (walang message) =====
                      if (_step == 3) ...[
                        // ✅ WALANG "Your code has been verified" message
                        const SizedBox(height: 24),
                        _buildLabel('NEW PASSWORD'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _newPasswordController,
                          obscureText: _obscureNew,
                          decoration: InputDecoration(
                            hintText: 'Min. 8 characters',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: Colors.grey.shade400,
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureNew
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.grey.shade400,
                                size: 20,
                              ),
                              onPressed: () =>
                                  setState(() => _obscureNew = !_obscureNew),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8F9FA),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(
                                color: Colors.grey.shade200,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(
                                color: Colors.grey.shade200,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(
                                color: Color(0xFF1a5276),
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildLabel('CONFIRM PASSWORD'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirm,
                          decoration: InputDecoration(
                            hintText: 'Re-enter new password',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: Colors.grey.shade400,
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.grey.shade400,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm,
                              ),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8F9FA),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(
                                color: Colors.grey.shade200,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(
                                color: Colors.grey.shade200,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(
                                color: Color(0xFF1a5276),
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _resetPassword,
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
                                    'Reset Password',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],

                      // ===== SUCCESS =====
                      if (_isSuccess && _step == 3) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () =>
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  '/login',
                                  (route) => false,
                                ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF28a745),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Back to Login',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            '← Back to login',
                            style: TextStyle(
                              color: Color(0xFF6c757d),
                              fontSize: 13,
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
}
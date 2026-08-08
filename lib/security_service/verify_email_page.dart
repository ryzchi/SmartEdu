import 'package:flutter/material.dart';
import 'auth_service.dart';

class VerifyEmailPage extends StatefulWidget {
  final String email;
  const VerifyEmailPage({super.key, required this.email});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final _pinControllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isVerifying = false;
  bool _isVerified = false;
  String? _errorMessage;

  Future<void> _verify() async {
    final pin = _pinControllers.map((c) => c.text).join();

    if (pin.length != 6) {
      setState(() => _errorMessage = 'Please enter complete 6-digit code');
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    final result = await AuthService().verifyPin(widget.email, pin);

    setState(() => _isVerifying = false);

    if (result['success']) {
      setState(() => _isVerified = true);
    } else {
      setState(() => _errorMessage = result['message']);
    }
  }

  void _onPinChanged(int index, String value) {
    // Move to next field if a digit is entered
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    // Move to previous field if backspace is pressed (value becomes empty)
    else if (value.isEmpty && index > 0) {
      // Need to check if it was a backspace by checking if previous field exists
      // The onChanged triggers when field becomes empty due to backspace
      _focusNodes[index - 1].requestFocus();
      // Clear previous field's content if it was a backspace on an empty field
      // This handles the case where user backspaces on an empty field
      if (_pinControllers[index - 1].text.isEmpty && index - 1 > 0) {
        // Move focus further back if previous is also empty
        _focusNodes[index - 2].requestFocus();
      }
    }
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
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/capstonelogo.png',
                        width: 60,
                        height: 60,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Account Verification',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1a2b4a),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Enter the 6-digit verification code for:',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.email,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFF0d2b5c),
                        ),
                      ),
                      const SizedBox(height: 32),
                      if (!_isVerified) ...[
                        // ========== FIXED PIN ROW ==========
                        LayoutBuilder(
                          builder: (context, constraints) {
                            double maxWidth = constraints.maxWidth;
                            double totalGaps = 5 * 6.0; // 5 gaps x 6px
                            double fieldWidth = (maxWidth - totalGaps) / 6;
                            // Ensure minimum width
                            if (fieldWidth < 35) fieldWidth = 35;
                            if (fieldWidth > 48) fieldWidth = 48;

                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(6, (index) {
                                return Container(
                                  width: fieldWidth,
                                  height: fieldWidth * 1.2,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  child: TextField(
                                    controller: _pinControllers[index],
                                    focusNode: _focusNodes[index],
                                    textAlign: TextAlign.center,
                                    keyboardType: TextInputType.number,
                                    maxLength: 1,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1a2b4a),
                                    ),
                                    decoration: InputDecoration(
                                      counterText: '',
                                      filled: true,
                                      fillColor: const Color(0xFFF8F9FA),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade200,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade200,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF0d2b5c),
                                          width: 2,
                                        ),
                                      ),
                                      contentPadding: const EdgeInsets.all(0),
                                    ),
                                    onChanged: (value) =>
                                        _onPinChanged(index, value),
                                  ),
                                );
                              }),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Color(0xFFdc3545),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isVerifying ? null : _verify,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0d2b5c),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              elevation: 0,
                            ),
                            child: _isVerifying
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Verify Account',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/login',
                            (route) => false,
                          ),
                          child: const Text(
                            'Back to login',
                            style: TextStyle(
                              color: Color(0xFF6c757d),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ] else ...[
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF28a745),
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Account Verified!',
                          style: TextStyle(
                            color: Color(0xFF28a745),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You can now log in to your account.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/login',
                              (route) => false,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0d2b5c),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Proceed to Login',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
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

  @override
  void dispose() {
    for (var c in _pinControllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }
}
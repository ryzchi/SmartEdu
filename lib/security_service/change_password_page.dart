import 'package:flutter/material.dart';
import 'auth_service.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _message;
  bool _isSuccess = false;

  Future<void> _change() async {
    final email = AuthService().currentUserEmail;
    if (email == null) {
      setState(() {
        _isLoading = false;
        _isSuccess = false;
        _message = 'Could not determine current user email.';
      });
      return;
    }

    setState(() => _isLoading = true);
    final result = await AuthService().changePassword(
      email,
      _oldPasswordController.text,
      _newPasswordController.text,
      _confirmPasswordController.text,
    );
    setState(() {
      _isLoading = false;
      _isSuccess = result['success'];
      _message = result['message'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1a2b4a)),
        title: const Text(
          'Change Password',
          style: TextStyle(
            color: Color(0xFF1a2b4a),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  _buildField(
                    'CURRENT PASSWORD',
                    _oldPasswordController,
                    _obscureOld,
                    () => setState(() => _obscureOld = !_obscureOld),
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    'NEW PASSWORD',
                    _newPasswordController,
                    _obscureNew,
                    () => setState(() => _obscureNew = !_obscureNew),
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    'CONFIRM NEW PASSWORD',
                    _confirmPasswordController,
                    _obscureConfirm,
                    () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _change,
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
                              'Update Password',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    bool obscure,
    VoidCallback toggle,
  ) {
    return Column(
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
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Icon(
              Icons.lock_outline,
              color: Colors.grey.shade400,
              size: 20,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.grey.shade400,
                size: 20,
              ),
              onPressed: toggle,
            ),
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
      ],
    );
  }
}

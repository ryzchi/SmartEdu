import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  SharedPreferences? _prefs;
  Map<String, dynamic>? _currentUser;
  int _failedAttempts = 0;
  DateTime? _lockoutEndTime;

  static const int maxAttempts = 3;
  static const Duration lockoutDuration = Duration(minutes: 30);

  final ApiClient _api = ApiClient();

  Future<SharedPreferences> get _preferences async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
      await loadSession();
    }
    return _prefs!;
  }

  Future<void> init() async {
    await _preferences;
  }

  // ─── SESSION MANAGEMENT ─────────────────────────────────────────────

  Future<void> loadSession() async {
    final prefs = await _preferences;
    final session = prefs.getString('user_session');
    if (session != null) {
      try {
        _currentUser = jsonDecode(session);
      } catch (e) {
        _currentUser = null;
      }
    }
  }

  bool get isLoggedIn => _currentUser != null;
  String? get currentUserName => _currentUser?['name'];
  String? get currentUserEmail => _currentUser?['email'];
  String? get currentUserRole => _currentUser?['role'];
  int? get currentUserId => _currentUser?['id'];

  // ─── REMEMBER ME ────────────────────────────────────────────────────

  Future<bool> getRememberMeStatus() async {
    final prefs = await _preferences;
    return prefs.getBool('remember_me') ?? false;
  }

  Future<Map<String, String?>> getSavedCredentials() async {
    final prefs = await _preferences;
    final rememberMe = prefs.getBool('remember_me') ?? false;
    if (!rememberMe) {
      return {'email': null, 'password': null, 'role': null};
    }
    return {
      'email': prefs.getString('saved_email'),
      'password': prefs.getString('saved_password'),
      'role': prefs.getString('saved_role'),
    };
  }

  Future<void> saveCredentials(String email, String password, String role) async {
    final prefs = await _preferences;
    await prefs.setString('saved_email', email);
    await prefs.setString('saved_password', password);
    await prefs.setString('saved_role', role);
    await prefs.setBool('remember_me', true);
  }

  Future<void> clearSavedCredentials() async {
    final prefs = await _preferences;
    await prefs.remove('saved_email');
    await prefs.remove('saved_password');
    await prefs.remove('saved_role');
    await prefs.setBool('remember_me', false);
  }

  // ─── LOCKOUT ────────────────────────────────────────────────────────

  bool get isLockedOut {
    if (_lockoutEndTime == null) return false;
    if (DateTime.now().isBefore(_lockoutEndTime!)) return true;
    _lockoutEndTime = null;
    _failedAttempts = 0;
    return false;
  }

  String? get lockoutMessage {
    if (_lockoutEndTime == null) return null;
    final remaining = _lockoutEndTime!.difference(DateTime.now());
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    return 'Account locked. Try again in ${minutes}m ${seconds}s';
  }

  // ─── REGISTER ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
    String confirmPassword,
    String role,
  ) async {
    if (name.trim().isEmpty) {
      return {'success': false, 'message': 'Name is required'};
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}');
    if (!emailRegex.hasMatch(email)) {
      return {'success': false, 'message': 'Please enter a valid email address'};
    }

    if (password.length < 6) {
      return {'success': false, 'message': 'Password must be at least 6 characters'};
    }

    if (password != confirmPassword) {
      return {'success': false, 'message': 'Passwords do not match'};
    }

    try {
      final response = await _api.post('register.php', {
        'name': name,
        'email': email,
        'password': password,
        'role': role.toLowerCase() == 'faculty' ? 'teacher' : role.toLowerCase(),
      });
      return {
        'success': response['success'] == true,
        'message': response['message'] ?? 'Registration failed',
        'email': response['email'],
        'pin': response['pin'],
      };
    } catch (_) {
      return {'success': false, 'message': 'Unable to contact server'};
    }
  }

  // ─── VERIFY PIN ────────────────────────────────────────────────────

  Future<Map<String, dynamic>> verifyPin(
    String email,
    String enteredPin,
  ) async {
    try {
      final response = await _api.post('verify.php', {
        'email': email,
        'pin': enteredPin,
      });
      return {
        'success': response['success'] == true,
        'message': response['message'] ?? 'Verification failed',
      };
    } catch (_) {
      return {'success': false, 'message': 'Unable to contact server'};
    }
  }

  // ─── LOGIN ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(
    String email,
    String password,
    String role,
    bool rememberMe,
  ) async {
    if (isLockedOut) {
      return {
        'success': false,
        'message': lockoutMessage ?? 'Account is locked',
      };
    }

    try {
      final normalizedRole = role.toLowerCase() == 'faculty' ? 'teacher' : role.toLowerCase();
      print('📡 Sending login request: email=$email, role=$normalizedRole');
      
      final response = await _api.post('login.php', {
        'email': email,
        'password': password,
        'role': normalizedRole,
      });

      print('📡 API Response: $response');
      print('📡 Response type: ${response.runtimeType}');
      print('📡 Response keys: ${response.keys}');

      if (response['success'] == true) {
        _failedAttempts = 0;
        _lockoutEndTime = null;
        _currentUser = response['user'];
        
        final prefs = await _preferences;
        
        // Save session always (for current login)
        await prefs.setString('user_session', jsonEncode(_currentUser));
        
        // Handle remember me
        if (rememberMe) {
          // Save credentials for auto-fill
          await prefs.setString('saved_email', email);
          await prefs.setString('saved_password', password);
          await prefs.setString('saved_role', normalizedRole);
          await prefs.setBool('remember_me', true);
        } else {
          // Clear saved credentials if not remembering
          await prefs.remove('saved_email');
          await prefs.remove('saved_password');
          await prefs.remove('saved_role');
          await prefs.setBool('remember_me', false);
        }
        
        print('✅ Login successful, user: ${_currentUser?['name']}, id: ${_currentUser?['id']}');
        return {'success': true, 'message': response['message'] ?? 'Login successful'};
      }

      if (response['needsVerification'] == true) {
        print('⚠️ Account needs email verification');
        return {
          'success': false,
          'message': response['message'] ?? 'Please verify your account first.',
          'needsVerification': true,
          'email': response['email'],
        };
      }

      _failedAttempts += 1;
      if (_failedAttempts >= maxAttempts) {
        _lockoutEndTime = DateTime.now().add(lockoutDuration);
        print('🔒 Too many failed attempts - account locked');
        return {
          'success': false,
          'message': 'Too many failed attempts. Account locked for 30 minutes.',
        };
      }

      final remaining = maxAttempts - _failedAttempts;
      return {
        'success': false,
        'message': response['message'] ?? 'Invalid credentials. $remaining attempt(s) remaining.',
      };
    } catch (e) {
      print('❌ Login exception caught: $e');
      return {
        'success': false,
        'message': 'Login error: ${e.toString()}',
      };
    }
  }

  // ─── FORGOT PASSWORD ──────────────────────────────────────────────

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}');
    if (!emailRegex.hasMatch(email)) {
      return {'success': false, 'message': 'Please enter a valid email address'};
    }

    try {
      final response = await _api.post('forgot_password.php', {'email': email});
      return {
        'success': response['success'] == true,
        'message': response['message'] ?? 'Failed to generate reset code',
        'pin': response['pin'],
      };
    } catch (_) {
      return {'success': false, 'message': 'Unable to contact server'};
    }
  }

  // ─── RESET PASSWORD ───────────────────────────────────────────────

  Future<Map<String, dynamic>> resetPassword(
    String email,
    String enteredPin,
    String newPassword,
    String confirmPassword,
  ) async {
    if (newPassword.length < 6) {
      return {'success': false, 'message': 'Password must be at least 6 characters'};
    }
    if (newPassword != confirmPassword) {
      return {'success': false, 'message': 'Passwords do not match'};
    }

    try {
      final response = await _api.post('reset_password.php', {
        'email': email,
        'pin': enteredPin,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      });
      return {'success': response['success'] == true, 'message': response['message'] ?? 'Failed to reset password'};
    } catch (_) {
      return {'success': false, 'message': 'Unable to contact server'};
    }
  }

  // ─── CHANGE PASSWORD ──────────────────────────────────────────────

  Future<Map<String, dynamic>> changePassword(
    String email,
    String oldPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    if (newPassword.length < 6) {
      return {'success': false, 'message': 'Password must be at least 6 characters'};
    }
    if (newPassword != confirmPassword) {
      return {'success': false, 'message': 'Passwords do not match'};
    }

    try {
      final response = await _api.post('change_password.php', {
        'email': email,
        'old_password': oldPassword,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      });
      return {'success': response['success'] == true, 'message': response['message'] ?? 'Failed to change password'};
    } catch (_) {
      return {'success': false, 'message': 'Unable to contact server'};
    }
  }

  // ─── LOGOUT ────────────────────────────────────────────────────────

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await _preferences;
    await prefs.remove('user_session');
    await prefs.remove('saved_email');
    await prefs.remove('saved_password');
    await prefs.remove('saved_role');
    await prefs.setBool('remember_me', false);
  }
}
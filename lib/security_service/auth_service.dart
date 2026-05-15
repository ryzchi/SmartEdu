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

  Future<void> loadSession() async {
    final prefs = await _preferences;
    final session = prefs.getString('user_session');
    if (session != null) {
      _currentUser = jsonDecode(session);
    }
  }

  bool get isLoggedIn => _currentUser != null;
  String? get currentUserName => _currentUser?['name'];
  String? get currentUserEmail => _currentUser?['email'];
  String? get currentUserRole => _currentUser?['role'];

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
        'role': role.toLowerCase(),
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
      final response = await _api.post('login.php', {
        'email': email,
        'password': password,
        'role': role.toLowerCase(),
      });

      if (response['success'] == true) {
        _failedAttempts = 0;
        _lockoutEndTime = null;
        _currentUser = response['user'];
        final prefs = await _preferences;
        if (rememberMe) {
          await prefs.setString('user_session', jsonEncode(_currentUser));
          await prefs.setBool('remember_me', true);
        } else {
          await prefs.remove('user_session');
          await prefs.setBool('remember_me', false);
        }
        return {'success': true, 'message': response['message'] ?? 'Login successful'};
      }

      if (response['needsVerification'] == true) {
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
    } catch (_) {
      return {'success': false, 'message': 'Unable to contact server'};
    }
  }

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

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await _preferences;
    await prefs.remove('user_session');
    await prefs.setBool('remember_me', false);
  }
}

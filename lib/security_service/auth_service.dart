import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

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

  // LAZY INITIALIZATION - auto-init when needed
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

  // Generate 6-digit PIN
  String _generatePin() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
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

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      return {
        'success': false,
        'message': 'Please enter a valid email address',
      };
    }

    if (password.length < 6) {
      return {
        'success': false,
        'message': 'Password must be at least 6 characters',
      };
    }

    if (password != confirmPassword) {
      return {'success': false, 'message': 'Passwords do not match'};
    }

    final prefs = await _preferences;
    final storedUsers = prefs.getStringList('registered_users') ?? [];

    for (var u in storedUsers) {
      final decoded = jsonDecode(u);
      if (decoded['email'] == email) {
        return {'success': false, 'message': 'Email already registered'};
      }
    }

    // Generate verification PIN
    final pin = _generatePin();

    final newUser = jsonEncode({
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      'verified': false,
      'pin': pin,
    });

    storedUsers.add(newUser);
    await prefs.setStringList('registered_users', storedUsers);
    await prefs.setString('pending_verification_email', email);

    return {
      'success': true,
      'message': 'Registration successful. Verify your account.',
      'email': email,
      'pin': pin,
    };
  }

  Future<Map<String, dynamic>> verifyPin(
    String email,
    String enteredPin,
  ) async {
    final prefs = await _preferences;
    final storedUsers = prefs.getStringList('registered_users') ?? [];
    String? correctPin;

    for (var u in storedUsers) {
      final decoded = jsonDecode(u);
      if (decoded['email'] == email) {
        correctPin = decoded['pin'];
        break;
      }
    }

    if (correctPin == null) {
      return {'success': false, 'message': 'User not found'};
    }

    if (correctPin != enteredPin) {
      return {'success': false, 'message': 'Incorrect verification code'};
    }

    // Mark as verified
    final updated = <String>[];
    for (var u in storedUsers) {
      final decoded = jsonDecode(u);
      if (decoded['email'] == email) {
        decoded['verified'] = true;
        decoded.remove('pin');
      }
      updated.add(jsonEncode(decoded));
    }

    await prefs.setStringList('registered_users', updated);
    await prefs.remove('pending_verification_email');

    return {'success': true, 'message': 'Email verified successfully!'};
  }

  Future<Map<String, dynamic>> login(
    String email,
    String password,
    String role,
    bool rememberMe,
  ) async {
    final prefs = await _preferences;

    if (isLockedOut) {
      return {
        'success': false,
        'message': lockoutMessage ?? 'Account is locked',
      };
    }

    final storedUsers = prefs.getStringList('registered_users') ?? [];
    bool found = false;
    Map<String, dynamic>? user;

    // Check registered users first
    for (var u in storedUsers) {
      final decoded = jsonDecode(u);
      if (decoded['email'] == email &&
          decoded['password'] == password &&
          decoded['role'].toString().toLowerCase() == role.toLowerCase()) {
        if (decoded['verified'] == true) {
          found = true;
          user = decoded;
        } else {
          return {
            'success': false,
            'message': 'Please verify your account first.',
            'needsVerification': true,
            'email': email,
          };
        }
        break;
      }
    }

    if (found) {
      _failedAttempts = 0;
      _lockoutEndTime = null;
      _currentUser = user;

      if (rememberMe) {
        await prefs.setString('user_session', jsonEncode(user));
        await prefs.setBool('remember_me', true);
      } else {
        await prefs.remove('user_session');
        await prefs.setBool('remember_me', false);
      }

      return {'success': true, 'message': 'Login successful'};
    } else {
      _failedAttempts++;
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
        'message': 'Invalid credentials. $remaining attempt(s) remaining.',
      };
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      return {
        'success': false,
        'message': 'Please enter a valid email address',
      };
    }

    final pin = _generatePin();
    final prefs = await _preferences;
    await prefs.setString('reset_pin_$email', pin);

    return {
      'success': true,
      'message': 'Password reset code generated.',
      'pin': pin,
    };
  }

  Future<Map<String, dynamic>> resetPassword(
    String email,
    String enteredPin,
    String newPassword,
    String confirmPassword,
  ) async {
    if (newPassword.length < 6) {
      return {
        'success': false,
        'message': 'Password must be at least 6 characters',
      };
    }
    if (newPassword != confirmPassword) {
      return {'success': false, 'message': 'Passwords do not match'};
    }

    final prefs = await _preferences;
    final storedPin = prefs.getString('reset_pin_$email');
    if (storedPin == null || storedPin != enteredPin) {
      return {'success': false, 'message': 'Invalid reset code'};
    }

    final storedUsers = prefs.getStringList('registered_users') ?? [];
    final updated = <String>[];
    bool found = false;

    for (var u in storedUsers) {
      final decoded = jsonDecode(u);
      if (decoded['email'] == email) {
        decoded['password'] = newPassword;
        found = true;
      }
      updated.add(jsonEncode(decoded));
    }

    if (found) {
      await prefs.setStringList('registered_users', updated);
      await prefs.remove('reset_pin_$email');
      return {'success': true, 'message': 'Password reset successful'};
    }

    return {'success': false, 'message': 'User not found'};
  }

  Future<Map<String, dynamic>> changePassword(
    String oldPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    if (_currentUser == null) {
      return {'success': false, 'message': 'Not logged in'};
    }
    if (newPassword.length < 6) {
      return {
        'success': false,
        'message': 'Password must be at least 6 characters',
      };
    }
    if (newPassword != confirmPassword) {
      return {'success': false, 'message': 'Passwords do not match'};
    }

    final prefs = await _preferences;
    final storedUsers = prefs.getStringList('registered_users') ?? [];
    final updated = <String>[];
    bool found = false;

    for (var u in storedUsers) {
      final decoded = jsonDecode(u);
      if (decoded['email'] == _currentUser!['email']) {
        if (decoded['password'] != oldPassword) {
          return {'success': false, 'message': 'Incorrect current password'};
        }
        decoded['password'] = newPassword;
        found = true;
      }
      updated.add(jsonEncode(decoded));
    }

    if (found) {
      await prefs.setStringList('registered_users', updated);
      return {'success': true, 'message': 'Password changed successfully'};
    }

    return {'success': false, 'message': 'User not found'};
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await _preferences;
    await prefs.remove('user_session');
    await prefs.setBool('remember_me', false);
  }
}

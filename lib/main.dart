import 'package:flutter/material.dart';
import 'security_service/auth_service.dart';
import 'public_view/home_page.dart';
import 'public_view/login_page.dart';
import 'public_view/news_page.dart';
import 'public_view/calendar_page.dart';
import 'security_service/role_login_page.dart';
import 'security_service/register_page.dart';
import 'security_service/forgot_password_page.dart';
import 'security_service/reset_password_page.dart';
import 'security_service/change_password_page.dart';
import 'security_service/verify_email_page.dart';
import '/dashboards_page/student_dashboard_page.dart';
import 'dashboards_page/teacher_dashboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService().init();
  runApp(const DelaPazApp());
}

class DelaPazApp extends StatelessWidget {
  const DelaPazApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dela Paz National High School',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/login': (context) => const LoginPage(),
        '/news': (context) => const NewsPage(),
        '/calendar': (context) => const CalendarPage(),
        '/student-login': (context) => const RoleLoginPage(role: 'Student'),
        '/faculty-login': (context) => const RoleLoginPage(role: 'Faculty'),
        '/register': (context) => const RegisterPage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
        '/reset-password': (context) => const ResetPasswordPage(),
        '/change-password': (context) => const ChangePasswordPage(),
        '/student-dashboard': (context) => const StudentDashboardPage(),
        '/teacher-dashboard': (context) => const TeacherDashboardPage(),
        '/verify-email': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;
          return VerifyEmailPage(email: args?['email'] ?? '');
        },
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'dashboards_page/teacher_dashboard_page.dart';
import 'dashboards_page/student_dashboard_page.dart';
import 'public_view/login_page.dart';
import 'public_view/home_page.dart';
import 'public_view/news_page.dart';
import 'public_view/calendar_page.dart';
import 'security_service/register_page.dart';
import 'security_service/change_password_page.dart';
import 'security_service/forgot_password_page.dart';
import 'security_service/verify_email_page.dart';
import 'security_service/reset_password_page.dart'; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Learning Platform',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/login',
      onGenerateRoute: (settings) {
        if (settings.name == '/verify-email') {
          final args = settings.arguments as Map<String, dynamic>?;
          final email = args?['email'] ?? '';
          return MaterialPageRoute(
            builder: (context) => VerifyEmailPage(email: email),
          );
        }

        if (settings.name == '/forgot-password') {
          final role = settings.arguments as String? ?? 'Student';
          return MaterialPageRoute(
            builder: (context) => ForgotPasswordPage(role: role),
          );
        }

        if (settings.name == '/reset-password') {
          final role = settings.arguments as String? ?? 'Student';
          return MaterialPageRoute(
            builder: (context) => ResetPasswordPage(role: role),
          );
        }

        switch (settings.name) {
          case '/login':
          case '/':
            return MaterialPageRoute(builder: (context) => const LoginPage());
          case '/home':
            return MaterialPageRoute(builder: (context) => const HomePage());
          case '/news':
            return MaterialPageRoute(builder: (context) => const NewsPage());
          case '/calendar':
            return MaterialPageRoute(
              builder: (context) => const CalendarPage(),
            );
          case '/dashboard':
          case '/teacher-dashboard':
            return MaterialPageRoute(
              builder: (context) => const TeacherDashboardPage(),
            );
          case '/student-dashboard':
            return MaterialPageRoute(
              builder: (context) => const StudentDashboardPage(),
            );
          case '/register':
            return MaterialPageRoute(
              builder: (context) => const RegisterPage(),
            );
          case '/change-password':
            return MaterialPageRoute(
              builder: (context) => const ChangePasswordPage(),
            );
          default:
            return MaterialPageRoute(builder: (context) => const LoginPage());
        }
      },
    );
  }
}
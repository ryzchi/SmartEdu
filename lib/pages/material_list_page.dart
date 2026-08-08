import 'package:flutter/material.dart';

class LessonPlanPage extends StatelessWidget {
  const LessonPlanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lesson Plans')),
      body: const Center(
        child: Text('Lesson Plans feature is integrated in Teacher Dashboard'),
      ),
    );
  }
}

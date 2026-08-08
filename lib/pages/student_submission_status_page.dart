import 'package:flutter/material.dart';
import '../assignment_service.dart';

class StudentSubmissionStatusPage extends StatefulWidget {
  const StudentSubmissionStatusPage({super.key});

  @override
  State<StudentSubmissionStatusPage> createState() =>
      _StudentSubmissionStatusPageState();
}

class _StudentSubmissionStatusPageState
    extends State<StudentSubmissionStatusPage> {
  final AssignmentService _assignmentService =
      AssignmentService();

  List<Map<String, dynamic>> submissions = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadSubmissions();
  }

  Future<void> loadSubmissions() async {
    final data = await _assignmentService.fetchSubmissions();

    setState(() {
      submissions = data;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submission Status'),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : submissions.isEmpty
              ? const Center(
                  child: Text('No submissions found'),
                )
              : ListView.builder(
                  itemCount: submissions.length,
                  itemBuilder: (context, index) {
                    final submission = submissions[index];

                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        title: Text(
                          submission['assignment_title'] ?? '',
                        ),
                        subtitle: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Status: ${submission['status']}',
                            ),
                            Text(
                              'Feedback: ${submission['feedback'] ?? ''}',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
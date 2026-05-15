import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../assignment_service.dart';
import '../security_service/auth_service.dart';

class SubmitAssignmentPage extends StatefulWidget {
  final String assignmentId;

  const SubmitAssignmentPage({super.key, required this.assignmentId});

  @override
  State<SubmitAssignmentPage> createState() => _SubmitAssignmentPageState();
}

class _SubmitAssignmentPageState extends State<SubmitAssignmentPage> {
  File? file;
  bool loading = false;
  final AssignmentService _assignmentService = AssignmentService();

  Future pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        file = File(result.files.single.path!);
      });
    }
  }

  Future uploadSubmission() async {
    if (file == null) return;

    final studentEmail = AuthService().currentUserEmail;
    if (studentEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student email is not available.')),
      );
      return;
    }

    setState(() => loading = true);

    final result = await _assignmentService.submitAssignment(
      assignmentId: widget.assignmentId,
      filePath: file!.path,
      studentEmail: studentEmail,
    );

    setState(() => loading = false);

    if (mounted) {
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Submitted successfully!')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Submission failed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Assignment')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: pickFile,
              child: const Text('Pick File'),
            ),
            const SizedBox(height: 10),
            Text(file != null ? file!.path.split('/').last : 'No file selected'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : uploadSubmission,
              child: Text(loading ? 'Uploading...' : 'Submit'),
            ),
          ],
        ),
      ),
    );
  }
}

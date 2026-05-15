import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SubmitAssignmentPage extends StatefulWidget {
  final String assignmentId;

  const SubmitAssignmentPage({super.key, required this.assignmentId});

  @override
  State<SubmitAssignmentPage> createState() => _SubmitAssignmentPageState();
}

class _SubmitAssignmentPageState extends State<SubmitAssignmentPage> {
  File? file;
  bool loading = false;

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

    setState(() => loading = true);

    String fileName = file!.path.split('/').last;

    final ref = FirebaseStorage.instance
        .ref()
        .child('submissions/$fileName');

    await ref.putFile(file!);
    String url = await ref.getDownloadURL();

    await FirebaseFirestore.instance.collection('submissions').add({
      'assignmentId': widget.assignmentId,
      'fileUrl': url,
      'studentName': 'Student', // replace with auth later
      'submittedAt': Timestamp.now(),
      'status': 'pending',
    });

    setState(() => loading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Submitted successfully!")),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Submit Assignment")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: pickFile,
              child: const Text("Pick File"),
            ),
            const SizedBox(height: 10),
            Text(file != null ? file!.path.split('/').last : "No file selected"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : uploadSubmission,
              child: Text(loading ? "Uploading..." : "Submit"),
            ),
          ],
        ),
      ),
    );
  }
}
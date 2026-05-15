import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import './material_service.dart';

class UploadMaterialPage extends StatefulWidget {
  const UploadMaterialPage({super.key});

  @override
  State<UploadMaterialPage> createState() => _UploadMaterialPageState();
}

class _UploadMaterialPageState extends State<UploadMaterialPage> {
  File? selectedFile;
  final service = MaterialService();
  String title = '';
  String subject = '';
  bool _isLoading = false;
  String? _errorMessage;

  Future pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future upload() async {
    if (selectedFile == null) {
      setState(() => _errorMessage = 'Please select a file to upload.');
      return;
    }
    if (title.trim().isEmpty || subject.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter title and subject.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final fileName = selectedFile!.path.split('/').last;
    final result = await service.uploadMaterial(
      file: selectedFile!,
      title: title,
      subject: subject,
      type: fileName.split('.').last,
    );

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploaded!')),
        );
      }
    } else {
      setState(() => _errorMessage = result['message'] ?? 'Upload failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Material')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              onChanged: (val) => title = val,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              onChanged: (val) => subject = val,
              decoration: const InputDecoration(labelText: 'Subject'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: pickFile, child: const Text('Pick File')),
            const SizedBox(height: 8),
            Text(selectedFile != null ? selectedFile!.path.split('/').last : 'No file selected'),
            const SizedBox(height: 24),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ElevatedButton(
              onPressed: _isLoading ? null : upload,
              child: _isLoading ? const CircularProgressIndicator() : const Text('Upload'),
            ),
          ],
        ),
      ),
    );
  }
}

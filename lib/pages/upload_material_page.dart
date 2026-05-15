import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import './material_service.dart';

class UploadMaterialPage extends StatefulWidget {
  const UploadMaterialPage({super.key});

  @override
  _UploadMaterialPageState createState() => _UploadMaterialPageState();
}

class _UploadMaterialPageState extends State<UploadMaterialPage> {
  File? selectedFile;
  final service = MaterialService();
  String title = '';
  String subject = '';

  Future pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future upload() async {
    if (selectedFile == null) return;

    String fileName = selectedFile!.path.split('/').last;
    String url = await service.uploadFile(selectedFile!, fileName);

    await service.saveMaterial(
      title: title,
      subject: subject,
      url: url,
      type: fileName.split('.').last,
    );

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Uploaded!")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Material")),
      body: Column(
        children: [
          TextField(onChanged: (val) => title = val, decoration: const InputDecoration(labelText: "Title")),
          TextField(onChanged: (val) => subject = val, decoration: const InputDecoration(labelText: "Subject")),
          ElevatedButton(onPressed: pickFile, child: const Text("Pick File")),
          ElevatedButton(onPressed: upload, child: const Text("Upload")),
        ],
      ),
    );
  }
}
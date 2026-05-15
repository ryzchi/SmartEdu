import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MaterialService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Upload File
  Future<String> uploadFile(File file, String fileName) async {
    final ref = _storage.ref().child('materials/$fileName');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  // Save Metadata
  Future<void> saveMaterial({
    required String title,
    required String subject,
    required String url,
    required String type,
  }) async {
    await _firestore.collection('materials').add({
      'title': title,
      'subject': subject,
      'url': url,
      'type': type,
      'createdAt': Timestamp.now(),
    });
  }

  // Delete
  Future<void> deleteMaterial(String docId, String fileUrl) async {
    await _firestore.collection('materials').doc(docId).delete();
    await FirebaseStorage.instance.refFromURL(fileUrl).delete();
  }
}
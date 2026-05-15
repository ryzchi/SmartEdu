import 'dart:io';
import '../services/api_client.dart';

class MaterialService {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> uploadMaterial({
    required File file,
    required String title,
    required String subject,
    required String type,
  }) async {
    return await _api.uploadFile(
      'upload_material.php',
      'file',
      file.path,
      fields: {
        'title': title,
        'subject': subject,
        'type': type,
      },
    );
  }

  Future<void> deleteMaterial(String docId, String fileUrl) async {
    throw UnsupportedError('Delete is not implemented for the PHP backend yet');
  }
}

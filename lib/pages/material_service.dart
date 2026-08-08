import 'dart:io';
import '../services/api_client.dart';

class MaterialService {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> uploadMaterial({
    File? file,
    List<int>? fileBytes,
    String? fileName,
    required String title,
    required String subject,
    required String type,
  }) async {
    return await _api.uploadFile(
      'upload_material.php',
      'file',
      file?.path ?? '',
      fileBytes: fileBytes,
      fileName: fileName,
      fields: {
        'title': title,
        'subject': subject,
        'type': type,
      },
    );
  }

  Future<Map<String, dynamic>> editMaterial({
    required String id,
    required String title,
    required String subject,
    required String type,
  }) async {
    return _api.post('edit_material.php', {
      'id': id,
      'title': title,
      'subject': subject,
      'type': type,
    });
  }

  Future<Map<String, dynamic>> deleteMaterial(String materialId) async {
    return _api.post('delete_material.php', {
      'id': materialId,
    });
  }

  Future<List<Map<String, dynamic>>> fetchMaterials({Map<String, String>? query}) async {
    final response = await _api.get('materials.php', query);
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from((response['materials'] ?? []) as List);
    }
    return [];
  }
}

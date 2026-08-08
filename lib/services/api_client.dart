import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  // Dynamic base URL based on platform
  static String get _baseUrl {
    if (kIsWeb) {
      return 'http://localhost/ADET/backend/php/';
    } else if (Platform.isAndroid) {
      // Android emulator: 10.0.2.2
      // Physical device: use your PC's IP address
      return 'http://10.94.168.216/ADET/backend/php/';
    } else if (Platform.isIOS) {
      return 'http://127.0.0.1/ADET/backend/php/';
    } else {
      return 'http://localhost/ADET/backend/php/';
    }
  }

  final http.Client _client;

  ApiClient([http.Client? client]) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> get(String path, [Map<String, String>? query]) async {
    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: query);
    if (kDebugMode) print('📡 GET: $uri');
    try {
      final response = await _client.get(uri).timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$_baseUrl$path');
    if (kDebugMode) print('📡 POST: $uri');
    if (kDebugMode) print('📡 Body: $body');
    try {
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));
      if (kDebugMode) print('📡 Response: ${response.body}');
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> uploadFile(
    String path,
    String fileField,
    String filePath, {
    Map<String, String>? fields,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll({'Accept': 'application/json'})
      ..fields.addAll(fields ?? {});

    if (fileBytes != null) {
      request.files.add(http.MultipartFile.fromBytes(
        fileField,
        fileBytes,
        filename: fileName ?? 'upload.bin',
      ));
    } else if (filePath.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath(fileField, filePath));
    }

    try {
      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Upload error: $e'};
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode != 200) {
      return {'success': false, 'message': 'HTTP ${response.statusCode}'};
    }
    try {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) return data;
      return {'success': false, 'message': 'Invalid response format'};
    } catch (e) {
      return {'success': false, 'message': 'JSON error: $e'};
    }
  }
}
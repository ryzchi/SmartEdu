import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080/flutter.api';
    }
    return 'http://10.0.2.2:8080/flutter.api';
  }

  final http.Client _client;

  ApiClient([http.Client? client]) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> get(String path, [Map<String, String>? query]) async {
    final uri = Uri.parse('$baseUrl/$path').replace(queryParameters: query);
    final response = await _client.get(uri, headers: _defaultHeaders());
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl/$path');
    final response = await _client.post(
      uri,
      headers: _defaultHeaders(),
      body: jsonEncode(body),
    );
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> postForm(String path, Map<String, String> fields) async {
    final uri = Uri.parse('$baseUrl/$path');
    final response = await _client.post(
      uri,
      headers: _defaultHeaders(),
      body: fields,
    );
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> uploadFile(
    String path,
    String fileField,
    String filePath, {
    Map<String, String>? fields,
  }) async {
    final uri = Uri.parse('$baseUrl/$path');
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll({'Accept': 'application/json'})
      ..fields.addAll(fields ?? {});

    final file = await http.MultipartFile.fromPath(fileField, filePath);
    request.files.add(file);

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _decodeResponse(response);
  }

  Map<String, String> _defaultHeaders() => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final body = response.body.isEmpty ? '{}' : response.body;
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (e) {
      return {
        'success': false,
        'message': 'Unable to parse server response',
        'statusCode': response.statusCode,
      };
    }
  }
}

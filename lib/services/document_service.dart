import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class DocumentService {
  // Helper to get authorization headers (assuming you store your JWT token)
  Future<Map<String, String>> _getHeaders(String token) async {
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  /// 1. Fetch all documents for the authenticated user
  Future<List<dynamic>> fetchDocuments(String token) async {
    final url = Uri.parse('${AppConfig.apiUrl}/documents/');

    try {
      final response = await http.get(
        url,
        headers: await _getHeaders(token),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      } else {
        throw Exception('Failed to load documents: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error fetching documents: $e');
    }
  }

  /// 2. Upload a new document file to the backend
  Future<bool> uploadDocument(String token, File file) async {
    final url = Uri.parse('${AppConfig.apiUrl}/documents/upload');

    try {
      // Use MultiPartRequest for file streaming uploads
      final request = http.MultipartRequest('POST', url)
        ..headers.addAll(await _getHeaders(token))
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print('Upload failed with status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Network error during file upload: $e');
      return false;
    }
  }
}

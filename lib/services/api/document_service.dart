// lib/services/api/document_service.dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_client.dart';
import '../../models/workspace_items/document.dart';

class DocumentService {
  final ApiClient _client = ApiClient();

  /// Get all documents (optionally filtered by workspace)
  Future<Map<String, dynamic>> getDocuments({String? workspaceId}) async {
    try {
      final query = workspaceId != null ? '?workspace_id=$workspaceId' : '';
      return await _client.request(
        method: 'GET',
        endpoint: '/documents$query',
      );
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to get documents: ${e.toString()}'
      };
    }
  }

  /// Upload a document to a workspace
  Future<Map<String, dynamic>> uploadDocument({
    required File file,
    required String workspaceId,
    String? customFileName,
  }) async {
    try {
      final fileName = customFileName ?? file.path.split('/').last;

      final token = await _client.getToken();
      if (token == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiClient.baseUrl}/documents/upload'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['workspace_id'] = workspaceId;
      request.files.add(
        await http.MultipartFile.fromPath('file', file.path, filename: fileName),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      }

      String errorMsg = 'Upload failed';
      try {
        final error = jsonDecode(response.body);
        errorMsg = error['detail'] ?? error['error'] ?? 'Upload failed';
      } catch (e) {
        errorMsg = 'Server error: ${response.statusCode}';
      }

      return {'success': false, 'error': errorMsg};
    } catch (e) {
      return {
        'success': false,
        'error': 'Upload failed: ${e.toString()}'
      };
    }
  }

  /// Delete a document by ID
  Future<Map<String, dynamic>> deleteDocument(String documentId) async {
    try {
      final token = await _client.getToken();
      if (token == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }

      final response = await http.delete(
        Uri.parse('${ApiClient.baseUrl}/documents/$documentId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return {'success': true};
      } else if (response.statusCode == 404) {
        return {'success': false, 'error': 'Document not found'};
      } else if (response.statusCode == 401) {
        return {'success': false, 'error': 'Unauthorized'};
      } else {
        try {
          final error = jsonDecode(response.body);
          return {
            'success': false,
            'error': error['detail'] ?? 'Failed to delete document'
          };
        } catch (e) {
          return {
            'success': false,
            'error': 'Failed to delete document (${response.statusCode})'
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Connection error: ${e.toString()}'
      };
    }
  }

  /// Get download URL for a document
  /// The backend returns the file directly, not a JSON URL.
  /// This method returns the document ID so the caller can download directly.
  Future<String?> getDocumentDownloadUrl(String documentId) async {
    try {
      final token = await _client.getToken();
      if (token == null) {
        print('❌ No token available');
        return null;
      }

      // Just check if the document exists and is accessible
      final response = await http.head(
        Uri.parse('${ApiClient.baseUrl}/documents/$documentId/download'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 Download URL check: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Return the document ID - the caller will use it to download directly
        return documentId;
      } else if (response.statusCode == 404) {
        print('❌ Document not found');
        return null;
      } else if (response.statusCode == 401) {
        print('❌ Unauthorized');
        return null;
      } else {
        print('❌ Unknown error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Get download URL error: $e');
      return null;
    }
  }

  /// Download document directly and save to a file
  Future<String?> downloadDocumentToFile(String documentId, String savePath) async {
    try {
      final token = await _client.getToken();
      if (token == null) {
        print('❌ No token available');
        return null;
      }

      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/documents/$documentId/download'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 Download response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final file = File(savePath);
        await file.writeAsBytes(response.bodyBytes);
        print('✅ File saved to: $savePath');
        return savePath;
      } else {
        print('❌ Download failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Download error: $e');
      return null;
    }
  }

  /// Get document by ID (metadata only)
  Future<Map<String, dynamic>> getDocument(String documentId) async {
    try {
      final token = await _client.getToken();
      if (token == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }

      return await _client.request(
        method: 'GET',
        endpoint: '/documents/$documentId',
      );
    } catch (e) {
      return {
        'success': false,
        'error': 'Connection error: ${e.toString()}'
      };
    }
  }

  /// Get documents by file type
  Future<Map<String, dynamic>> getDocumentsByType(String fileType, {String? workspaceId}) async {
    final response = await getDocuments(workspaceId: workspaceId);

    if (response['success'] == true) {
      final documents = response['data'] as List;
      final filtered = documents.where((doc) =>
        doc['filetype']?.toLowerCase().contains(fileType.toLowerCase()) == true
      ).toList();
      return {'success': true, 'data': filtered};
    }

    return response;
  }

  /// Check if document exists
  Future<bool> documentExists(String documentId) async {
    try {
      final response = await getDocument(documentId);
      return response['success'] == true;
    } catch (e) {
      return false;
    }
  }
}
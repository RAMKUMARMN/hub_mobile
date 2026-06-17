// lib/services/api/document_api.dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_services.dart';

class DocumentApi {
  
  /// Get all documents (optionally filtered by workspace)
  static Future<Map<String, dynamic>> getDocuments({String? workspaceId}) async {
    try {
      return await ApiService.getDocuments(workspaceId: workspaceId);
    } catch (e) {
      return {
        'success': false, 
        'error': 'Failed to get documents: ${e.toString()}'
      };
    }
  }
  
  /// Upload a document to a workspace
  static Future<Map<String, dynamic>> uploadDocument({
    required File file,
    required String workspaceId,
    String? customFileName,
  }) async {
    try {
      final fileName = customFileName ?? file.path.split('/').last;
      
      return await ApiService.uploadDocument(
        filePath: file.path,
        fileName: fileName,
        workspaceId: workspaceId,
      );
    } catch (e) {
      return {
        'success': false, 
        'error': 'Upload failed: ${e.toString()}'
      };
    }
  }
  
  /// Delete a document by ID
  static Future<Map<String, dynamic>> deleteDocument(String documentId) async {
    try {
      final token = await ApiService.getToken();
      if (token == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }
      
      final response = await http.delete(
        Uri.parse("${ApiService.baseUrl}/documents/$documentId"),
        headers: await ApiService.getHeaders(),
      );
      
      if (response.statusCode == 200) {
        return {'success': true};
      } else if (response.statusCode == 404) {
        return {'success': false, 'error': 'Document not found'};
      } else if (response.statusCode == 401) {
        return {'success': false, 'error': 'Unauthorized'};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false, 
          'error': error['detail'] ?? 'Failed to delete document'
        };
      }
    } catch (e) {
      return {
        'success': false, 
        'error': 'Connection error: ${e.toString()}'
      };
    }
  }
  
  /// Get download URL for a document
  static Future<String?> getDocumentDownloadUrl(String documentId) async {
    try {
      final token = await ApiService.getToken();
      if (token == null) return null;
      
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/documents/$documentId/download"),
        headers: await ApiService.getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['download_url'] ?? data['url'];
      }
      return null;
    } catch (e) {
      print('Get download URL error: $e');
      return null;
    }
  }
  
  /// Download and save document to local storage
  static Future<String?> downloadDocument(String documentId, String savePath) async {
    try {
      final downloadUrl = await getDocumentDownloadUrl(documentId);
      if (downloadUrl == null) return null;
      
      final response = await http.get(Uri.parse(downloadUrl));
      
      if (response.statusCode == 200) {
        final file = File(savePath);
        await file.writeAsBytes(response.bodyBytes);
        return savePath;
      }
      return null;
    } catch (e) {
      print('Download document error: $e');
      return null;
    }
  }
  
  /// Get document by ID (metadata only)
  static Future<Map<String, dynamic>> getDocument(String documentId) async {
    try {
      final token = await ApiService.getToken();
      if (token == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }
      
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/documents/$documentId"),
        headers: await ApiService.getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else if (response.statusCode == 404) {
        return {'success': false, 'error': 'Document not found'};
      } else {
        return {'success': false, 'error': 'Failed to get document'};
      }
    } catch (e) {
      return {
        'success': false, 
        'error': 'Connection error: ${e.toString()}'
      };
    }
  }
  
  /// Get documents by file type
  static Future<Map<String, dynamic>> getDocumentsByType(String fileType, {String? workspaceId}) async {
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
  static Future<bool> documentExists(String documentId) async {
    try {
      final response = await getDocument(documentId);
      return response['success'] == true;
    } catch (e) {
      return false;
    }
  }
}
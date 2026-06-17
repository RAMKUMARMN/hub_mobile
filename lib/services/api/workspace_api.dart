// lib/services/api/workspace_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_services.dart';

class WorkspaceApi {
  // Use ApiService.baseUrl getter
  static String get baseUrl => ApiService.baseUrl;
  
  static Future<Map<String, dynamic>> getWorkspaces() async {
    return await ApiService.getWorkspaces();
  }
  
  static Future<Map<String, dynamic>> createWorkspace({
    required String name,
    String icon = '📁',
    String colorHex = '#0080FF',
  }) async {
    return await ApiService.createWorkspace(
      name: name,
      icon: icon,
      color: colorHex,
    );
  }
  
  static Future<Map<String, dynamic>> updateWorkspace({
    required String workspaceId,
    String? name,
    String? icon,
    String? colorHex,
  }) async {
    return await ApiService.updateWorkspace(
      workspaceId: workspaceId,
      name: name,
      icon: icon,
      color: colorHex,
    );
  }
  
  static Future<Map<String, dynamic>> deleteWorkspace(String workspaceId) async {
    return await ApiService.deleteWorkspace(workspaceId);
  }
  
  static Future<Map<String, dynamic>> getWorkspaceSummary(String workspaceId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/workspaces/$workspaceId/summary"),
        headers: await ApiService.getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'summary': data['summary']};
      }
      return {'success': false, 'error': 'Failed to get summary'};
    } catch (e) {
      return {'success': false, 'error': 'Connection error'};
    }
  }
}
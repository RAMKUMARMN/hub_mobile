// lib/services/api/workspace_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class WorkspaceService {
  final ApiClient _client = ApiClient();

  /// Get all workspaces
  Future<Map<String, dynamic>> getWorkspaces() async {
    return await _client.request(
      method: 'GET',
      endpoint: '/workspaces',
    );
  }

  /// Create a new workspace - ✅ HAS TRAILING SLASH
  Future<Map<String, dynamic>> createWorkspace({
    required String name,
    String icon = '📁',
    String colorHex = '#0080FF',
  }) async {
    return await _client.request(
      method: 'POST',
      endpoint: '/workspaces/',  // ← TRAILING SLASH
      body: {
        'name': name,
        'icon': icon,
        'color': colorHex,
      },
    );
  }

  /// Update an existing workspace
  Future<Map<String, dynamic>> updateWorkspace({
    required String workspaceId,
    String? name,
    String? icon,
    String? colorHex,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (icon != null) body['icon'] = icon;
    if (colorHex != null) body['color'] = colorHex;

    return await _client.request(
      method: 'PUT',
      endpoint: '/workspaces/$workspaceId',
      body: body,
    );
  }

  /// Delete a workspace
  Future<Map<String, dynamic>> deleteWorkspace(String workspaceId) async {
    return await _client.request(
      method: 'DELETE',
      endpoint: '/workspaces/$workspaceId',
    );
  }

  /// Get workspace summary
  Future<Map<String, dynamic>> getWorkspaceSummary(String workspaceId) async {
    try {
      final token = await _client.getToken();
      if (token == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }

      final response = await http.get(
        Uri.parse('${ApiClient.baseUrl}/workspaces/$workspaceId/summary'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'summary': data['summary']};
      }
      return {'success': false, 'error': 'Failed to get summary'};
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }
}
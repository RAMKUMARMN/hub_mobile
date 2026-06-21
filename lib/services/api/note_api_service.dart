// lib/services/api/note_api_service.dart
import 'api_client.dart';

class NoteApiService {
  final ApiClient _client = ApiClient();

// lib/services/api/note_api_service.dart
// lib/services/api/note_api_service.dart

Future<Map<String, dynamic>> getNotes({String? workspaceId}) async {
  final query = workspaceId != null ? '?workspace_id=$workspaceId' : '';
  final response = await _client.request(
    method: 'GET',
    endpoint: '/notes$query',
  );
  
  print('📝 Raw notes response: $response');  // Debug
  
  if (response['success'] == true) {
    final data = response['data'];
    
    // ✅ Handle both List and Map responses
    if (data is List) {
      return {'success': true, 'data': data};
    } else if (data is Map) {
      // If it's a Map, try to extract notes
      final notes = data['notes'] ?? [];
      return {'success': true, 'data': notes};
    } else {
      return {'success': false, 'error': 'Unexpected response format'};
    }
  }
  return response;
}
  /// Create a new note - ✅ HAS TRAILING SLASH
  Future<Map<String, dynamic>> createNote({
    required String title,
    String? content,
    List<String>? tags,
    required String workspaceId,
  }) async {
    return await _client.request(
      method: 'POST',
      endpoint: '/notes/',  // ← TRAILING SLASH
      body: {
        'workspace_id': workspaceId,
        'title': title,
        'content': content,
        'tags': tags ?? [],
      },
    );
  }

  /// Update an existing note
  Future<Map<String, dynamic>> updateNote({
    required String noteId,
    String? title,
    String? content,
    List<String>? tags,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (content != null) body['content'] = content;
    if (tags != null) body['tags'] = tags;

    return await _client.request(
      method: 'PUT',
      endpoint: '/notes/$noteId',
      body: body,
    );
  }

  /// Delete a note
  Future<Map<String, dynamic>> deleteNote(String noteId) async {
    return await _client.request(
      method: 'DELETE',
      endpoint: '/notes/$noteId',
    );
  }
}
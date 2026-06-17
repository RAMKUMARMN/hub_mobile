// lib/services/api/note_api.dart
import 'api_services.dart';

class NoteApi {
  static Future<Map<String, dynamic>> getNotes({String? workspaceId}) async {
    return await ApiService.getNotes(workspaceId: workspaceId);
  }
  
  static Future<Map<String, dynamic>> createNote({
    required String title,
    String? content,
    List<String>? tags,
    required String workspaceId,
  }) async {
    return await ApiService.createNote(
      workspaceId: workspaceId,
      title: title,
      content: content,
      tags: tags,
    );
  }
  
  static Future<Map<String, dynamic>> updateNote({
    required String noteId,
    String? title,
    String? content,
    List<String>? tags,
  }) async {
    return await ApiService.updateNote(
      noteId: noteId,
      title: title,
      content: content,
      tags: tags,
    );
  }
  
  static Future<Map<String, dynamic>> deleteNote(String noteId) async {
    return await ApiService.deleteNote(noteId);
  }
}
// lib/services/api/api_services.dart
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_config.dart';

class ApiService {
  // This must be a static getter, not a const
  static String get baseUrl => AppConfig.apiBaseUrl;
  static const int apiTimeoutSeconds = 120;
  
  /// Get auth token from storage
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
  
  /// Get headers with authorization
  static Future<Map<String, String>> getHeaders({bool includeAuth = true}) async {
    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
    };
    
    if (includeAuth) {
      final token = await getToken();
      if (token != null) {
        headers["Authorization"] = "Bearer $token";
      }
    }
    
    return headers;
  }

  // ============ AI CHAT WITH STREAMING ============
  
  /// Send chat message with streaming response (for better perceived performance)
  // lib/services/api/api_services.dart

  static Future<void> sendChatMessageStream({
    required String prompt,
    required void Function(String chunk) onChunk,
    String? workspaceId,
    String? chatId,
  }) async {
    try {
      final body = <String, dynamic>{
        "prompt": prompt,
      };
      if (workspaceId != null) body["workspace_id"] = workspaceId;
      if (chatId != null) body["chat_id"] = chatId;
      
      final request = http.Request(
        'POST',
        Uri.parse("${ApiService.baseUrl}/ai/chat/stream"),  // ← Changed to /stream
      );
      
      final headers = await ApiService.getHeaders();
      request.headers.addAll(headers);
      request.body = jsonEncode(body);
      
      final response = await request.send();
      
      if (response.statusCode == 200) {
        final stream = response.stream.transform(utf8.decoder);
        
        await for (var chunk in stream) {
          final lines = chunk.split('\n');
          for (var line in lines) {
            line = line.trim();
            if (line.isNotEmpty) {
              try {
                final data = jsonDecode(line);
                if (data['response'] != null) {
                  onChunk(data['response']);
                }
              } catch (e) {
                // If not JSON, send as is (for error messages)
                if (line.startsWith('Error:')) {
                  onChunk(line);
                }
              }
            }
          }
        }
      } else {
        onChunk("Error: Server returned ${response.statusCode}");
      }
    } catch (e) {
      onChunk("Error: ${e.toString()}");
    }
  }

  // ============ AI CHAT (NON-STREAMING) ============
  
  /// Send chat message without streaming (simpler)
  static Future<Map<String, dynamic>> sendChatMessage({
    required String prompt,
    String? workspaceId,
    String? chatId,
  }) async {
    try {
      final body = <String, dynamic>{
        "prompt": prompt,
      };
      if (workspaceId != null) body["workspace_id"] = workspaceId;
      if (chatId != null) body["chat_id"] = chatId;
      
      final response = await http.post(
        Uri.parse("${ApiService.baseUrl}/ai/chat"),
        headers: await getHeaders(),
        body: jsonEncode(body),
      ).timeout(Duration(seconds: apiTimeoutSeconds));  // ← ADD THIS
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'response': data['response'],
          'chat_id': data['chat_id'],
        };
      }
      return {'success': false, 'error': 'AI service error'};
    } catch (e) {
      if (e is TimeoutException) {
        return {'success': false, 'error': 'Request timed out. The AI is taking too long to respond.'};
      }
      return {'success': false, 'error': 'Connection error: ${e.toString()}'};
    }
  }

  // ============ AUTHENTICATION ============

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiService.baseUrl}/auth/login"),
        headers: await getHeaders(includeAuth: false),
        body: jsonEncode({"email": email, "password": password}),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'token': data['access_token'],
          'user_id': data['user']['id'],
          'name': data['user']['name'],
          'email': data['user']['email'],
        };
      }
      
      final error = jsonDecode(response.body);
      return {'success': false, 'error': error['detail'] ?? 'Login failed'};
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiService.baseUrl}/auth/register"),
        headers: await getHeaders(includeAuth: false),
        body: jsonEncode({"name": name, "email": email, "password": password}),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'token': data['access_token'],
          'user_id': data['user']['id'],
          'name': data['user']['name'],
          'email': data['user']['email'],
        };
      }
      
      final error = jsonDecode(response.body);
      return {'success': false, 'error': error['detail'] ?? 'Registration failed'};
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/auth/me"),
        headers: await getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      }
      return {'success': false, 'error': 'Failed to load profile'};
    } catch (e) {
      return {'success': false, 'error': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? email,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (email != null) body['email'] = email;
      
      final response = await http.put(
        Uri.parse("${ApiService.baseUrl}/auth/profile"),
        headers: await getHeaders(),
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false, 'error': 'Update failed'};
    } catch (e) {
      return {'success': false, 'error': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiService.baseUrl}/auth/change-password"),
        headers: await getHeaders(),
        body: jsonEncode({
          "current_password": currentPassword,
          "new_password": newPassword,
        }),
      );
      
      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false, 'error': 'Password change failed'};
    } catch (e) {
      return {'success': false, 'error': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final response = await http.delete(
        Uri.parse("${ApiService.baseUrl}/auth/account"),
        headers: await getHeaders(),
      );
      
      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false, 'error': 'Account deletion failed'};
    } catch (e) {
      return {'success': false, 'error': 'Connection error'};
    }
  }

  // ============ WORKSPACES ============

  static Future<Map<String, dynamic>> getWorkspaces() async {
    try {
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/workspaces"),
        headers: await getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      }
      return {'success': false, 'error': 'Failed to load workspaces'};
    } catch (e) {
      return {'success': false, 'error': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> createWorkspace({
    required String name,
    String icon = '📁',
    String color = '#0080FF',
  }) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiService.baseUrl}/workspaces"),
        headers: await getHeaders(),
        body: jsonEncode({
          "name": name,
          "icon": icon,
          "color": color,
        }),
      );
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      }
      return {'success': false, 'error': 'Failed to create workspace'};
    } catch (e) {
      return {'success': false, 'error': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> updateWorkspace({
    required String workspaceId,
    String? name,
    String? icon,
    String? color,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (icon != null) body['icon'] = icon;
      if (color != null) body['color'] = color;
      
      final response = await http.put(
        Uri.parse("${ApiService.baseUrl}/workspaces/$workspaceId"),
        headers: await getHeaders(),
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false, 'error': 'Failed to update workspace'};
    } catch (e) {
      return {'success': false, 'error': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> deleteWorkspace(String workspaceId) async {
    try {
      final response = await http.delete(
        Uri.parse("${ApiService.baseUrl}/workspaces/$workspaceId"),
        headers: await getHeaders(),
      );
      
      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false, 'error': 'Failed to delete workspace'};
    } catch (e) {
      return {'success': false, 'error': 'Connection error'};
    }
  }

  // ============ TASKS ============

  static Future<Map<String, dynamic>> getTasks({String? workspaceId}) async {
    try {
      final queryParams = workspaceId != null ? '?workspace_id=$workspaceId' : '';
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/tasks$queryParams"),
        headers: await getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Backend returns { "total": X, "tasks": [...] }
        final tasks = data['tasks'] ?? [];
        return {'success': true, 'data': tasks};
      }
      return {'success': false, 'error': 'Failed to load tasks'};
    } catch (e) {
      return {'success': false, 'error': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> createTask({
    required String workspaceId,
    required String title,
    String? description,
    String priority = 'medium',
    DateTime? dueDate,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiService.baseUrl}/tasks"),
        headers: await getHeaders(),
        body: jsonEncode({
          "workspace_id": workspaceId,
          "title": title,
          "description": description,
          "priority": priority,
          "due_date": dueDate?.toIso8601String(),
        }),
      );
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      }
      return {'success': false, 'error': 'Failed to create task'};
    } catch (e) {
      return {'success': false, 'error': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> updateTask({
    required String taskId,
    String? title,
    String? description,
    String? priority,
    String? status,
    DateTime? dueDate,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (title != null) body['title'] = title;
      if (description != null) body['description'] = description;
      if (priority != null) body['priority'] = priority;
      if (status != null) body['status'] = status;
      if (dueDate != null) body['due_date'] = dueDate.toIso8601String();
      
      final response = await http.put(
        Uri.parse("${ApiService.baseUrl}/tasks/$taskId"),
        headers: await getHeaders(),
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false, 'error': 'Failed to update task'};
    } catch (e) {
      return {'success': false, 'error': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> deleteTask(String taskId) async {
    try {
      final response = await http.delete(
        Uri.parse("${ApiService.baseUrl}/tasks/$taskId"),
        headers: await getHeaders(),
      );
      
      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false, 'error': 'Failed to delete task'};
    } catch (e) {
      return {'success': false, 'error': 'Connection error'};
    }
  }

  // ============ NOTES ============

  static Future<Map<String, dynamic>> getNotes({String? workspaceId}) async {
    try {
      final url = workspaceId != null 
          ? Uri.parse("${ApiService.baseUrl}/notes?workspace_id=$workspaceId")
          : Uri.parse("${ApiService.baseUrl}/notes");
          
      final response = await http.get(url, headers: await getHeaders());
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data['notes'] ?? []};
      }
      return {'success': false, 'error': 'Failed to load notes'};
    } catch (e) {
      return {'success': false, 'error': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> createNote({
    required String workspaceId,
    required String title,
    String? content,
    List<String>? tags,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiService.baseUrl}/notes"),
        headers: await getHeaders(),
        body: jsonEncode({
          "workspace_id": workspaceId,
          "title": title,
          "content": content,
          "tags": tags ?? [],
        }),
      );
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      }
      return {'success': false, 'error': 'Failed to create note'};
    } catch (e) {
      return {'success': false, 'error': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> updateNote({
    required String noteId,
    String? title,
    String? content,
    List<String>? tags,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (title != null) body['title'] = title;
      if (content != null) body['content'] = content;
      if (tags != null) body['tags'] = tags;
      
      final response = await http.put(
        Uri.parse("${ApiService.baseUrl}/notes/$noteId"),
        headers: await getHeaders(),
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false, 'error': 'Failed to update note'};
    } catch (e) {
      return {'success': false, 'error': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> deleteNote(String noteId) async {
    try {
      final response = await http.delete(
        Uri.parse("${ApiService.baseUrl}/notes/$noteId"),
        headers: await getHeaders(),
      );
      
      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false, 'error': 'Failed to delete note'};
    } catch (e) {
      return {'success': false, 'error': 'Connection error'};
    }
  }

  // ============ AI CHAT (NON-STREAMING) ============
  // Keep the non-streaming version as fallback

  static Future<Map<String, dynamic>> getChats({String? workspaceId}) async {
    try {
      final url = workspaceId != null 
          ? Uri.parse("${ApiService.baseUrl}/ai/chats?workspace_id=$workspaceId")
          : Uri.parse("${ApiService.baseUrl}/ai/chats");
          
      final response = await http.get(url, headers: await getHeaders());
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      }
      return {'success': false, 'error': 'Failed to load chats'};
    } catch (e) {
      return {'success': false, 'error': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> getDailyInsight() async {
    try {
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/ai/daily-insight"),
        headers: await getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'insight': data['insight']};
      }
      return {'success': false, 'error': 'Failed to get insight'};
    } catch (e) {
      return {'success': false, 'error': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> getWeeklyReport() async {
    try {
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/ai/weekly-report"),
        headers: await getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'report': data['report']};
      }
      return {'success': false, 'error': 'Failed to get report'};
    } catch (e) {
      return {'success': false, 'error': 'Connection error'};
    }
  }

  // ============ DOCUMENTS ============

  static Future<Map<String, dynamic>> getDocuments({String? workspaceId}) async {
    try {
      final url = workspaceId != null 
          ? Uri.parse("${ApiService.baseUrl}/documents?workspace_id=$workspaceId")
          : Uri.parse("${ApiService.baseUrl}/documents");
          
      final response = await http.get(url, headers: await getHeaders());
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      }
      return {'success': false, 'error': 'Failed to load documents'};
    } catch (e) {
      return {'success': false, 'error': 'Connection error'};
    }
  }

  static Future<Map<String, dynamic>> uploadDocument({
  required String filePath,
  required String fileName,
  required String workspaceId,
}) async {
  try {
    final token = await getToken();
    if (token == null) {
      return {'success': false, 'error': 'Not authenticated'};
    }
    
    var request = http.MultipartRequest(
      'POST',
      Uri.parse("${ApiService.baseUrl}/documents/upload"),
    );
    
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['workspace_id'] = workspaceId;  // Send as form field
    request.files.add(await http.MultipartFile.fromPath('file', filePath, filename: fileName));
    
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
    return {'success': false, 'error': 'Connection error: ${e.toString()}'};
  }
}

  // ============ SEARCH ============

  static Future<Map<String, dynamic>> search(String query) async {
    try {
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/search?q=${Uri.encodeComponent(query)}"),
        headers: await getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'results': data['results'] ?? []};
      }
      return {'success': false, 'error': 'Search failed'};
    } catch (e) {
      return {'success': false, 'error': 'Connection error'};
    }
  }

  // lib/services/api/api_services.dart - Add these methods

// Add this method to handle all API requests uniformly
static Future<Map<String, dynamic>> makeRequest({
  required String method,
  required String endpoint,
  Map<String, dynamic>? body,
  Map<String, String>? customHeaders,
}) async {
  try {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await getHeaders();
    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }
    
    http.Response response;
    
    switch (method.toUpperCase()) {
      case 'GET':
        response = await http.get(url, headers: headers);
        break;
      case 'POST':
        response = await http.post(
          url,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
        break;
      case 'PUT':
        response = await http.put(
          url,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
        break;
      case 'DELETE':
        response = await http.delete(url, headers: headers);
        break;
      default:
        return {'success': false, 'error': 'Unsupported method'};
    }
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      return {'success': true, 'data': data};
    } else {
      final error = jsonDecode(response.body);
      return {'success': false, 'error': error['detail'] ?? 'Request failed'};
    }
  } catch (e) {
    return {'success': false, 'error': 'Connection error: $e'};
  }
}

}
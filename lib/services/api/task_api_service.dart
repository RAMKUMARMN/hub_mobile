// lib/services/api/task_api_service.dart
import 'api_client.dart';
import '../../models/workspace_items/task.dart';
import 'package:logger/logger.dart';


class TaskApiService {
  final ApiClient _client = ApiClient();
  final logger = Logger();

  /// Get all tasks (optionally filtered by workspace)
  // lib/services/api/task_api_service.dart

// lib/services/api/task_api_service.dart

Future<Map<String, dynamic>> getTasks({String? workspaceId}) async {
  final query = workspaceId != null ? '?workspace_id=$workspaceId' : '';
  final response = await _client.request(
    method: 'GET',
    endpoint: '/tasks$query',
  );
  
  logger.d('📝 Raw tasks response: $response');  // Debug
  
  if (response['success'] == true) {
    final data = response['data'];
    
    // ✅ Handle both List and Map responses
    if (data is List) {
      return {'success': true, 'data': data};
    } else if (data is Map) {
      final tasks = data['tasks'] ?? [];
      return {'success': true, 'data': tasks};
    } else {
      return {'success': false, 'error': 'Unexpected response format'};
    }
  }
  return response;
}

  /// Create a new task - ✅ HAS TRAILING SLASH
  Future<Map<String, dynamic>> createTask({
    required String title,
    String? description,
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
    DateTime? reminderAt,
    required String workspaceId,
  }) async {
    final body = {
      'workspace_id': workspaceId,
      'title': title,
      'description': description,
      'priority': priority.apiValue,  // "MEDIUM", "LOW", etc.
      'deadline': dueDate?.toIso8601String(),
    };

    if (reminderAt != null) {
      body['reminder_at'] = reminderAt.toIso8601String();
    }

    return await _client.request(
      method: 'POST',
      endpoint: '/tasks/',  // ← TRAILING SLASH - FIXED!
      body: body,
    );
  }

  /// Update an existing task
  Future<Map<String, dynamic>> updateTask({
    required String taskId,
    String? title,
    String? description,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? dueDate,
    DateTime? reminderAt,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (priority != null) body['priority'] = priority.apiValue;
    if (status != null) body['status'] = status.apiValue;
    if (dueDate != null) body['deadline'] = dueDate.toIso8601String();  // ✅ FIXED
    if (reminderAt != null) body['reminder_at'] = reminderAt.toIso8601String();

    return await _client.request(
      method: 'PUT',
      endpoint: '/tasks/$taskId',
      body: body,
    );
  }

  /// Delete a task
  Future<Map<String, dynamic>> deleteTask(String taskId) async {
    return await _client.request(
      method: 'DELETE',
      endpoint: '/tasks/$taskId',
    );
  }

  /// Mark a task as completed
  Future<Map<String, dynamic>> completeTask(String taskId) async {
    return await updateTask(
      taskId: taskId,
      status: TaskStatus.completed,
    );
  }
}
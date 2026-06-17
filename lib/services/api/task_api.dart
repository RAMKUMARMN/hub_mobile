// lib/services/api/task_api.dart

import 'api_services.dart';
import '../../models/workspace_items/task.dart';

class TaskApi {
  static Future<Map<String, dynamic>> getTasks({String? workspaceId}) async {
    return await ApiService.getTasks(workspaceId: workspaceId);
  }
  
  static Future<Map<String, dynamic>> createTask({
    required String title,
    String? description,
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
    DateTime? reminderAt,
    required String workspaceId,
  }) async {
    final body = {
      "workspace_id": workspaceId,
      "title": title,
      "description": description,
      "priority": priority.apiValue,
      "due_date": dueDate?.toIso8601String(),
    };
    
    // Only add reminder_at if provided
    if (reminderAt != null) {
      body["reminder_at"] = reminderAt.toIso8601String();
    }
    
    try {
      final response = await ApiService.makeRequest(
        method: 'POST',
        endpoint: '/tasks',
        body: body,
      );
      return response;
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  static Future<Map<String, dynamic>> updateTask({
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
    if (dueDate != null) body['due_date'] = dueDate.toIso8601String();
    if (reminderAt != null) body['reminder_at'] = reminderAt.toIso8601String();
    
    try {
      final response = await ApiService.makeRequest(
        method: 'PUT',
        endpoint: '/tasks/$taskId',
        body: body,
      );
      return response;
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  static Future<Map<String, dynamic>> deleteTask(String taskId) async {
    return await ApiService.deleteTask(taskId);
  }
  
  static Future<Map<String, dynamic>> completeTask(String taskId) async {
    return await updateTask(
      taskId: taskId,
      status: TaskStatus.completed,
    );
  }
}
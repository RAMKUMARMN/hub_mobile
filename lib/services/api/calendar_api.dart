// lib/services/api/calendar_api.dart

import 'api_services.dart';
import '../../models/calendar_event.dart';

class CalendarApi {
  static Future<Map<String, dynamic>> getEvents({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final queryParams = '?start_date=${startDate.toIso8601String()}&end_date=${endDate.toIso8601String()}';
    return await ApiService.makeRequest(
      method: 'GET',
      endpoint: '/calendar/events$queryParams',
    );
  }
  
  static Future<Map<String, dynamic>> createEvent({
    required String title,
    required DateTime startTime,
    DateTime? endTime,
    bool isAllDay = false,
    String? description,
    String? linkedTodoId,
    String notificationMode = 'TIME_BASED',
  }) async {
    final body = {
      'title': title,
      'start_time': startTime.toIso8601String(),
      'is_all_day': isAllDay,
      'notification_mode': notificationMode,
    };
    
    if (endTime != null) body['end_time'] = endTime.toIso8601String();
    if (description != null) body['description'] = description;
    if (linkedTodoId != null) body['linked_todo_id'] = linkedTodoId;
    
    return await ApiService.makeRequest(
      method: 'POST',
      endpoint: '/calendar/events',
      body: body,
    );
  }
  
  static Future<Map<String, dynamic>> updateEvent({
    required String eventId,
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    bool? isAllDay,
    String? description,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (startTime != null) body['start_time'] = startTime.toIso8601String();
    if (endTime != null) body['end_time'] = endTime.toIso8601String();
    if (isAllDay != null) body['is_all_day'] = isAllDay;
    if (description != null) body['description'] = description;
    
    return await ApiService.makeRequest(
      method: 'PUT',
      endpoint: '/calendar/events/$eventId',
      body: body,
    );
  }
  
  static Future<Map<String, dynamic>> deleteEvent(String eventId) async {
    return await ApiService.makeRequest(
      method: 'DELETE',
      endpoint: '/calendar/events/$eventId',
    );
  }
}
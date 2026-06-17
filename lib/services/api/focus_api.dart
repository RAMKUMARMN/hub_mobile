// lib/services/api/focus_api.dart

import 'api_services.dart';

class FocusApi {
  static Future<Map<String, dynamic>> startSession({
    required int durationSeconds,
    int? intervalSeconds,
    String? goalDescription,
  }) async {
    final body = <String, dynamic>{
      'duration_seconds': durationSeconds,
    };
    if (intervalSeconds != null) body['interval_seconds'] = intervalSeconds;
    if (goalDescription != null && goalDescription.isNotEmpty) {
      body['goal_description'] = goalDescription;
    }
    
    return await ApiService.makeRequest(
      method: 'POST',
      endpoint: '/focus/sessions',
      body: body,
    );
  }
  
  static Future<Map<String, dynamic>> completeSession({
    required String sessionId,
    List<Map<String, dynamic>>? milestonePayload,
  }) async {
    final body = <String, dynamic>{};
    if (milestonePayload != null && milestonePayload.isNotEmpty) {
      body['milestone_payload'] = milestonePayload;
    }
    
    return await ApiService.makeRequest(
      method: 'PATCH',
      endpoint: '/focus/sessions/$sessionId/complete',
      body: body,
    );
  }
  
  static Future<Map<String, dynamic>> pauseSession({
    required String sessionId,
  }) async {
    return await ApiService.makeRequest(
      method: 'PATCH',
      endpoint: '/focus/sessions/$sessionId/pause',
      body: {},
    );
  }
  
  static Future<Map<String, dynamic>> resumeSession({
    required String sessionId,
  }) async {
    return await ApiService.makeRequest(
      method: 'PATCH',
      endpoint: '/focus/sessions/$sessionId/resume',
      body: {},
    );
  }
  
  static Future<Map<String, dynamic>> abandonSession({
    required String sessionId,
  }) async {
    return await ApiService.makeRequest(
      method: 'PATCH',
      endpoint: '/focus/sessions/$sessionId/abandon',
      body: {},
    );
  }
  
  static Future<Map<String, dynamic>> getSessions({
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
  }) async {
    final params = <String, String>{};
    if (fromDate != null) params['from_date'] = fromDate.toIso8601String();
    if (toDate != null) params['to_date'] = toDate.toIso8601String();
    if (limit != null) params['limit'] = limit.toString();
    
    final queryString = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    final endpoint = queryString.isEmpty ? '/focus/sessions' : '/focus/sessions?$queryString';
    
    return await ApiService.makeRequest(
      method: 'GET',
      endpoint: endpoint,
    );
  }
  
  static Future<Map<String, dynamic>> getSession(String sessionId) async {
    return await ApiService.makeRequest(
      method: 'GET',
      endpoint: '/focus/sessions/$sessionId',
    );
  }
  
  static Future<Map<String, dynamic>> getTodayStats() async {
    return await ApiService.makeRequest(
      method: 'GET',
      endpoint: '/focus/stats/today',
    );
  }
  
  static Future<Map<String, dynamic>> getWeeklyStats() async {
    return await ApiService.makeRequest(
      method: 'GET',
      endpoint: '/focus/stats/weekly',
    );
  }
}
// lib/services/api/focus_service.dart
import 'api_client.dart';

class FocusService {
  final ApiClient _client = ApiClient();

  /// Start a new focus session
  Future<Map<String, dynamic>> startSession({
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
    
    return await _client.request(
      method: 'POST',
      endpoint: '/focus/sessions',
      body: body,
    );
  }

  /// Complete a focus session
  Future<Map<String, dynamic>> completeSession({
    required String sessionId,
    List<Map<String, dynamic>>? milestonePayload,
  }) async {
    final body = <String, dynamic>{};
    if (milestonePayload != null && milestonePayload.isNotEmpty) {
      body['milestone_payload'] = milestonePayload;
    }
    
    return await _client.request(
      method: 'PATCH',
      endpoint: '/focus/sessions/$sessionId/complete',
      body: body,
    );
  }

  /// Pause a focus session
  Future<Map<String, dynamic>> pauseSession({
    required String sessionId,
  }) async {
    return await _client.request(
      method: 'PATCH',
      endpoint: '/focus/sessions/$sessionId/pause',
      body: {},
    );
  }

  /// Resume a paused focus session
  Future<Map<String, dynamic>> resumeSession({
    required String sessionId,
  }) async {
    return await _client.request(
      method: 'PATCH',
      endpoint: '/focus/sessions/$sessionId/resume',
      body: {},
    );
  }

  /// Abandon/cancel a focus session
  Future<Map<String, dynamic>> abandonSession({
    required String sessionId,
  }) async {
    return await _client.request(
      method: 'PATCH',
      endpoint: '/focus/sessions/$sessionId/abandon',
      body: {},
    );
  }

  /// Get all focus sessions with optional filters
  Future<Map<String, dynamic>> getSessions({
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
    
    return await _client.request(
      method: 'GET',
      endpoint: endpoint,
    );
  }

  /// Get a single focus session by ID
  Future<Map<String, dynamic>> getSession(String sessionId) async {
    return await _client.request(
      method: 'GET',
      endpoint: '/focus/sessions/$sessionId',
    );
  }

  /// Get today's focus stats
  Future<Map<String, dynamic>> getTodayStats() async {
    return await _client.request(
      method: 'GET',
      endpoint: '/focus/stats/today',
    );
  }

  /// Get weekly focus stats
  Future<Map<String, dynamic>> getWeeklyStats() async {
    return await _client.request(
      method: 'GET',
      endpoint: '/focus/stats/weekly',
    );
  }
}
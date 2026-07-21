// lib/services/ai/ai_services.dart
import '../api/api_client.dart';

class AIService {
  final ApiClient _client = ApiClient();

  /// Create a new backend chat session and return the session ID (UUID string).
  Future<String> createSession({String title = 'New Chat'}) async {
    final response = await _client.request(
      method: 'POST',
      endpoint: '/chat/sessions',
      body: {'title': title},
    );

    if (response['success'] == true) {
      final data = response['data'];
      final id = data['id']?.toString();
      if (id != null && id.isNotEmpty) return id;
    }
    throw Exception('Failed to create chat session: ${response['error']}');
  }

  /// Send a message to a backend session and stream the response.
  ///
  /// SSE events from the backend:
  ///   {"sources": [...]}                — RAG source citations (optional, first)
  ///   {"thinking": "..."}              — DeepSeek reasoning token
  ///   {"delta": "..."}                 — Answer token
  ///   {"status": "..."}                — Status update (optional)
  ///   data: [DONE]                     — Stream complete
  ///
  /// [onDelta]    — called for each answer token (the main content)
  /// [onThinking] — called for each reasoning token (optional)
  /// [onSources]  — called once with RAG source list (optional)
  /// [onStatus]   — called for status/progress updates (optional)
  Future<void> sendMessageStream({
    required String sessionId,
    required String message,
    required void Function(String chunk) onDelta,
    void Function(String chunk)? onThinking,
    void Function(List<dynamic> sources)? onSources,
    void Function(String status)? onStatus,
    bool useRag = false,
    bool thinkingMode = false,
  }) async {
    await _client.streamSseRequest(
      endpoint: '/chat/sessions/$sessionId/messages',
      body: {
        'content': message,
        'use_rag': useRag,
        'thinking_mode': thinkingMode,
      },
      onDelta: onDelta,
      onThinking: onThinking,
      onSources: onSources,
      onStatus: onStatus,
    );
  }

  /// List all chat sessions for the authenticated user.
  Future<List<Map<String, dynamic>>> listSessions() async {
    final response = await _client.request(
      method: 'GET',
      endpoint: '/chat/sessions',
    );
    if (response['success'] == true) {
      final data = response['data'];
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
    }
    return [];
  }

  /// Delete a chat session by its UUID.
  Future<void> deleteSession(String sessionId) async {
    await _client.request(
      method: 'DELETE',
      endpoint: '/chat/sessions/$sessionId',
    );
  }

  /// Get message history for a session.
  Future<List<Map<String, dynamic>>> getMessages(String sessionId) async {
    final response = await _client.request(
      method: 'GET',
      endpoint: '/chat/sessions/$sessionId/messages',
    );
    if (response['success'] == true) {
      final data = response['data'];
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
    }
    return [];
  }
}
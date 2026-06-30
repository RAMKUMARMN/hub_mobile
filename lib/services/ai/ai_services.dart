// lib/services/ai/ai_services.dart
import '../api/api_client.dart';

class AIService {
  final ApiClient _client = ApiClient();

  // ============ SESSION MANAGEMENT ============

  /// Create a new chat session on the backend
  Future<Map<String, dynamic>> createSession({String title = 'New Chat'}) async {
    return await _client.request(
      method: 'POST',
      endpoint: '/chat/sessions',
      body: {'title': title},
    );
  }

  /// List all chat sessions for the current user
  Future<Map<String, dynamic>> listSessions() async {
    return await _client.request(
      method: 'GET',
      endpoint: '/chat/sessions',
    );
  }

  /// Delete a chat session
  Future<Map<String, dynamic>> deleteSession(String sessionId) async {
    return await _client.request(
      method: 'DELETE',
      endpoint: '/chat/sessions/$sessionId',
    );
  }

  /// Fetch all messages for a given session
  Future<Map<String, dynamic>> getSessionMessages(String sessionId) async {
    return await _client.request(
      method: 'GET',
      endpoint: '/chat/sessions/$sessionId/messages',
    );
  }

  // ============ STREAMING CHAT ============

  /// Send a message to AI with streaming. Dispatches events via onEvent callback.
  /// onEvent receives a parsed map which may contain keys:
  ///   - 'delta'    : token to append to the final answer
  ///   - 'thinking' : token to append to the reasoning/thought block
  ///   - 'sources'  : list of RAG document citations
  ///   - 'status'   : intermediate status string (e.g., "Searching the web...")
  ///   - 'error'    : error string
  Future<void> sendMessageStream({
    required String sessionId,
    required String message,
    required void Function(Map<String, dynamic> event) onEvent,
    bool useRag = false,
    bool useHyde = false,
    bool webSearch = false,
    bool thinkingMode = true,
    String retrievalMode = 'semantic',
    int ragChunkLimit = 4,
    bool useReranker = false,
    List<String>? documentIds,
  }) async {
    final body = <String, dynamic>{
      'content': message,
      'use_rag': useRag,
      'use_hyde': useHyde,
      'web_search': webSearch,
      'thinking_mode': thinkingMode,
      'retrieval_mode': retrievalMode,
      'rag_chunk_limit': ragChunkLimit,
      'use_reranker': useReranker,
    };
    if (documentIds != null && documentIds.isNotEmpty) {
      body['document_ids'] = documentIds;
    }

    await _client.streamRequest(
      endpoint: '/chat/sessions/$sessionId/messages',
      body: body,
      onChunk: onEvent,
    );
  }

  /// Send a message to AI (non-streaming helper).
  /// Creates a temporary chat session, streams the response internally to accumulate it,
  /// and deletes the session afterwards.
  Future<String> sendMessage(String message, {String? workspaceId}) async {
    try {
      final sessionResp = await createSession(title: 'Temp Suggestion Session');
      if (sessionResp['success'] != true) {
        return 'Error: Failed to create temporary session.';
      }
      final sessionId = sessionResp['data']['id'].toString();

      StringBuffer responseBuffer = StringBuffer();
      await sendMessageStream(
        sessionId: sessionId,
        message: message,
        thinkingMode: false,
        onEvent: (event) {
          if (event.containsKey('delta')) {
            responseBuffer.write(event['delta'] as String? ?? '');
          }
        },
      );

      deleteSession(sessionId).catchError((_) => <String, dynamic>{});

      final result = responseBuffer.toString().trim();
      return result.isNotEmpty ? result : 'No response from AI';
    } catch (e) {
      return 'Error: ${e.toString()}';
    }
  }

  // ============ UTILITY ============

  /// Generate a short title from the first user message (client-side fallback)
  String generateLocalTitle(String firstMessage) {
    if (firstMessage.length > 30) {
      return '${firstMessage.substring(0, 27)}...';
    }
    return firstMessage;
  }
}
// lib/services/ai/ai_services.dart
import '../api/index.dart';
import '../api/api_client.dart';

class AIService {
  final ApiClient _client = ApiClient();

  /// Send a message to AI with streaming
  // lib/services/ai/ai_services.dart

Future<void> sendMessageStream({
  required String message,
  required void Function(String chunk) onChunk,
  String? workspaceId,
  String? chatId,
}) async {
  final body = {
    'prompt': message,
    if (workspaceId != null) 'workspace_id': workspaceId,
    // ✅ Only include chat_id if it's not null and looks like a UUID
    if (chatId != null && chatId.isNotEmpty) 'chat_id': chatId,
  };
  
  await _client.streamRequest(
    endpoint: '/ai/chat/stream',
    body: body,
    onChunk: onChunk,
  );
}

  /// Send a message to AI (non-streaming)
  Future<String> sendMessage(String message, {String? workspaceId}) async {
    final response = await _client.request(
      method: 'POST',
      endpoint: '/ai/chat',
      body: {
        'prompt': message,
        if (workspaceId != null) 'workspace_id': workspaceId,
      },
    );
    
    if (response['success'] == true) {
      return response['data']['response'] ?? 'No response from AI';
    }
    return response['error'] ?? 'Failed to get response';
  }
  
  /// Generate a title from the first message
  Future<String> generateTitle(String firstMessage) async {
    // Simple title generation - you can enhance this
    if (firstMessage.length > 30) {
      return '${firstMessage.substring(0, 27)}...';
    }
    return firstMessage;
  }
  
  /// Get daily insight
  Future<Map<String, dynamic>> getDailyInsight() async {
    final response = await _client.request(
      method: 'GET',
      endpoint: '/ai/daily-insight',
    );
    
    if (response['success'] == true) {
      return response['data'];
    }
    return {'error': response['error'] ?? 'Failed to get insight'};
  }
  
  /// Get weekly report
  Future<Map<String, dynamic>> getWeeklyReport() async {
    final response = await _client.request(
      method: 'GET',
      endpoint: '/ai/weekly-report',
    );
    
    if (response['success'] == true) {
      return response['data'];
    }
    return {'error': response['error'] ?? 'Failed to get report'};
  }
  
  /// Get chat history
  Future<Map<String, dynamic>> getChats({String? workspaceId}) async {
    final query = workspaceId != null ? '?workspace_id=$workspaceId' : '';
    final response = await _client.request(
      method: 'GET',
      endpoint: '/ai/chats$query',
    );
    
    if (response['success'] == true) {
      return response['data'];
    }
    return {'error': response['error'] ?? 'Failed to get chats'};
  }
}
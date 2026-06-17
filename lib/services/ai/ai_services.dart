// lib/services/ai/ai_services.dart
import '../api/api_services.dart';

class AIService {
  Future<String> sendMessage(String message, {String? workspaceId}) async {
    final response = await ApiService.sendChatMessage(
      prompt: message,
      workspaceId: workspaceId,
    );
    
    if (response['success'] == true) {
      return response['response'];
    }
    return response['error'] ?? "Failed to get response";
  }
  
  Future<String> generateTitle(String firstMessage) async {
    // Simple title generation - you can enhance this
    if (firstMessage.length > 30) {
      return '${firstMessage.substring(0, 27)}...';
    }
    return firstMessage;
  }
  
  Future<Map<String, dynamic>> uploadDocument(String filePath, String fileName) async {
    // This should go through DocumentApi
    return {'success': false, 'error': 'Use DocumentApi for uploads'};
  }
}
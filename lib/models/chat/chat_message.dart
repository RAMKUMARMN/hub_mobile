// lib/models/chat/chat_message.dart
class ChatMessage {
  final String id;
  final String sender;
  final String message;
  final DateTime timestamp;
  final bool isError;
  final String? thinking;
  final List<Map<String, dynamic>>? sources;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.message,
    required this.timestamp,
    this.isError = false,
    this.thinking,
    this.sources,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'sender': sender,
    'message': message,
    'timestamp': timestamp.toIso8601String(),
    'isError': isError,
    'thinking': thinking,
    'sources': sources,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final role = json['role'] ?? json['sender'] ?? 'user';
    final content = json['content'] ?? json['message'] ?? '';
    final createdAtRaw = json['created_at'] ?? json['timestamp'] ?? DateTime.now().toIso8601String();
    
    List<Map<String, dynamic>>? parsedSources;
    if (json['sources'] is List) {
      parsedSources = (json['sources'] as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }

    return ChatMessage(
      id: (json['id'] ?? '').toString(),
      sender: role == 'assistant' ? 'ai' : role,
      message: content,
      timestamp: DateTime.parse(createdAtRaw.toString()),
      isError: json['isError'] ?? false,
      thinking: json['thinking'],
      sources: parsedSources,
    );
  }
  
  bool get isUser => sender == 'user';
  bool get isAI => sender == 'ai';
}
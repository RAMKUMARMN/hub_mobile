class ChatSession {
  final String id;
  final String title;
  final String createdAt;
  final String updatedAt;

  const ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) => ChatSession(
        id: json['id'] as String,
        title: json['title'] as String,
        createdAt: json['created_at'] as String,
        updatedAt: json['updated_at'] as String,
      );
}

class ChatMessage {
  final String id;
  final String sessionId;
  final String role; // 'user' | 'assistant'
  final String content;
  final String createdAt;

  const ChatMessage({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        sessionId: json['session_id'] as String,
        role: json['role'] as String,
        content: json['content'] as String,
        createdAt: json['created_at'] as String,
      );

  bool get isUser => role == 'user';
}

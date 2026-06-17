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
        id: json['id'],
        title: json['title'],
        createdAt: json['created_at'],
        updatedAt: json['updated_at'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
}

class ChatMessage {
  final String id;
  final String sessionId;
  final String role;
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
        id: json['id'],
        sessionId: json['session_id'],
        role: json['role'],
        content: json['content'],
        createdAt: json['created_at'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'session_id': sessionId,
        'role': role,
        'content': content,
        'created_at': createdAt,
      };

  bool get isUser => role == 'user';
}
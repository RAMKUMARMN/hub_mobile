// lib/models/chat/ai_chat.dart
import 'chat_message.dart';

class AIChat {
  final String id;
  final String workspaceId;
  final String title;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  AIChat({
    required this.id,
    required this.workspaceId,
    required this.title,
    this.messages = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'workspaceId': workspaceId,
    'title': title,
    'messages': messages.map((m) => m.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory AIChat.fromJson(Map<String, dynamic> json) => AIChat(
    id: json['id'],
    workspaceId: json['workspaceId'],
    title: json['title'],
    messages: (json['messages'] as List)
        .map((m) => ChatMessage.fromJson(m))
        .toList(),
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );
}
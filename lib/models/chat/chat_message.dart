// lib/models/chat/chat_message.dart
class ChatMessage {
  final String id;
  final String sender;
  final String message;
  final DateTime timestamp;
  final bool isError;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.message,
    required this.timestamp,
    this.isError = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'sender': sender,
    'message': message,
    'timestamp': timestamp.toIso8601String(),
    'isError': isError,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'],
    sender: json['sender'],
    message: json['message'],
    timestamp: DateTime.parse(json['timestamp']),
    isError: json['isError'] ?? false,
  );
  
  bool get isUser => sender == 'user';
  bool get isAI => sender == 'ai';
}
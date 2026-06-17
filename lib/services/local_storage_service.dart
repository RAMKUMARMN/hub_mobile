import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/message.dart';
import '../models/todo.dart';

class LocalStorageService {
  static const String recentChatsKey = 'recent_chats';
  static const String recentSessionsKey = 'recent_sessions';
  static const String todosKey = 'todos';

  // =========================
  // RECENT CHAT MESSAGES
  // =========================

  Future<void> saveRecentChat(ChatMessage message) async {
    final prefs = await SharedPreferences.getInstance();

    final chats = prefs.getStringList(recentChatsKey) ?? [];

    chats.add(
      jsonEncode({
        'id': message.id,
        'session_id': message.sessionId,
        'role': message.role,
        'content': message.content,
        'created_at': message.createdAt,
      }),
    );

    if (chats.length > 10) {
      chats.removeRange(0, chats.length - 10);
    }

    await prefs.setStringList(recentChatsKey, chats);
  }

  Future<List<ChatMessage>> getRecentChats() async {
    final prefs = await SharedPreferences.getInstance();

    final chats = prefs.getStringList(recentChatsKey) ?? [];

    return chats
        .map(
          (item) => ChatMessage.fromJson(
            jsonDecode(item) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<void> clearRecentChats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(recentChatsKey);
  }

 Future<void> saveSessionMessages(
    String sessionId,
    List<ChatMessage> messages,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final data = messages.map((message) {
      return jsonEncode({
        'id': message.id,
        'session_id': message.sessionId,
        'role': message.role,
        'content': message.content,
        'created_at': message.createdAt,
      });
    }).toList();

    await prefs.setStringList(
      'session_$sessionId',
      data,
    );
  }

  Future<List<ChatMessage>> getSessionMessages(
    String sessionId,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final data =
        prefs.getStringList('session_$sessionId') ?? [];

    return data
        .map(
          (item) => ChatMessage.fromJson(
            jsonDecode(item),
          ),
        )
        .toList();
  }

  Future<void> saveMessage(
    ChatMessage message,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final key =
        'session_${message.sessionId}';

    final messages =
        prefs.getStringList(key) ?? [];

    messages.add(
      jsonEncode({
        'id': message.id,
        'session_id': message.sessionId,
        'role': message.role,
        'content': message.content,
        'created_at': message.createdAt,
      }),
    );

    await prefs.setStringList(
      key,
      messages,
    );
  }

  // =========================
  // RECENT CHAT SESSIONS
  // =========================

  Future<void> saveRecentSessions(
    List<ChatSession> sessions,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final data = sessions
        .take(10)
        .map(
          (session) => jsonEncode(
            session.toJson(),
          ),
        )
        .toList();

    await prefs.setStringList(
      recentSessionsKey,
      data,
    );
  }

  Future<List<ChatSession>> getRecentSessions() async {
    final prefs = await SharedPreferences.getInstance();

    final data =
        prefs.getStringList(recentSessionsKey) ?? [];

    return data
        .map(
          (item) => ChatSession.fromJson(
            jsonDecode(item) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<void> clearRecentSessions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(recentSessionsKey);
  }

  // =========================
  // TODOS
  // =========================

  Future<void> saveTodos(
    List<Todo> todos,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final data = todos
        .map(
          (todo) => jsonEncode({
            'id': todo.id,
            'title': todo.title,
            'completed': todo.completed,
          }),
        )
        .toList();

    await prefs.setStringList(
      todosKey,
      data,
    );
  }

  Future<List<Todo>> getTodos() async {
    final prefs = await SharedPreferences.getInstance();

    final data =
        prefs.getStringList(todosKey) ?? [];

    return data
        .map(
          (item) => Todo.fromJson(
            jsonDecode(item) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<void> clearTodos() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(todosKey);
  }
}
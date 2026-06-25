import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/message.dart';
import 'hive_encryption_service.dart';

class ChatCache {
  ChatCache._();

  static const String oldBoxName = 'chat_cache';
  static const String boxName = 'chat_cache_secure';
  static const String _messagesPrefix = 'messages:';

  static Future<void> ensureInitialized() async {
    await HiveEncryptionService.migrateIfNecessary(oldBoxName, boxName);
    if (!Hive.isBoxOpen(boxName)) {
      final cipher = await HiveEncryptionService.getCipher();
      await Hive.openBox<String>(boxName, encryptionCipher: cipher);
    }
  }

  static Future<List<ChatMessage>> loadMessages(String sessionId) async {
    await ensureInitialized();
    final box = Hive.box<String>(boxName);
    final encoded = box.get('$_messagesPrefix$sessionId');
    if (encoded == null || encoded.isEmpty) return [];

    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((item) => ChatMessage.fromJson(item.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveMessages(String sessionId, List<ChatMessage> messages) async {
    await ensureInitialized();
    final box = Hive.box<String>(boxName);
    final encoded = jsonEncode(messages.map((message) => message.toJson()).toList());
    await box.put('$_messagesPrefix$sessionId', encoded);
  }

  static Future<void> deleteMessages(String sessionId) async {
    await ensureInitialized();
    final box = Hive.box<String>(boxName);
    await box.delete('$_messagesPrefix$sessionId');
  }

  static const String _sessionsKey = 'sessions';

  static Future<List<ChatSession>> loadSessions() async {
    await ensureInitialized();
    final box = Hive.box<String>(boxName);
    final encoded = box.get(_sessionsKey);
    if (encoded == null || encoded.isEmpty) return [];

    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((item) => ChatSession.fromJson(item.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveSessions(List<ChatSession> sessions) async {
    await ensureInitialized();
    final box = Hive.box<String>(boxName);
    final encoded = jsonEncode(sessions.map((s) => s.toJson()).toList());
    await box.put(_sessionsKey, encoded);
  }

  static Future<void> clear() async {
    await ensureInitialized();
    await Hive.box<String>(boxName).clear();
  }
}
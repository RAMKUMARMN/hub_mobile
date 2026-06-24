import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/todo.dart';
import 'hive_encryption_service.dart';

class TodoCache {
  TodoCache._();

  static const String oldBoxName = 'todo_cache';
  static const String boxName = 'todo_cache_secure';
  static const String _todosKey = 'todos';

  static Future<void> ensureInitialized() async {
    await HiveEncryptionService.migrateIfNecessary(oldBoxName, boxName);
    if (!Hive.isBoxOpen(boxName)) {
      final cipher = await HiveEncryptionService.getCipher();
      await Hive.openBox<String>(boxName, encryptionCipher: cipher);
    }
  }

  static Future<List<Todo>> loadTodos() async {
    await ensureInitialized();
    final box = Hive.box<String>(boxName);
    final encoded = box.get(_todosKey);
    if (encoded == null || encoded.isEmpty) return [];

    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((item) => Todo.fromJson(item.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveTodos(List<Todo> todos) async {
    await ensureInitialized();
    final box = Hive.box<String>(boxName);
    final encoded = jsonEncode(todos.map((t) => t.toJson()).toList());
    await box.put(_todosKey, encoded);
  }

  static Future<void> clear() async {
    await ensureInitialized();
    await Hive.box<String>(boxName).clear();
  }
}

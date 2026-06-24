import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/document.dart';
import 'hive_encryption_service.dart';

class DocumentCache {
  DocumentCache._();

  static const String oldBoxName = 'document_cache';
  static const String boxName = 'document_cache_secure';
  static const String _documentsKey = 'documents';

  static Future<void> ensureInitialized() async {
    await HiveEncryptionService.migrateIfNecessary(oldBoxName, boxName);
    if (!Hive.isBoxOpen(boxName)) {
      final cipher = await HiveEncryptionService.getCipher();
      await Hive.openBox<String>(boxName, encryptionCipher: cipher);
    }
  }

  static Future<List<Document>> loadDocuments() async {
    await ensureInitialized();
    final box = Hive.box<String>(boxName);
    final encoded = box.get(_documentsKey);
    if (encoded == null || encoded.isEmpty) return [];

    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((item) => Document.fromJson(item.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveDocuments(List<Document> documents) async {
    await ensureInitialized();
    final box = Hive.box<String>(boxName);
    final encoded = jsonEncode(documents.map((d) => d.toJson()).toList());
    await box.put(_documentsKey, encoded);
  }

  static Future<void> clear() async {
    await ensureInitialized();
    await Hive.box<String>(boxName).clear();
  }
}

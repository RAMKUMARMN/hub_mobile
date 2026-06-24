import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/user.dart';
import 'hive_encryption_service.dart';

class ProfileCache {
  ProfileCache._();

  static const String oldBoxName = 'profile_cache';
  static const String boxName = 'profile_cache_secure';
  static const String _profileKey = 'profile';

  static Future<void> ensureInitialized() async {
    await HiveEncryptionService.migrateIfNecessary(oldBoxName, boxName);
    if (!Hive.isBoxOpen(boxName)) {
      final cipher = await HiveEncryptionService.getCipher();
      await Hive.openBox<String>(boxName, encryptionCipher: cipher);
    }
  }

  static Future<User?> loadProfile() async {
    await ensureInitialized();
    final box = Hive.box<String>(boxName);
    final encoded = box.get(_profileKey);
    if (encoded == null || encoded.isEmpty) return null;

    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map) return null;
      return User.fromJson(decoded.cast<String, dynamic>());
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveProfile(User user) async {
    await ensureInitialized();
    final box = Hive.box<String>(boxName);
    final encoded = jsonEncode(user.toJson());
    await box.put(_profileKey, encoded);
  }

  static Future<void> clear() async {
    await ensureInitialized();
    await Hive.box<String>(boxName).clear();
  }
}

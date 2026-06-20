import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HiveEncryptionService {
  static const _storage = FlutterSecureStorage();
  static const _keyName = 'hive_encryption_key';
  static HiveAesCipher? _cipher;

  static Future<HiveAesCipher> getCipher() async {
    if (_cipher != null) return _cipher!;

    final existingKeyStr = await _storage.read(key: _keyName);
    List<int> encryptionKey;

    if (existingKeyStr == null) {
      // Key is missing. Check for key loss scenario: do secure boxes already exist?
      // If they exist but we have no key, we must delete them.
      final secureBoxes = [
        'chat_cache_secure',
        'document_cache_secure',
        'profile_cache_secure',
        'todo_cache_secure'
      ];
      
      bool secureBoxExists = false;
      for (final box in secureBoxes) {
        if (await Hive.boxExists(box)) {
          secureBoxExists = true;
          break;
        }
      }

      if (secureBoxExists) {
        // Fatal key loss. Delete all secure boxes.
        for (final box in secureBoxes) {
          await Hive.deleteBoxFromDisk(box);
        }
      }

      // Generate a new key
      encryptionKey = Hive.generateSecureKey();
      await _storage.write(key: _keyName, value: base64UrlEncode(encryptionKey));
    } else {
      encryptionKey = base64Url.decode(existingKeyStr);
    }

    _cipher = HiveAesCipher(encryptionKey);
    return _cipher!;
  }

  static Future<void> migrateIfNecessary(String oldBoxName, String secureBoxName) async {
    final prefs = await SharedPreferences.getInstance();
    final migrationKey = 'migration_${oldBoxName}_complete';
    
    if (prefs.getBool(migrationKey) == true) {
      return; // Already migrated
    }

    final oldExists = await Hive.boxExists(oldBoxName);
    if (!oldExists) {
      // Nothing to migrate
      await prefs.setBool(migrationKey, true);
      return;
    }

    // Interrupted migration recovery: if secure box exists but migration is not complete, wipe secure box
    if (await Hive.boxExists(secureBoxName)) {
      await Hive.deleteBoxFromDisk(secureBoxName);
    }

    // Perform migration
    final oldBox = await Hive.openBox<String>(oldBoxName);
    final cipher = await getCipher();
    final secureBox = await Hive.openBox<String>(secureBoxName, encryptionCipher: cipher);

    // Copy data
    for (final key in oldBox.keys) {
      final value = oldBox.get(key);
      if (value != null) {
        await secureBox.put(key, value);
      }
    }

    // Close boxes
    await oldBox.close();
    await secureBox.close(); // Ensure everything is written before marking complete

    // Mark migration complete
    await prefs.setBool(migrationKey, true);

    // Clean up old box
    await Hive.deleteBoxFromDisk(oldBoxName);
  }
}

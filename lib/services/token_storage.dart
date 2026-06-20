import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage();
  
  static Future<void> migrateFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final oldAccess = prefs.getString('access_token');
    final oldRefresh = prefs.getString('refresh_token');

    if (oldAccess != null) {
      await _storage.write(key: 'access_token', value: oldAccess);
      await prefs.remove('access_token');
    }
    if (oldRefresh != null) {
      await _storage.write(key: 'refresh_token', value: oldRefresh);
      await prefs.remove('refresh_token');
    }
  }

  static Future<String?> getAccessToken() async {
    return _storage.read(key: 'access_token');
  }

  static Future<String?> getRefreshToken() async {
    return _storage.read(key: 'refresh_token');
  }

  static Future<void> saveTokens(String access, String refresh) async {
    await _storage.write(key: 'access_token', value: access);
    await _storage.write(key: 'refresh_token', value: refresh);
  }

  static Future<void> clearTokens() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }
}

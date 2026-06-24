import 'chat_cache.dart';
import 'document_cache.dart';
import 'profile_cache.dart';
import 'todo_cache.dart';

/// Clears all local caches. Call on logout to prevent data leakage.
class CacheManager {
  CacheManager._();

  static Future<void> clearAll() async {
    await ChatCache.clear();
    await DocumentCache.clear();
    await TodoCache.clear();
    await ProfileCache.clear();
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/media_item.dart';

/// Durable, file-backed queue of captured media.
///
/// Every original file lives in the app's local documents directory and is
/// tracked in a single JSON manifest. The manifest is written atomically
/// (temp file + rename) so a crash mid-write can never corrupt the queue.
class MediaStore {
  MediaStore(this._manifestFile, this.mediaDirectoryPath);

  final File _manifestFile;

  /// Absolute path of the folder holding the original media files.
  final String mediaDirectoryPath;

  final List<MediaItem> _items = [];

  List<MediaItem> get items => List.unmodifiable(_items);

  /// Opens the queue from the app's default documents directory. Safe to call
  /// from both the UI isolate and the background sync isolate.
  static Future<MediaStore> openDefault() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/media');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final store = MediaStore(File('${docs.path}/media_queue.json'), dir.path);
    await store.load();
    return store;
  }

  Future<void> load() async {
    _items.clear();
    if (!await _manifestFile.exists()) return;
    try {
      final raw = await _manifestFile.readAsString();
      if (raw.trim().isEmpty) return;
      final decoded = jsonDecode(raw) as List<dynamic>;
      _items.addAll(
        decoded.map((e) => MediaItem.fromJson(e as Map<String, dynamic>)),
      );
    } catch (_) {
      // Corrupt manifest: start fresh rather than crash the app.
      _items.clear();
    }
  }

  Future<void> save() async {
    final tmp = File('${_manifestFile.path}.tmp');
    final payload = jsonEncode(_items.map((e) => e.toJson()).toList());
    await tmp.writeAsString(payload, flush: true);
    await tmp.rename(_manifestFile.path);
  }

  Future<void> upsert(MediaItem item) async {
    final index = _items.indexWhere((e) => e.id == item.id);
    if (index == -1) {
      _items.add(item);
    } else {
      _items[index] = item;
    }
    await save();
  }

  Future<void> delete(String id) async {
    _items.removeWhere((e) => e.id == id);
    await save();
  }

  MediaItem? byId(String id) {
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }
}

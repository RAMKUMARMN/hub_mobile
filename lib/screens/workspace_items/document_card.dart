// lib/screens/workspace_items/document_card.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/workspace_items/document.dart';
import '../../themes/app_colors.dart';
import '../../widgets/glass/glass_card.dart';
import '../../utils/helpers.dart';
import '../../services/api/api_client.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class DocumentCard extends StatelessWidget {
  final Document document;
  final VoidCallback? onDelete;
  final VoidCallback? onShare;

  const DocumentCard({
    super.key,
    required this.document,
    this.onDelete,
    this.onShare,
  });

  IconData _getFileIcon(String fileType) {
    if (fileType.contains('pdf')) return Icons.picture_as_pdf;
    if (fileType.contains('image')) return Icons.image;
    if (fileType.contains('word') || fileType.contains('doc')) return Icons.description;
    return Icons.insert_drive_file;
  }

  Color _getFileColor(String fileType) {
    if (fileType.contains('pdf')) return Colors.red;
    if (fileType.contains('image')) return Colors.purple;
    if (fileType.contains('word') || fileType.contains('doc')) return Colors.blue;
    return AppColors.aiCyan;
  }

  /// STATIC: Format file size
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// STATIC: Get user-specific cache directory
  static Future<Directory> _getUserCacheDir() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    
    // Get current user ID
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? 'anonymous';
    
    // Create user-specific folder
    final userCacheDir = Directory('${appDocDir.path}/cached_documents/$userId');
    if (!await userCacheDir.exists()) {
      await userCacheDir.create(recursive: true);
    }
    return userCacheDir;
  }

  /// Open document with caching - downloads ONCE per user
  Future<void> _openDocument(BuildContext context) async {
    try {
      // Get user-specific cache directory
      final cacheDir = await _getUserCacheDir();
      
      // Extract proper file extension from filename
      String getFileExtension(String filename) {
        final parts = filename.split('.');
        if (parts.length > 1) {
          return parts.last.toLowerCase();
        }
        if (document.fileType.contains('pdf')) return 'pdf';
        if (document.fileType.contains('jpeg') || document.fileType.contains('jpg')) return 'jpg';
        if (document.fileType.contains('png')) return 'png';
        if (document.fileType.contains('image')) return 'image';
        if (document.fileType.contains('word') || document.fileType.contains('doc')) return 'docx';
        if (document.fileType.contains('text')) return 'txt';
        return 'file';
      }
      
      final extension = getFileExtension(document.title);
      final cacheFileName = '${document.id}.$extension';
      final cacheFilePath = '${cacheDir.path}/$cacheFileName';
      final cacheFile = File(cacheFilePath);
      
      // STEP 1: Check if file is already cached
      if (await cacheFile.exists()) {
        final fileSize = await cacheFile.length();
        if (fileSize > 0) {
          logger.i('📄 Opening from cache: $cacheFilePath');
          final result = await OpenFile.open(cacheFilePath);
          if (result.type != ResultType.done) {
            if (context.mounted) {
              Helpers.showError(context, 'Cannot open file: ${result.message}');
            }
          }
          return;
        }
      }
      
      // STEP 2: File not cached - download it
      logger.i('📥 Downloading file: ${document.title}');
      if (context.mounted) {
        Helpers.showInfo(context, 'Downloading file...');
      }
      
      final token = await ApiClient().getToken();
      if (token == null) {
        if (context.mounted) {
          Helpers.showError(context, 'Not authenticated');
        }
        return;
      }
      
      final response = await http.get(
        Uri.parse("${ApiClient.baseUrl}/documents/${document.id}/download"),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode != 200) {
        if (context.mounted) {
          Helpers.showError(context, 'Failed to download file (${response.statusCode})');
        }
        return;
      }
      
      // STEP 3: Save to user-specific cache
      await cacheFile.writeAsBytes(response.bodyBytes);
      logger.i('✅ File cached for user: $cacheFilePath');
      
      // STEP 4: Open the file
      final result = await OpenFile.open(cacheFilePath);
      if (result.type != ResultType.done) {
        if (context.mounted) {
          Helpers.showError(context, 'Cannot open file: ${result.message}');
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          Helpers.showSuccess(context, 'File opened successfully');
        }
      }
      
    } catch (e) {
      logger.e('❌ Error opening document: $e');
      if (context.mounted) {
        Helpers.showError(context, 'Failed to open file: ${e.toString()}');
      }
    }
  }

  /// STATIC: Clear cache for specific user
  static Future<void> clearUserDocumentCache({String? userId}) async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      
      if (userId != null) {
        // Clear specific user's cache
        final userCacheDir = Directory('${appDocDir.path}/cached_documents/$userId');
        if (await userCacheDir.exists()) {
          await userCacheDir.delete(recursive: true);
          logger.i('🗑️ Cleared cache for user: $userId');
        }
      } else {
        // Clear all cache
        final cacheDir = Directory('${appDocDir.path}/cached_documents');
        if (await cacheDir.exists()) {
          await cacheDir.delete(recursive: true);
          logger.i('🗑️ Cleared all document cache');
        }
      }
    } catch (e) {
      logger.e('❌ Error clearing cache: $e');
    }
  }

  /// STATIC: Get cache size for current user
  static Future<String> getCacheSize() async {
    try {
      final cacheDir = await _getUserCacheDir();
      
      if (!await cacheDir.exists()) return '0 B';
      
      int totalSize = 0;
      final files = await cacheDir.list().toList();
      
      for (var entity in files) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      
      return formatFileSize(totalSize);
      
    } catch (e) {
      return '0 B';
    }
  }

  /// STATIC: Check if a document is cached for current user
  static Future<bool> isDocumentCached(String documentId) async {
    try {
      final cacheDir = await _getUserCacheDir();
      
      if (!await cacheDir.exists()) return false;
      
      // Find any file with this document ID
      final files = await cacheDir.list().toList();
      for (var entity in files) {
        if (entity is File && entity.path.contains(documentId)) {
          if (await entity.exists() && await entity.length() > 0) {
            return true;
          }
        }
      }
      return false;
      
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final secondaryText = Theme.of(context).textTheme.bodyMedium?.color;
    final fileColor = _getFileColor(document.fileType);

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      onTap: () => _openDocument(context),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: fileColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_getFileIcon(document.fileType), color: fileColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  document.formattedFileSize,
                  style: TextStyle(color: secondaryText, fontSize: 12),
                ),
                // Show cache indicator
                FutureBuilder<bool>(
                  future: isDocumentCached(document.id),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data == true) {
                      return const Row(
                        children: [
                          Icon(Icons.check_circle, size: 12, color: Colors.green),
                          SizedBox(width: 4),
                          Text(
                            'Cached',
                            style: TextStyle(color: Colors.green, fontSize: 10),
                          ),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
          if (onShare != null)
            IconButton(
              icon: const Icon(Icons.share_outlined, size: 20),
              color: AppColors.aiCyan,
              onPressed: onShare,
            ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              color: Colors.red.shade300,
              onPressed: () => _confirmDelete(context),
            ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Delete "${document.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              onDelete?.call();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
// lib/screens/workspace_items/document_card.dart
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import '../../../models/workspace_items/document.dart';
import '../../../themes/app_colors.dart';
import '../../../widgets/glass/glass_card.dart';
import '../../../utils/helpers.dart';

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

  Future<void> _openDocument(BuildContext context) async {
    try {
      final result = await OpenFile.open(document.filePath);
      if (result.type != ResultType.done) {
        if (context.mounted) {
          Helpers.showError(context, 'Cannot open this file type');
        }
      }
    } catch (e) {
      if (context.mounted) {
        Helpers.showError(context, 'Failed to open file: ${e.toString()}');
      }
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
      onTap: () => _openDocument(context),  // Pass context here
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
// lib/screens/ai/ai_sidebar_items.dart
import 'package:flutter/material.dart';
import '../../themes/app_colors.dart';
import '../../models/chat/ai_chat.dart';
import '../../models/workspace/workspace.dart';
import '../../models/workspace_items/document.dart';

// ============================================================================
// AIWorkspaceDropdown - Workspace dropdown button
// ============================================================================

class AIWorkspaceDropdown extends StatelessWidget {
  final Workspace? currentWorkspace;
  final VoidCallback onTap;

  const AIWorkspaceDropdown({
    super.key,
    required this.currentWorkspace,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.aiCyan.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                currentWorkspace?.name ?? 'General',
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: AppColors.aiCyan, size: 24),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// AIChatTile - Chat list tile with edit/delete
// ============================================================================

class AIChatTile extends StatelessWidget {
  final AIChat chat;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const AIChatTile({
    super.key,
    required this.chat,
    required this.isSelected,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final secondaryText = Theme.of(context).textTheme.bodyMedium?.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.aiCyan.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        leading: isSelected
            ? Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.aiCyan,
                  borderRadius: BorderRadius.circular(2),
                ),
              )
            : null,
        title: Text(
          chat.messages.isEmpty ? 'New Conversation' : chat.title,
          style: TextStyle(
            color: isSelected ? AppColors.aiCyan : textColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit_outlined, size: 18, color: secondaryText?.withValues(alpha: 0.6)),
              onPressed: onRename,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(Icons.delete_outline, size: 18, color: Colors.grey.shade400),
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

// ============================================================================
// AIFileSelectorTile - Tile to open file selector with selected count
// ============================================================================

class AIFileSelectorTile extends StatefulWidget {
  final List<Document> documents;
  final VoidCallback onTap;

  const AIFileSelectorTile({
    super.key,
    required this.documents,
    required this.onTap,
  });

  @override
  State<AIFileSelectorTile> createState() => _AIFileSelectorTileState();
}

class _AIFileSelectorTileState extends State<AIFileSelectorTile> {
  // Track selected file count (updated from bottom sheet)
  int _selectedCount = 0;

  // Callback to update selected count from bottom sheet
  void _updateSelectedCount(int count) {
    setState(() {
      _selectedCount = count;
    });
  }

  @override
  Widget build(BuildContext context) {
    final secondaryText = Theme.of(context).textTheme.bodyMedium?.color;
    final hasDocuments = widget.documents.isNotEmpty;
    final showSelected = hasDocuments && _selectedCount > 0;

    return GestureDetector(
      onTap: () {
        // ✅ Pass callback to bottom sheet
        _showFileSelectorBottomSheetWithCallback(
          context, 
          widget.documents, 
          _updateSelectedCount
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.aiCyan.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.aiCyan.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(
              hasDocuments ? Icons.folder_open : Icons.folder_outlined,
              color: hasDocuments ? AppColors.aiCyan : Colors.grey.shade500,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasDocuments ? 'Select Context Files' : 'No Files in Workspace',
                style: TextStyle(
                  color: hasDocuments ? secondaryText : Colors.grey.shade500,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // ✅ Show SELECTED count instead of total
            if (showSelected)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.aiCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$_selectedCount selected',
                  style: TextStyle(
                    color: AppColors.aiCyan,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else if (hasDocuments)
              Text(
                '0 selected',
                style: TextStyle(
                  color: secondaryText?.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              )
            else
              const Icon(Icons.info_outline, color: Colors.grey, size: 18),
            Icon(
              Icons.chevron_right,
              color: hasDocuments ? AppColors.aiCyan : Colors.grey.shade400,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // ✅ File Selector Bottom Sheet with callback
  void _showFileSelectorBottomSheetWithCallback(
    BuildContext context,
    List<Document> documents,
    Function(int) onSelectionChanged,
  ) {
    final Set<String> selectedIds = {};

    // Auto-select all documents initially
    if (documents.isNotEmpty) {
      selectedIds.addAll(documents.map((d) => d.id));
      onSelectionChanged(selectedIds.length);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SafeArea(
              child: Container(
                padding: const EdgeInsets.all(20),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Select Context Files',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      documents.isEmpty
                          ? 'No files in this workspace. Upload files first.'
                          : 'Choose files for AI to reference in responses',
                      style: TextStyle(
                        color: documents.isEmpty ? Colors.orange.shade700 : Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (documents.isEmpty)
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.upload_file_outlined, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(
                                'No files found',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Upload files to your workspace to use them',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.pushNamed(context, '/workspace');
                                },
                                icon: const Icon(Icons.folder_open),
                                label: const Text('Go to Workspace'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.aiCyan,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView(
                          shrinkWrap: true,
                          children: documents.map((doc) {
                            final isSelected = selectedIds.contains(doc.id);
                            return CheckboxListTile(
                              key: ValueKey(doc.id),
                              value: isSelected,
                              onChanged: (_) {
                                setState(() {
                                  if (isSelected) {
                                    selectedIds.remove(doc.id);
                                  } else {
                                    selectedIds.add(doc.id);
                                  }
                                });
                                // ✅ Update the callback
                                onSelectionChanged(selectedIds.length);
                              },
                              title: Text(doc.title, style: const TextStyle(fontSize: 14)),
                              subtitle: Text(
                                doc.formattedFileSize,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                              secondary: Icon(
                                _getFileIcon(doc.fileType),
                                color: isSelected ? AppColors.aiCyan : Colors.grey.shade400,
                                size: 24,
                              ),
                              controlAffinity: ListTileControlAffinity.leading,
                              activeColor: AppColors.aiCyan,
                              dense: false,
                            );
                          }).toList(),
                        ),
                      ),
                    const SizedBox(height: 16),
                    if (documents.isNotEmpty)
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  selectedIds.clear();
                                });
                                // ✅ Update callback
                                onSelectionChanged(0);
                              },
                              child: const Text('Clear All'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                // ✅ Final callback update
                                onSelectionChanged(selectedIds.length);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${selectedIds.length} files selected for AI context'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.aiCyan,
                                foregroundColor: Colors.white,
                              ),
                              child: Text('Apply (${selectedIds.length})'),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Helper: Get file icon
  IconData _getFileIcon(String fileType) {
    if (fileType.contains('pdf')) return Icons.picture_as_pdf;
    if (fileType.contains('image')) return Icons.image;
    if (fileType.contains('word') || fileType.contains('doc')) return Icons.description;
    if (fileType.contains('sheet') || fileType.contains('excel')) return Icons.table_chart;
    return Icons.insert_drive_file;
  }
}
// lib/screens/ai/ai_dialogs.dart
import 'package:flutter/material.dart';
import '../../providers/ai_provider.dart';
import '../../providers/workspace_provider.dart';
import '../../themes/app_colors.dart';
import '../../models/chat/ai_chat.dart';
import '../../models/workspace_items/document.dart';

// ============================================================================
// Workspace Menu Bottom Sheet
// ============================================================================

void showWorkspaceMenu(
  BuildContext context,
  WorkspaceProvider workspaceProvider,
  AIProvider aiProvider,
) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => SafeArea(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Workspace',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...workspaceProvider.workspaces.map((workspace) => ListTile(
                  leading: Text(workspace.icon, style: const TextStyle(fontSize: 24)),
                  title: Text(workspace.name),
                  trailing: workspaceProvider.currentWorkspace?.id == workspace.id
                      ? const Icon(Icons.check_circle, color: AppColors.aiCyan)
                      : null,
                  onTap: () {
                    aiProvider.setWorkspaceContext(workspace);
                    workspaceProvider.selectWorkspace(workspace);
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    ),
  );
}

// ============================================================================
// Rename Chat Dialog
// ============================================================================

void showRenameChatDialog(
  BuildContext context,
  AIChat chat,
  AIProvider aiProvider,
) {
  final controller = TextEditingController(text: chat.title);
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Rename Chat'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          hintText: 'Enter chat name',
          border: OutlineInputBorder(),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final newTitle = controller.text.trim();
            if (newTitle.isNotEmpty) {
              aiProvider.updateChatTitle(chat.id, newTitle);
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

// ============================================================================
// Delete Chat Confirmation Dialog
// ============================================================================

void showDeleteChatConfirmation(
  BuildContext context,
  AIChat chat,
  AIProvider aiProvider,
) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Chat'),
      content: Text('Delete "${chat.title}"?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            aiProvider.deleteChat(chat.id);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}

// ============================================================================
// File Selector Bottom Sheet WITH Callback
// ============================================================================

void showFileSelectorBottomSheetWithCallback(
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

// ============================================================================
// Legacy File Selector Bottom Sheet (Keep for backward compatibility)
// ============================================================================

void showFileSelectorBottomSheet(BuildContext context, List<Document> documents) {
  showFileSelectorBottomSheetWithCallback(
    context,
    documents,
    (count) {
      // No-op callback for backward compatibility
    },
  );
}

// ============================================================================
// Helper: Get File Icon
// ============================================================================

IconData _getFileIcon(String fileType) {
  if (fileType.contains('pdf')) return Icons.picture_as_pdf;
  if (fileType.contains('image')) return Icons.image;
  if (fileType.contains('word') || fileType.contains('doc')) return Icons.description;
  if (fileType.contains('sheet') || fileType.contains('excel')) return Icons.table_chart;
  return Icons.insert_drive_file;
}
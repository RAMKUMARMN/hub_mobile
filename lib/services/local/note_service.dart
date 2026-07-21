// lib/services/local/note_service.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../providers/workspace_provider.dart';
import '../api/note_api_service.dart';
import '../../models/workspace_items/note.dart';
import '../../utils/helpers.dart';
import '../../utils/validators.dart';

import 'package:logger/logger.dart';

class NoteService {
  final BuildContext context;
  final NoteApiService _noteApi = NoteApiService();  // ✅ NEW: Instance of NoteApiService
  final logger = Logger();
  NoteService({required this.context});

  /// Create a new note
  Future<bool> createNote({
    required String title,
    String content = '',
    List<String> tags = const [],
  }) async {
    if (!Validators.isNotEmpty(title)) {
      Helpers.showError(context, 'Note title is required');
      return false;
    }
    
    final appState = Provider.of<AppState>(context, listen: false);
    final workspaceProvider = Provider.of<WorkspaceProvider>(context, listen: false);
    final workspaceId = workspaceProvider.currentWorkspace?.id;
    
    if (workspaceId == null) {
      Helpers.showError(context, 'No workspace selected');
      return false;
    }

    // Create note object FIRST (for immediate UI update)
    final newNote = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      workspaceId: workspaceId,
      title: title,
      subtitle: 'Note created at ${DateTime.now().toLocal().toString().substring(0, 16)}',
      icon: Icons.notes_rounded,
      content: content,
      tags: tags,
      isFavorite: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    // Add to UI immediately for better UX
    appState.addWorkspaceItem(newNote, workspaceId: workspaceId);
    appState.addActivity('📝 New note created: $title');
    if (context.mounted) {
      Helpers.showSuccess(context, 'Note saved!');
    }
    
    // Then try to save to backend in background
    try {
      // ✅ FIXED: Using _noteApi instead of NoteApi
      await _noteApi.createNote(
        title: title,
        content: content,
        tags: tags,
        workspaceId: workspaceId,
      );
    } catch (e) {
      // Backend save failed, but note already saved locally
      logger.e('Backend save failed, but note saved locally: $e');
    }
    
    return true;
  }

  /// Show create note dialog
  void showCreateNoteDialog({String? initialContent}) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController contentController = TextEditingController(text: initialContent);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('New Note'),
            content: SizedBox(
              width: double.maxFinite,
              height: 350,  // Fixed height to prevent overflow
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      hintText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: TextField(
                      controller: contentController,
                      decoration: const InputDecoration(
                        hintText: 'Write your note here...',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: null,  // Unlimited lines
                      expands: true,   // Fill available space
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.trim().isEmpty) {
                    Helpers.showError(context, 'Please enter a title');
                    return;
                  }
                  Navigator.pop(dialogContext);
                  await createNote(
                    title: titleController.text.trim(),
                    content: contentController.text,
                  );
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Update existing note
  Future<bool> updateNote(String noteId, {String? title, String? content}) async {
    try {
      // ✅ FIXED: Using _noteApi instead of NoteApi
      final response = await _noteApi.updateNote(
        noteId: noteId,
        title: title,
        content: content,
      );
      
      if (response['success'] == true) {
        if (context.mounted) {
          Helpers.showSuccess(context, 'Note updated!');
        }
        return true;
      }
      if (context.mounted) {
        Helpers.showError(context, response['error'] ?? 'Failed to update note');
      }
      return false;
    } catch (e) {
      if (context.mounted) {
        Helpers.showError(context, 'Failed to update note: ${e.toString()}');
      }
      return false;
    }
  }

  /// Delete note
  Future<bool> deleteNote(String noteId) async {
    try {
      // ✅ FIXED: Using _noteApi instead of NoteApi
      final response = await _noteApi.deleteNote(noteId);
      if (response['success'] == true) {
        if (context.mounted) {
          Helpers.showSuccess(context, 'Note deleted');
        }
        return true;
      }
      if (context.mounted) {
        Helpers.showError(context, response['error'] ?? 'Failed to delete note');
      }
      return false;
    } catch (e) {
      if (context.mounted) {
        Helpers.showError(context, 'Failed to delete note: ${e.toString()}');
      }
      return false;
    }
  }
}
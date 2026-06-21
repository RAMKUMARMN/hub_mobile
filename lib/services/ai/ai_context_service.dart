// lib/services/ai/ai_context_service.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../providers/workspace_provider.dart';
import '../../models/workspace/workspace.dart';
import '../../models/workspace_items/task.dart';
import '../../models/workspace_items/note.dart';
import '../../models/workspace_items/document.dart';
import 'ai_services.dart';

class AIContextService {
  final BuildContext context;
  late final AIService _aiService;
  
  AIContextService(this.context) {
    _aiService = AIService();
  }
  
  // ============ HELPER METHODS ============
  
  /// Get all tasks across all workspaces
  List<Task> _getAllTasks(AppState appState) {
    final allTasks = <Task>[];
    // AppState has no tasks getter now, so we iterate through all workspaces
    // This is a workaround - consider adding tasks getter back to AppState
    return allTasks;
  }
  
  /// Get all notes across all workspaces
  List<Note> _getAllNotes(AppState appState) {
    final allNotes = <Note>[];
    // AppState has no notes getter now, so we iterate through all workspaces
    return allNotes;
  }
  
  // ============ WORKSPACE CONTEXT ============
  
  String buildWorkspaceContext() {
    final workspaceProvider = Provider.of<WorkspaceProvider>(context, listen: false);
    final appState = Provider.of<AppState>(context, listen: false);
    final workspace = workspaceProvider.currentWorkspace;
    
    if (workspace == null) return '';
    
    // Get items for current workspace
    final items = appState.getItemsForWorkspace(workspace.id);
    final tasks = items.whereType<Task>().toList();
    final notes = items.whereType<Note>().toList();
    
    final pendingTasks = tasks.where((t) => t.status != TaskStatus.completed).length;
    final completedTasks = tasks.where((t) => t.status == TaskStatus.completed).length;
    
    return '''
Current Workspace: ${workspace.name}
Type: ${workspace.type.displayName}
Total Tasks: ${tasks.length}
Pending Tasks: $pendingTasks
Completed Tasks: $completedTasks
Total Notes: ${notes.length}
''';
  }
  
  // ============ TASK CONTEXT ============
  
  String getTaskSummary() {
    final workspaceProvider = Provider.of<WorkspaceProvider>(context, listen: false);
    final appState = Provider.of<AppState>(context, listen: false);
    final workspace = workspaceProvider.currentWorkspace;
    
    if (workspace == null) return 'No workspace selected.';
    
    final items = appState.getItemsForWorkspace(workspace.id);
    final tasks = items.whereType<Task>().toList();
    
    if (tasks.isEmpty) return 'No tasks available.';
    
    final pendingTasks = tasks.where((t) => t.status != TaskStatus.completed).toList();
    final highPriorityTasks = tasks.where((t) => t.priority == TaskPriority.high && t.status != TaskStatus.completed).toList();
    final overdueTasks = tasks.where((t) => t.isOverdue).toList();
    
    String summary = '';
    
    if (highPriorityTasks.isNotEmpty) {
      summary += 'High Priority Tasks (${highPriorityTasks.length}):\n';
      for (var task in highPriorityTasks.take(3)) {
        summary += '• ${task.title}\n';
      }
    }
    
    if (overdueTasks.isNotEmpty) {
      summary += '\nOverdue Tasks (${overdueTasks.length}):\n';
      for (var task in overdueTasks.take(3)) {
        summary += '• ${task.title}\n';
      }
    }
    
    if (pendingTasks.isNotEmpty && summary.isEmpty) {
      summary += 'Pending Tasks (${pendingTasks.length}):\n';
      for (var task in pendingTasks.take(3)) {
        summary += '• ${task.title}\n';
      }
    }
    
    return summary.isEmpty ? 'No pending tasks. Great job!' : summary;
  }
  
  // ============ NOTE CONTEXT ============
  
  String getNoteSummary() {
    final workspaceProvider = Provider.of<WorkspaceProvider>(context, listen: false);
    final appState = Provider.of<AppState>(context, listen: false);
    final workspace = workspaceProvider.currentWorkspace;
    
    if (workspace == null) return 'No workspace selected.';
    
    final items = appState.getItemsForWorkspace(workspace.id);
    final notes = items.whereType<Note>().toList();
    
    if (notes.isEmpty) return 'No notes available.';
    
    final recentNotes = notes.take(3).toList();
    String summary = 'Recent Notes (${notes.length} total):\n';
    for (var note in recentNotes) {
      summary += '• ${note.title}\n';
    }
    
    return summary;
  }
  
  // ============ FULL CONTEXT ============
  
  String getFullContext() {
    return '''
Workspace Context:
${buildWorkspaceContext()}

Task Summary:
${getTaskSummary()}

Note Summary:
${getNoteSummary()}
''';
  }
  
  // ============ AI-POWERED INSIGHTS ============
  
  Future<String> getSmartTaskSuggestion() async {
    final taskContext = getTaskSummary();
    final prompt = '''
Based on this task context:
$taskContext

Provide ONE specific, actionable suggestion for what the user should focus on right now.
Keep it short and practical (under 100 characters).
''';
    
    try {
      return await _aiService.sendMessage(prompt);
    } catch (e) {
      return _getDefaultTaskSuggestion();
    }
  }
  
  String _getDefaultTaskSuggestion() {
    final workspaceProvider = Provider.of<WorkspaceProvider>(context, listen: false);
    final appState = Provider.of<AppState>(context, listen: false);
    final workspace = workspaceProvider.currentWorkspace;
    
    if (workspace == null) return 'Start by selecting a workspace.';
    
    final items = appState.getItemsForWorkspace(workspace.id);
    final tasks = items.whereType<Task>().toList();
    final highPriorityTasks = tasks.where((t) => t.priority == TaskPriority.high && t.status != TaskStatus.completed).toList();
    
    if (highPriorityTasks.isNotEmpty) {
      return 'Focus on "${highPriorityTasks.first.title}" first.';
    }
    
    final pendingTasks = tasks.where((t) => t.status != TaskStatus.completed).toList();
    if (pendingTasks.isNotEmpty) {
      return 'Start with "${pendingTasks.first.title}".';
    }
    
    return 'Great job! Take a moment to plan your next goal.';
  }
  
  Future<String> getProductivityTip() async {
    final workspaceProvider = Provider.of<WorkspaceProvider>(context, listen: false);
    final workspaceName = workspaceProvider.currentWorkspace?.name ?? 'General';
    final prompt = '''
Provide ONE short productivity tip (max 80 characters) that would be helpful for someone working on a project named "$workspaceName".
''';
    
    try {
      return await _aiService.sendMessage(prompt);
    } catch (e) {
      return 'Take a 5-minute break to stay focused.';
    }
  }
  
  // ============ WORKSPACE QUERIES ============
  
  Future<String> askAboutWorkspace(String question) async {
    final context = buildWorkspaceContext();
    final prompt = '''
Workspace Context:
$context

User Question: $question

Based ONLY on the above context, provide a helpful answer.
If you can't answer from the context, say so politely.
''';
    
    try {
      return await _aiService.sendMessage(prompt);
    } catch (e) {
      return "I'm having trouble processing your question. Please try again.";
    }
  }
  
  // ============ SMART ACTIONS ============
  
  Future<Map<String, dynamic>> extractTaskFromText(String text) async {
    final prompt = '''
Parse the following text and extract a task if present.
Return as JSON: {"hasTask": true/false, "title": "...", "priority": "low/medium/high", "dueDate": null or "YYYY-MM-DD"}

Text: "$text"
''';
    
    try {
      final response = await _aiService.sendMessage(prompt);
      // Parse JSON response (simplified)
      return {
        'hasTask': response.contains('true'),
        'title': text.length > 50 ? '${text.substring(0, 47)}...' : text,
        'priority': 'medium',
        'dueDate': null,
      };
    } catch (e) {
      return {
        'hasTask': false,
        'title': text,
        'priority': 'medium',
        'dueDate': null,
      };
    }
  }
  
  Future<Map<String, dynamic>> extractReminderFromText(String text) async {
    final prompt = '''
Parse the following text and extract a reminder if present.
Return as JSON: {"hasReminder": true/false, "title": "...", "time": null or "YYYY-MM-DD HH:MM"}

Text: "$text"
''';
    
    try {
      final response = await _aiService.sendMessage(prompt);
      return {
        'hasReminder': response.contains('true'),
        'title': text,
        'time': null,
      };
    } catch (e) {
      return {
        'hasReminder': false,
        'title': text,
        'time': null,
      };
    }
  }
  
  // ============ SUGGESTED PROMPTS ============
  
  List<String> getSuggestedPrompts() {
    final workspaceProvider = Provider.of<WorkspaceProvider>(context, listen: false);
    final appState = Provider.of<AppState>(context, listen: false);
    final workspace = workspaceProvider.currentWorkspace;
    
    final workspaceName = workspace?.name ?? 'General';
    
    if (workspace == null) {
      return [
        'Create a workspace to get started',
        'How do I add tasks?',
        'What can SmartHub do?',
      ];
    }
    
    final items = appState.getItemsForWorkspace(workspace.id);
    final hasTasks = items.whereType<Task>().isNotEmpty;
    final hasNotes = items.whereType<Note>().isNotEmpty;
    
    final prompts = <String>[];
    
    if (hasTasks) {
      prompts.add('Summarize my tasks');
      prompts.add('What should I prioritize?');
    }
    
    if (hasNotes) {
      prompts.add('Find connections in my notes');
    }
    
    prompts.add('Give me a productivity tip');
    prompts.add('How is my progress in $workspaceName?');
    
    return prompts;
  }
}
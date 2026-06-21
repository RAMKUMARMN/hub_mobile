// lib/providers/app_state.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workspace_items/workspace_item.dart';
import '../models/workspace_items/task.dart';
import '../models/workspace_items/note.dart';
import '../models/workspace_items/document.dart';
import '../models/focus_session.dart';
import '../services/api/document_service.dart';
import '../services/api/task_api_service.dart';
import '../services/api/note_api_service.dart';
import '../models/workspace/workspace.dart';
import '../services/api/workspace_service.dart';

class AppState extends ChangeNotifier {
  // Items organized by workspace
  Map<String, List<WorkspaceItem>> _workspaceItemsMap = {};
  Map<String, List<WorkspaceItem>> get workspaceItemsMap => _workspaceItemsMap;
  List<Map<String, dynamic>> _recentActivities = [];
  List<FocusSession> _focusSessions = [];
  String? _currentUserId;

  // Services
  final TaskApiService _taskApi = TaskApiService();
  final NoteApiService _noteApi = NoteApiService();
  final DocumentService _documentService = DocumentService();
  final WorkspaceService _workspaceService = WorkspaceService();

  // Getters
  List<Map<String, dynamic>> get recentActivities => _recentActivities;
  String? get currentUserId => _currentUserId;
  List<FocusSession> get focusSessions => _focusSessions;

  int get totalFocusMinutesToday {
    final today = DateTime.now();
    return _focusSessions
        .where((s) =>
            s.completed &&
            s.endTime != null &&
            s.endTime!.year == today.year &&
            s.endTime!.month == today.month &&
            s.endTime!.day == today.day)
        .fold(0, (sum, s) => sum + (s.actualSeconds ~/ 60));
  }

  int get totalFocusMinutesThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return _focusSessions
        .where((s) =>
            s.completed && s.endTime != null && s.endTime!.isAfter(startOfWeek))
        .fold(0, (sum, s) => sum + (s.actualSeconds ~/ 60));
  }

  int get totalFocusMinutesThisMonth {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    return _focusSessions
        .where((s) =>
            s.completed &&
            s.endTime != null &&
            s.endTime!.isAfter(startOfMonth))
        .fold(0, (sum, s) => sum + (s.actualSeconds ~/ 60));
  }

  int get completedSessionsToday {
    final today = DateTime.now();
    return _focusSessions
        .where((s) =>
            s.completed &&
            s.endTime != null &&
            s.endTime!.year == today.year &&
            s.endTime!.month == today.month &&
            s.endTime!.day == today.day)
        .length;
  }

  double get averageFocusDuration {
    if (_focusSessions.isEmpty) return 0.0;
    final totalSeconds =
        _focusSessions.fold(0, (sum, s) => sum + s.actualSeconds);
    return (totalSeconds / _focusSessions.length) / 60;
  }

  Map<DateTime, int> get focusMinutesLast7Days {
    final result = <DateTime, int>{};
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day - i);
      final minutes = _focusSessions
          .where((s) =>
              s.completed &&
              s.endTime != null &&
              s.endTime!.year == date.year &&
              s.endTime!.month == date.month &&
              s.endTime!.day == date.day)
          .fold(0, (sum, s) => sum + (s.actualSeconds ~/ 60));
      result[date] = minutes;
    }
    return result;
  }

  List<WorkspaceItem> getItemsForWorkspace(String workspaceId) {
    return _workspaceItemsMap[workspaceId] ?? [];
  }

  int get pendingTasksCount {
    int count = 0;
    for (var items in _workspaceItemsMap.values) {
      count += items
          .whereType<Task>()
          .where((t) => t.status != TaskStatus.completed)
          .length;
    }
    return count;
  }

  AppState() {
    _loadFromStorage();
    _loadFocusSessions();
  }

  // ============ FOCUS SESSION MANAGEMENT ============

  void addFocusSession(FocusSession session) {
    _focusSessions.add(session);
    _saveFocusSessions();
    _addActivity(
        '🎯 Focus session completed: ${session.actualSeconds ~/ 60} minutes');
    _saveUserDataIfLoggedIn();
    notifyListeners();
  }

  void clearFocusSessions() {
    _focusSessions.clear();
    _saveFocusSessions();
    _saveUserDataIfLoggedIn();
    notifyListeners();
  }

  Future<void> _saveFocusSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getUserScopedKey('focus_sessions');
    final sessionsJson = _focusSessions.map((s) => s.toJson()).toList();
    await prefs.setString(key, jsonEncode(sessionsJson));
  }

  Future<void> _loadFocusSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getUserScopedKey('focus_sessions');
    final sessionsJson = prefs.getString(key);
    if (sessionsJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(sessionsJson);
        _focusSessions =
            decoded.map((json) => FocusSession.fromJson(json)).toList();
      } catch (e) {
        debugPrint('Error loading focus sessions: $e');
        _focusSessions = [];
      }
    }
  }

  // ============ WORKSPACE ITEMS CRUD ============

  void addWorkspaceItem(WorkspaceItem item, {required String workspaceId}) {
    if (workspaceId.isEmpty) return;

    if (!_workspaceItemsMap.containsKey(workspaceId)) {
      _workspaceItemsMap[workspaceId] = [];
    }

    _workspaceItemsMap[workspaceId]!.add(item);
    _addActivity('${item.title} added to workspace');
    _saveToStorage();
    _saveUserDataIfLoggedIn();
    notifyListeners();
  }

  void updateWorkspaceItem(int index, WorkspaceItem item,
      {required String workspaceId}) {
    if (workspaceId.isEmpty) return;

    final items = _workspaceItemsMap[workspaceId];
    if (items != null && index < items.length) {
      items[index] = item;
      _addActivity('${item.title} updated');
      _saveToStorage();
      _saveUserDataIfLoggedIn();
      notifyListeners();
    }
  }

  void removeWorkspaceItem(int index, {required String workspaceId}) {
    if (workspaceId.isEmpty) return;

    final items = _workspaceItemsMap[workspaceId];
    if (items != null && index < items.length) {
      final title = items[index].title;
      items.removeAt(index);
      _addActivity('$title removed from workspace');
      _saveToStorage();
      _saveUserDataIfLoggedIn();
      notifyListeners();
    }
  }

  void addTask(Task task, {required String workspaceId}) {
    addWorkspaceItem(task, workspaceId: workspaceId);
  }

  void addNote(Note note, {required String workspaceId}) {
    addWorkspaceItem(note, workspaceId: workspaceId);
  }

  void addDocument(Document document, {required String workspaceId}) {
    addWorkspaceItem(document, workspaceId: workspaceId);
  }

  void initializeWorkspaceItems(String workspaceId) {
    if (!_workspaceItemsMap.containsKey(workspaceId)) {
      _workspaceItemsMap[workspaceId] = [];
      _saveToStorage();
      notifyListeners();
    }
  }

  // ============ ACTIVITY MANAGEMENT ============

  void addActivity(String description) {
    _addActivity(description);
  }

  void _addActivity(String description) {
    _recentActivities.insert(0, {
      'description': description,
      'timestamp': DateTime.now().toIso8601String(),
    });
    if (_recentActivities.length > 20) _recentActivities.removeLast();
    _saveActivitiesToStorage();
    _saveUserDataIfLoggedIn();
    notifyListeners();
  }

  // ============ USER-SCOPED STORAGE ============

  Future<String> _getUserScopedKey(String baseKey) async {
    if (_currentUserId != null && _currentUserId!.isNotEmpty) {
      return '${baseKey}_$_currentUserId';
    }
    return baseKey;
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getUserScopedKey('workspace_items');

    final Map<String, List<Map<String, dynamic>>> allItemsJson = {};
    _workspaceItemsMap.forEach((workspaceId, items) {
      allItemsJson[workspaceId] = items.map((item) => item.toJson()).toList();
    });

    await prefs.setString(key, jsonEncode(allItemsJson));
  }

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getUserScopedKey('workspace_items');

    final allItemsJson = prefs.getString(key);
    if (allItemsJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(allItemsJson);
      _workspaceItemsMap = {};
      decoded.forEach((workspaceId, itemsJson) {
        final items = (itemsJson as List).map((json) {
          if (json.containsKey('description') && json.containsKey('priority')) {
            return Task.fromJson(json);
          } else if (json.containsKey('content') && json.containsKey('tags')) {
            return Note.fromJson(json);
          } else if (json.containsKey('filePath') &&
              json.containsKey('fileType')) {
            return Document.fromJson(json);
          } else {
            return Task(
              id: json['id'],
              workspaceId: json['workspaceId'],
              title: json['title'],
              subtitle: json['subtitle'],
              icon: _getIconFromValue(json['icon']),
              description: '',
              priority: TaskPriority.medium,
              status: TaskStatus.pending,
              dueDate: null,
              reminderAt: null,
              reminderEnabled: false,
              reminderCompleted: false,
              createdAt: DateTime.parse(json['createdAt']),
              updatedAt: DateTime.parse(json['updatedAt']),
            );
          }
        }).toList();
        _workspaceItemsMap[workspaceId] = items;
      });
    }

    final activitiesKey = await _getUserScopedKey('recent_activities');
    final activitiesJson = prefs.getString(activitiesKey);
    if (activitiesJson != null) {
      _recentActivities =
          List<Map<String, dynamic>>.from(jsonDecode(activitiesJson));
    }

    notifyListeners();
  }

  Future<void> _saveActivitiesToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getUserScopedKey('recent_activities');
    await prefs.setString(key, jsonEncode(_recentActivities));
  }

  void clearAllItemsForWorkspace(String workspaceId) {
    _workspaceItemsMap[workspaceId] = [];
    _saveToStorage();
    _saveUserDataIfLoggedIn();
    notifyListeners();
  }

  void clearAllData() {
    _workspaceItemsMap.clear();
    _recentActivities.clear();
    _focusSessions.clear();
    _currentUserId = null;
    _saveToStorage();
    _saveFocusSessions();
    notifyListeners();
  }

  // ============ USER-SPECIFIC DATA MANAGEMENT ============

  Future<void> loadUserData(String userId) async {
    _currentUserId = userId;
    debugPrint('📂 Loading user data for: $userId');
    _workspaceItemsMap.clear();
    _recentActivities.clear();
    _focusSessions.clear();
    await _loadFromStorage();
    await _loadFocusSessions();
    debugPrint('✅ Loaded data from local storage for user: $userId');
    notifyListeners();
  }

  Future<void> _saveUserDataIfLoggedIn() async {
    if (_currentUserId != null && _currentUserId!.isNotEmpty) {
      await _saveToStorage();
      await _saveFocusSessions();
      await _saveActivitiesToStorage();
    }
  }

  Future<void> clearUserData(String userId) async {
    _currentUserId = null;
    _workspaceItemsMap.clear();
    _recentActivities.clear();
    _focusSessions.clear();
    notifyListeners();
    debugPrint('🗑️ Cleared in-memory data for user: $userId');
  }

  // ============ HELPER: GET ICON FROM VALUE ============

  IconData _getIconFromValue(dynamic iconValue) {
    // If it's already an int, convert to IconData
    if (iconValue is int) {
      return IconData(iconValue, fontFamily: 'MaterialIcons');
    }
    // If it's a String, try to parse as icon name
    if (iconValue is String) {
      switch (iconValue) {
        case 'Icons.task_alt':
          return Icons.task_alt;
        case 'Icons.check_circle_outline_rounded':
          return Icons.check_circle_outline_rounded;
        case 'Icons.notes_rounded':
          return Icons.notes_rounded;
        case 'Icons.description_rounded':
          return Icons.description_rounded;
        case 'Icons.image':
          return Icons.image;
        case 'Icons.folder':
          return Icons.folder;
        default:
          return Icons.task_alt;
      }
    }
    return Icons.task_alt;
  }

  // ============ GET ALL WORKSPACE ITEMS ============

  List<WorkspaceItem> getAllWorkspaceItems() {
    final allItems = <WorkspaceItem>[];
    for (var items in _workspaceItemsMap.values) {
      allItems.addAll(items);
    }
    return allItems;
  }

  // ============ FIND WORKSPACE ID FOR ITEM ============

  String? findWorkspaceIdForItem(String itemId) {
    for (var entry in _workspaceItemsMap.entries) {
      final exists = entry.value.any((item) => item.id == itemId);
      if (exists) {
        return entry.key;
      }
    }
    return null;
  }

  // ============ BACKEND SYNC ============

  Future<void> loadAllDataFromBackend() async {
    try {
      debugPrint('🔄 Loading all data from backend...');
      final Map<String, List<WorkspaceItem>> newWorkspaceItemsMap = {};
      final List<Map<String, dynamic>> newRecentActivities = [];

      // Get workspaces from backend - ✅ FIXED: using _workspaceService
      final workspacesResponse = await _workspaceService.getWorkspaces();
      List<Workspace> workspaces = [];
      if (workspacesResponse['success'] == true) {
        final workspacesData = workspacesResponse['data'] as List;
        debugPrint('WORKSPACE RAW JSON:');
        debugPrint(workspacesData.toString());
        workspaces =
            workspacesData.map((json) => Workspace.fromJson(json)).toList();
      }

      for (var workspace in workspaces) {
        // Always ensure the NEW map has this key
        newWorkspaceItemsMap.putIfAbsent(workspace.id, () => []);

        // Load tasks - ✅ FIXED: using _taskApi
        // Load tasks
        try {
          final tasksResponse =
              await _taskApi.getTasks(workspaceId: workspace.id);

          // ✅ Debug: Log what we got
          debugPrint('📝 Tasks response: $tasksResponse');

          if (tasksResponse['success'] == true) {
            final data = tasksResponse['data'];

            // ✅ Handle both List and Map responses
            List tasksList = [];
            if (data is List) {
              tasksList = data;
            } else if (data is Map && data.containsKey('tasks')) {
              tasksList = data['tasks'] ?? [];
            } else {
              tasksList = data as List? ?? [];
            }

            for (var taskJson in tasksList) {
              try {
                final task = Task.fromApiJson(taskJson);
                final exists = newWorkspaceItemsMap[workspace.id]!
                    .any((item) => item.id == task.id);
                if (!exists) {
                  newWorkspaceItemsMap[workspace.id]!.add(task);
                  debugPrint('✅ Added task: ${task.title}');
                }
              } catch (e) {
                debugPrint('❌ Error parsing task: $e');
                debugPrint('❌ Task JSON: $taskJson');
              }
            }
          }
        } catch (e) {
          debugPrint('❌ Error loading tasks: $e');
        }

// Load notes
        try {
          final notesResponse =
              await _noteApi.getNotes(workspaceId: workspace.id);

          // ✅ DEBUG: Log what we got
          print('📝 Notes response: $notesResponse');
          print('📝 Notes data type: ${notesResponse['data'].runtimeType}');

          if (notesResponse['success'] == true) {
            final data = notesResponse['data'];

            // ✅ Check if data is a List or Map
            if (data is List) {
              final notes = data;
              for (var noteJson in notes) {
                try {
                  final note = Note.fromJson(noteJson);
                  newWorkspaceItemsMap[workspace.id]!.add(note);
                  debugPrint('✅ Added note: ${note.title}');
                } catch (e) {
                  debugPrint('❌ Error parsing note: $e');
                }
              }
            } else if (data is Map) {
              // If it's a Map, try to extract notes from it
              final notes = data['notes'] ?? [];
              for (var noteJson in notes) {
                try {
                  final note = Note.fromJson(noteJson);
                  newWorkspaceItemsMap[workspace.id]!.add(note);
                  debugPrint('✅ Added note: ${note.title}');
                } catch (e) {
                  debugPrint('❌ Error parsing note: $e');
                }
              }
            } else {
              print('❌ Unexpected notes data type: ${data.runtimeType}');
            }
          }
        } catch (e) {
          debugPrint('❌ Error loading notes: $e');
        }

        // Load documents - ✅ FIXED: using _documentService
        try {
          final docsResponse =
              await _documentService.getDocuments(workspaceId: workspace.id);
          if (docsResponse['success'] == true) {
            final documents = docsResponse['data'] as List? ?? [];
            for (var docJson in documents) {
              try {
                final document = Document.fromJson(docJson);
                newWorkspaceItemsMap[workspace.id]!.add(document);
              } catch (e) {
                debugPrint('❌ Error parsing document: $e');
              }
            }
          }
        } catch (e) {
          debugPrint('❌ Error loading documents: $e');
        }
      }

      if (newWorkspaceItemsMap.isNotEmpty) {
        _workspaceItemsMap = newWorkspaceItemsMap;
      }

      if (newRecentActivities.isNotEmpty) {
        _recentActivities = newRecentActivities;
      }

      _saveToStorage();
      _saveUserDataIfLoggedIn();
      notifyListeners();
      debugPrint('✅ Loaded all data from backend successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading data from backend: $e');
      debugPrint('❌ Real Stack Trace:');
      debugPrint(stackTrace.toString());
    }
  }

  // ============ DELETE USER DATA ============

  Future<void> deleteUserData(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data_$userId');
    await prefs.remove('workspace_items_$userId');
    await prefs.remove('recent_activities_$userId');
    await prefs.remove('focus_sessions_$userId');

    _currentUserId = null;
    _workspaceItemsMap.clear();
    _recentActivities.clear();
    _focusSessions.clear();
    notifyListeners();
    debugPrint('🗑️ Permanently deleted user data for: $userId');
  }
}

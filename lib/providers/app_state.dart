// lib/providers/app_state.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './workspace_provider.dart';
import '../models/workspace/workspace.dart';
import '../models/workspace_items/workspace_item.dart';
import '../models/workspace_items/task.dart';
import '../models/workspace_items/note.dart';
import '../models/workspace_items/document.dart';
import '../models/focus_session.dart';
import '../services/api/document_api.dart';
import '../services/api/workspace_api.dart';
import '../services/api/task_api.dart';
import '../services/api/note_api.dart';

class AppState extends ChangeNotifier {
  // Workspace state
  List<Workspace> _workspaces = [];
  Workspace? _currentWorkspace;
  String _currentFilter = 'all';
  
  // Items organized by workspace
  Map<String, List<WorkspaceItem>> _workspaceItemsMap = {};
  List<Map<String, dynamic>> _recentActivities = [];
  
  // Focus sessions
  List<FocusSession> _focusSessions = [];
  
  // Current user ID
  String? _currentUserId;

  // Getters
  List<Workspace> get workspaces => _workspaces;
  Workspace? get currentWorkspace => _currentWorkspace;
  String get currentFilter => _currentFilter;
  List<Map<String, dynamic>> get recentActivities => _recentActivities;
  String? get currentUserId => _currentUserId;
  
  List<FocusSession> get focusSessions => _focusSessions;
  
  int get totalFocusMinutesToday {
    final today = DateTime.now();
    return _focusSessions
        .where((s) => s.completed && s.endTime != null && 
              s.endTime!.year == today.year &&
              s.endTime!.month == today.month &&
              s.endTime!.day == today.day)
        .fold(0, (sum, s) => sum + (s.actualSeconds ~/ 60));
  }
  
  int get totalFocusMinutesThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    startOfWeek.subtract(Duration(hours: startOfWeek.hour, minutes: startOfWeek.minute));
    
    return _focusSessions
        .where((s) => s.completed && s.endTime != null && s.endTime!.isAfter(startOfWeek))
        .fold(0, (sum, s) => sum + (s.actualSeconds ~/ 60));
  }
  
  int get totalFocusMinutesThisMonth {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    
    return _focusSessions
        .where((s) => s.completed && s.endTime != null && s.endTime!.isAfter(startOfMonth))
        .fold(0, (sum, s) => sum + (s.actualSeconds ~/ 60));
  }
  
  int get completedSessionsToday {
    final today = DateTime.now();
    return _focusSessions
        .where((s) => s.completed && s.endTime != null &&
              s.endTime!.year == today.year &&
              s.endTime!.month == today.month &&
              s.endTime!.day == today.day)
        .length;
  }
  
  double get averageFocusDuration {
    if (_focusSessions.isEmpty) return 0.0;
    final totalSeconds = _focusSessions.fold(0, (sum, s) => sum + s.actualSeconds);
    return (totalSeconds / _focusSessions.length) / 60;
  }
  
  Map<DateTime, int> get focusMinutesLast7Days {
    final result = <DateTime, int>{};
    final now = DateTime.now();
    
    for (int i = 6; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day - i);
      final minutes = _focusSessions
          .where((s) => s.completed && s.endTime != null &&
                s.endTime!.year == date.year &&
                s.endTime!.month == date.month &&
                s.endTime!.day == date.day)
          .fold(0, (sum, s) => sum + (s.actualSeconds ~/ 60));
      result[date] = minutes;
    }
    
    return result;
  }
  
  List<WorkspaceItem> get workspaceItems {
    if (_currentWorkspace == null) return [];
    return _workspaceItemsMap[_currentWorkspace!.id] ?? [];
  }
  
  List<WorkspaceItem> get filteredWorkspaceItems {
    final items = workspaceItems;
    if (_currentFilter == 'all') return items;
    
    return items.where((item) {
      switch (_currentFilter) {
        case 'tasks':
          return item is Task;
        case 'notes':
          return item is Note;
        case 'files':
          return item is Document;
        default:
          return true;
      }
    }).toList();
  }
  
  List<Task> get tasks => workspaceItems.whereType<Task>().toList();
  List<Note> get notes => workspaceItems.whereType<Note>().toList();
  List<Document> get documents => workspaceItems.whereType<Document>().toList();

  List<WorkspaceItem> getItemsForWorkspace(String workspaceId) {
    return _workspaceItemsMap[workspaceId] ?? [];
  }
  
  int get pendingTasksCount {
    return tasks.where((t) => t.status != TaskStatus.completed).length;
  }

  AppState() {
    _loadFromStorage();
    _loadFocusSessions();
  }

  // ============ FOCUS SESSION MANAGEMENT ============
  
  void addFocusSession(FocusSession session) {
    _focusSessions.add(session);
    _saveFocusSessions();
    _addActivity('🎯 Focus session completed: ${session.actualSeconds ~/ 60} minutes');
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
    final sessionsJson = _focusSessions.map((s) => s.toJson()).toList();
    await prefs.setString('focus_sessions', jsonEncode(sessionsJson));
  }
  
  Future<void> _loadFocusSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionsJson = prefs.getString('focus_sessions');
    if (sessionsJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(sessionsJson);
        _focusSessions = decoded.map((json) => FocusSession.fromJson(json)).toList();
      } catch (e) {
        debugPrint('Error loading focus sessions: $e');
        _focusSessions = [];
      }
    }
  }

  // ============ WORKSPACE MANAGEMENT ============

  void ensureDefaultWorkspace() {
    final hasGeneral = _workspaces.any((w) => w.type == WorkspaceType.general);
    if (!hasGeneral) {
      final generalWorkspace = Workspace(
        id: 'general',
        name: 'General',
        type: WorkspaceType.general,
        icon: '🏠',
        color: Colors.blue,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _workspaces.insert(0, generalWorkspace);
      _workspaceItemsMap[generalWorkspace.id] = [];
      _saveWorkspacesToStorage();
      _saveUserDataIfLoggedIn();
    }
    
    if (_currentWorkspace == null && _workspaces.isNotEmpty) {
      _currentWorkspace = _workspaces.first;
    }
  }
  
  void addWorkspace(Workspace workspace) {
    _workspaces.add(workspace);
    _workspaceItemsMap[workspace.id] = [];
    _saveWorkspacesToStorage();
    _addActivity('Workspace created: ${workspace.name}');
    _saveUserDataIfLoggedIn();
    notifyListeners();
  }
  
  void selectWorkspace(Workspace workspace) {
    _currentWorkspace = workspace;
    _addActivity('Switched to workspace: ${workspace.name}');
    _saveUserDataIfLoggedIn();
    notifyListeners();
  }
  
  void updateWorkspace(String workspaceId, {String? name, String? icon, Color? color}) {
    final index = _workspaces.indexWhere((w) => w.id == workspaceId);
    if (index != -1) {
      final workspace = _workspaces[index];
      _workspaces[index] = Workspace(
        id: workspace.id,
        name: name ?? workspace.name,
        type: workspace.type,
        icon: icon ?? workspace.icon,
        color: color ?? workspace.color,
        createdAt: workspace.createdAt,
        updatedAt: DateTime.now(),
      );
      _saveWorkspacesToStorage();
      _addActivity('Workspace updated: ${_workspaces[index].name}');
      _saveUserDataIfLoggedIn();
      notifyListeners();
    }
  }
  
  void deleteWorkspace(String workspaceId) {
    final workspace = _workspaces.firstWhere((w) => w.id == workspaceId);
    if (workspace.type == WorkspaceType.general) {
      _addActivity('Cannot delete General workspace');
      return;
    }
    
    _workspaces.removeWhere((w) => w.id == workspaceId);
    _workspaceItemsMap.remove(workspaceId);
    
    if (_currentWorkspace?.id == workspaceId) {
      _currentWorkspace = _workspaces.first;
    }
    
    _saveWorkspacesToStorage();
    _addActivity('Workspace deleted: ${workspace.name}');
    _saveUserDataIfLoggedIn();
    notifyListeners();
  }
  
  void setFilter(String filter) {
    _currentFilter = filter;
    _addActivity('Filter changed to: $filter');
    _saveUserDataIfLoggedIn();
    notifyListeners();
  }

  // ============ WORKSPACE ITEMS CRUD ============
  
  void addWorkspaceItem(WorkspaceItem item, {String? workspaceId}) {
    final targetWorkspaceId = workspaceId ?? _currentWorkspace?.id;
    if (targetWorkspaceId == null) return;
    
    if (!_workspaceItemsMap.containsKey(targetWorkspaceId)) {
      _workspaceItemsMap[targetWorkspaceId] = [];
    }
    
    _workspaceItemsMap[targetWorkspaceId]!.add(item);
    _addActivity('${item.title} added to workspace');
    _saveToStorage();
    _saveUserDataIfLoggedIn();
    notifyListeners();
  }

  void updateWorkspaceItem(int index, WorkspaceItem item, {String? workspaceId}) {
    final targetWorkspaceId = workspaceId ?? _currentWorkspace?.id;
    if (targetWorkspaceId == null) return;
    
    final items = _workspaceItemsMap[targetWorkspaceId];
    if (items != null && index < items.length) {
      items[index] = item;
      _addActivity('${item.title} updated');
      _saveToStorage();
      _saveUserDataIfLoggedIn();
      notifyListeners();
    }
  }

  void removeWorkspaceItem(int index, {String? workspaceId}) {
    final targetWorkspaceId = workspaceId ?? _currentWorkspace?.id;
    if (targetWorkspaceId == null) return;
    
    final items = _workspaceItemsMap[targetWorkspaceId];
    if (items != null && index < items.length) {
      final title = items[index].title;
      items.removeAt(index);
      _addActivity('$title removed from workspace');
      _saveToStorage();
      _saveUserDataIfLoggedIn();
      notifyListeners();
    }
  }
  
  void addTask(Task task, {String? workspaceId}) {
    addWorkspaceItem(task, workspaceId: workspaceId);
  }
  
  void addNote(Note note, {String? workspaceId}) {
    addWorkspaceItem(note, workspaceId: workspaceId);
  }
  
  void addDocument(Document document, {String? workspaceId}) {
    addWorkspaceItem(document, workspaceId: workspaceId);
  }

  // ============ ACTIVITY MANAGEMENT ============
  
  void addActivity(String description) {
    _addActivity(description);
  }

  void _addActivity(String description) {
    _recentActivities.insert(0, {
      'description': description,
      'timestamp': DateTime.now().toIso8601String(),
      'workspaceId': _currentWorkspace?.id,
      'workspaceName': _currentWorkspace?.name,
    });
    if (_recentActivities.length > 20) _recentActivities.removeLast();
    _saveActivitiesToStorage();
    _saveUserDataIfLoggedIn();
    notifyListeners();
  }

  // ============ PERSISTENCE METHODS ============
  
  Future<void> _saveWorkspacesToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final workspacesJson = _workspaces.map((w) => w.toJson()).toList();
    await prefs.setString('workspaces', jsonEncode(workspacesJson));
  }
  
  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    
    final Map<String, List<Map<String, dynamic>>> allItemsJson = {};
    _workspaceItemsMap.forEach((workspaceId, items) {
      allItemsJson[workspaceId] = items.map((item) => item.toJson()).toList();
    });
    
    await prefs.setString('all_workspace_items', jsonEncode(allItemsJson));
  }

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    
    final workspacesJson = prefs.getString('workspaces');
    if (workspacesJson != null) {
      final List<dynamic> decoded = jsonDecode(workspacesJson);
      _workspaces = decoded.map((json) => Workspace.fromJson(json)).toList();
    }
    
    if (_workspaces.isEmpty) {
      _currentWorkspace = null;
    }
    
    final allItemsJson = prefs.getString('all_workspace_items');
    if (allItemsJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(allItemsJson);
      _workspaceItemsMap = {};
      decoded.forEach((workspaceId, itemsJson) {
        final items = (itemsJson as List).map((json) {
          if (json.containsKey('description') && json.containsKey('priority')) {
            return Task.fromJson(json);
          } else if (json.containsKey('content') && json.containsKey('tags')) {
            return Note.fromJson(json);
          } else if (json.containsKey('filePath') && json.containsKey('fileType')) {
            return Document.fromJson(json);
          } else {
            return Task(
              id: json['id'],
              workspaceId: json['workspaceId'],
              title: json['title'],
              subtitle: json['subtitle'],
              icon: IconData(json['icon'], fontFamily: 'MaterialIcons'),
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
    
    if (_workspaces.isNotEmpty && _currentWorkspace == null) {
      _currentWorkspace = _workspaces.first;
      if (!_workspaceItemsMap.containsKey(_currentWorkspace!.id)) {
        _workspaceItemsMap[_currentWorkspace!.id] = [];
      }
    }
    
    final activitiesJson = prefs.getString('recent_activities');
    if (activitiesJson != null) {
      _recentActivities = List<Map<String, dynamic>>.from(jsonDecode(activitiesJson));
    }
    
    notifyListeners();
  }

  void _createDefaultWorkspace() {
    final generalWorkspace = Workspace(
      id: 'general',
      name: 'General',
      type: WorkspaceType.general,
      icon: '🏠',
      color: Colors.blue,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _workspaces.add(generalWorkspace);
    _workspaceItemsMap[generalWorkspace.id] = [];
    _saveWorkspacesToStorage();
  }

  Future<void> _saveActivitiesToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('recent_activities', jsonEncode(_recentActivities));
  }
  
  void clearAllItemsForWorkspace(String workspaceId) {
    _workspaceItemsMap[workspaceId] = [];
    _saveToStorage();
    _saveUserDataIfLoggedIn();
    notifyListeners();
  }
  
  void clearAllData() {
    _workspaces.clear();
    _workspaceItemsMap.clear();
    _recentActivities.clear();
    _focusSessions.clear();
    _currentWorkspace = null;
    _createDefaultWorkspace();
    _saveWorkspacesToStorage();
    _saveToStorage();
    _saveFocusSessions();
    notifyListeners();
  }

  // ============ USER-SPECIFIC DATA MANAGEMENT ============
  
  // lib/providers/app_state.dart

Future<void> loadUserData(String userId, WorkspaceProvider workspaceProvider) async {
  _currentUserId = userId;
  
  print('📂 Loading user data for: $userId');
  
  // Clear existing data
  _workspaces.clear();
  _workspaceItemsMap.clear();
  _recentActivities.clear();
  _focusSessions.clear();
  
  // ✅ Load workspaces from backend
  await workspaceProvider.loadWorkspaces();
  
  // Then load local data
  final prefs = await SharedPreferences.getInstance();
  final key = 'user_data_$userId';
  final data = prefs.getString(key);
  
  if (data != null) {
    try {
      final decoded = jsonDecode(data);
      
      // Only load items and activities from local storage
      // Workspaces are already loaded from backend
      _workspaceItemsMap = {};
      if (decoded['items'] != null) {
        decoded['items'].forEach((workspaceId, itemsJson) {
          _workspaceItemsMap[workspaceId] = (itemsJson as List)
              .map((json) => _parseWorkspaceItem(json))
              .toList();
        });
      }
      _recentActivities = List<Map<String, dynamic>>.from(decoded['activities'] ?? []);
      
      print('✅ Loaded ${workspaceProvider.workspaces.length} workspaces from backend');
      print('✅ Loaded ${_recentActivities.length} activities from local');
      
      // Set current workspace from backend
      if (workspaceProvider.workspaces.isNotEmpty) {
        _currentWorkspace = workspaceProvider.workspaces.first;
        workspaceProvider.selectWorkspace(_currentWorkspace!);
      }
      
      notifyListeners();
    } catch (e) {
      print('❌ Error loading user data: $e');
      _createDefaultWorkspace();
      _saveUserData(userId);
    }
  } else {
    print('🆕 First time user, creating default workspace');
    _createDefaultWorkspace();
    _saveUserData(userId);
  }
}

  Future<void> _saveUserData(String userId) async {
    if (userId.isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'workspaces': _workspaces.map((w) => w.toJson()).toList(),
      'items': _workspaceItemsMap.map((key, items) => 
        MapEntry(key, items.map((item) => item.toJson()).toList())
      ),
      'activities': _recentActivities,
    };
    await prefs.setString('user_data_$userId', jsonEncode(data));
    print('💾 Saved user data for: $userId');
  }
  
  Future<void> _saveUserDataIfLoggedIn() async {
    if (_currentUserId != null && _currentUserId!.isNotEmpty) {
      await _saveUserData(_currentUserId!);
    }
  }

  Future<void> clearUserData(String userId) async {
     _currentUserId = null;
  _workspaces.clear();
  _workspaceItemsMap.clear();
  _recentActivities.clear();
  _focusSessions.clear();
  _currentWorkspace = null;
  _createDefaultWorkspace();
  notifyListeners();
  print('🗑️ Cleared in-memory data for user: $userId (storage preserved)');
  }
  
  Future<void> saveUserData(String userId) async {
    await _saveUserData(userId);
  }

  // ============ PARSE WORKSPACE ITEM ============
  
  WorkspaceItem _parseWorkspaceItem(Map<String, dynamic> json) {
    if (json.containsKey('description') && json.containsKey('priority')) {
      return Task.fromJson(json);
    } else if (json.containsKey('content') && json.containsKey('tags')) {
      return Note.fromJson(json);
    } else if (json.containsKey('filePath') && json.containsKey('fileType')) {
      return Document.fromJson(json);
    } else {
      return Task(
        id: json['id'],
        workspaceId: json['workspaceId'],
        title: json['title'],
        subtitle: json['subtitle'],
        icon: IconData(json['icon'], fontFamily: 'MaterialIcons'),
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
  }

  // ============ BACKEND SYNC ============

  Future<void> loadAllDataFromBackend() async {
    try {
      final workspacesResponse = await WorkspaceApi.getWorkspaces();
      if (workspacesResponse['success'] == true) {
        final workspacesData = workspacesResponse['data'] as List;
        _workspaces = workspacesData.map((json) => Workspace.fromJson(json)).toList();
        _saveWorkspacesToStorage();
      }
      
      for (var workspace in _workspaces) {
        final docsResponse = await DocumentApi.getDocuments(workspaceId: workspace.id);
        if (docsResponse['success'] == true) {
          final documents = docsResponse['data'] as List;
          if (!_workspaceItemsMap.containsKey(workspace.id)) {
            _workspaceItemsMap[workspace.id] = [];
          }
          for (var docJson in documents) {
            final document = Document.fromJson(docJson);
            final exists = _workspaceItemsMap[workspace.id]!.any((item) => item.id == document.id);
            if (!exists) {
              _workspaceItemsMap[workspace.id]!.add(document);
            }
          }
        }
      }
      
      for (var workspace in _workspaces) {
        final tasksResponse = await TaskApi.getTasks(workspaceId: workspace.id);
        if (tasksResponse['success'] == true) {
          final tasks = tasksResponse['data'] as List;
          if (!_workspaceItemsMap.containsKey(workspace.id)) {
            _workspaceItemsMap[workspace.id] = [];
          }
          for (var taskJson in tasks) {
            final task = Task.fromJson(taskJson);
            final exists = _workspaceItemsMap[workspace.id]!.any((item) => item.id == task.id);
            if (!exists) {
              _workspaceItemsMap[workspace.id]!.add(task);
            }
          }
        }
      }
      
      for (var workspace in _workspaces) {
        final notesResponse = await NoteApi.getNotes(workspaceId: workspace.id);
        if (notesResponse['success'] == true) {
          final notes = notesResponse['data'] as List;
          if (!_workspaceItemsMap.containsKey(workspace.id)) {
            _workspaceItemsMap[workspace.id] = [];
          }
          for (var noteJson in notes) {
            final note = Note.fromJson(noteJson);
            final exists = _workspaceItemsMap[workspace.id]!.any((item) => item.id == note.id);
            if (!exists) {
              _workspaceItemsMap[workspace.id]!.add(note);
            }
          }
        }
      }
      
      _saveToStorage();
      _saveUserDataIfLoggedIn();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading data from backend: $e');
    }
  }

  Future<void> deleteUserData(String userId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('user_data_$userId');
  _currentUserId = null;
  _workspaces.clear();
  _workspaceItemsMap.clear();
  _recentActivities.clear();
  _focusSessions.clear();
  _currentWorkspace = null;
  _createDefaultWorkspace();
  notifyListeners();
  print('🗑️ Permanently deleted user data for: $userId');
}
}
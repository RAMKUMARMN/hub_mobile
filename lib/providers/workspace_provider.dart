// lib/providers/workspace_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workspace/workspace.dart';
import '../services/api/workspace_service.dart';
import './app_state.dart';
import 'dart:convert';

class WorkspaceProvider extends ChangeNotifier {
  List<Workspace> _workspaces = [];
  Workspace? _currentWorkspace;
  String _currentFilter = 'all';
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentUserId;
  
  // Service
  final WorkspaceService _workspaceService = WorkspaceService();
  
  // Getters
  List<Workspace> get workspaces => _workspaces;
  Workspace? get currentWorkspace => _currentWorkspace;
  String get currentFilter => _currentFilter;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  WorkspaceProvider() {
    _ensureDefaultWorkspace();
  }

  // ============ USER ID MANAGEMENT ============
  
  void setCurrentUserId(String userId) {
    _currentUserId = userId;
  }

  // ============ USER-SCOPED STORAGE ============
  
  Future<String> _getUserScopedKey(String baseKey) async {
    if (_currentUserId != null && _currentUserId!.isNotEmpty) {
      return '${baseKey}_$_currentUserId';
    }
    return baseKey;
  }
  
  Future<void> _saveWorkspacesToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getUserScopedKey('workspaces');
    final workspacesJson = _workspaces.map((w) => w.toJson()).toList();
    await prefs.setString(key, jsonEncode(workspacesJson));
  }

  Future<void> _loadWorkspacesFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getUserScopedKey('workspaces');
    final workspacesJson = prefs.getString(key);
    if (workspacesJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(workspacesJson);
        _workspaces = decoded.map((json) => Workspace.fromJson(json)).toList();
        if (_workspaces.isNotEmpty) {
          _currentWorkspace = _workspaces.first;
        }
      } catch (e) {
        debugPrint('Error loading workspaces from storage: $e');
        _ensureDefaultWorkspace();
      }
    } else {
      _ensureDefaultWorkspace();
    }
    notifyListeners();
  }

  // ============ DEFAULT WORKSPACE ============

  void _ensureDefaultWorkspace() {
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
      _currentWorkspace = generalWorkspace;
    }
  }

  // ============ WORKSPACE CRUD ============

  Future<void> loadWorkspaces() async {
    _setLoading(true);
    try {
      await _loadWorkspacesFromStorage();
      
      // ✅ FIXED: Using _workspaceService instead of WorkspaceApi
      final response = await _workspaceService.getWorkspaces();
      if (response['success'] == true) {
        final backendWorkspaces = (response['data'] as List)
            .map((json) => Workspace.fromJson(json))
            .toList();
        
        if (backendWorkspaces.isNotEmpty) {
          _workspaces = backendWorkspaces;
          _ensureDefaultWorkspace();
          if (_currentWorkspace == null && _workspaces.isNotEmpty) {
            _currentWorkspace = _workspaces.first;
          }
          await _saveWorkspacesToStorage();
        }
        _clearError();
      } else {
        _errorMessage = response['error'];
      }
    } catch (e) {
      _errorMessage = "Failed to load workspaces";
      _ensureDefaultWorkspace();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createWorkspace(String name, {String icon = '📁', Color color = Colors.blue}) async {
    _setLoading(true);
    try {
      // ✅ FIXED: Using _workspaceService instead of WorkspaceApi
      // ✅ FIXED: Using toARGB32() instead of deprecated .value
      final response = await _workspaceService.createWorkspace(
        name: name,
        icon: icon,
        colorHex: color.toARGB32().toRadixString(16).padLeft(8, '0'),
      );

      if (response['success'] != true || response['data'] == null) {
        _errorMessage = response['error'] as String? ??
            'Failed to create workspace. Please check your connection and try again.';
        _setLoading(false);
        return false;
      }

      final newWorkspace = Workspace.fromJson(response['data']);

      _workspaces.add(newWorkspace);
      await _saveWorkspacesToStorage();

      // Initialize workspace items in AppState
      final appState = AppState();
      appState.initializeWorkspaceItems(newWorkspace.id);

      _currentWorkspace = newWorkspace;

      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = "Failed to create workspace: $e";
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateWorkspace(
    String workspaceId, {
    String? name,
    String? icon,
    Color? color,
  }) async {
    _setLoading(true);
    try {
      final index = _workspaces.indexWhere((w) => w.id == workspaceId);
      if (index != -1) {
        final workspace = _workspaces[index];
        final updatedWorkspace = Workspace(
          id: workspace.id,
          name: name ?? workspace.name,
          type: workspace.type,
          icon: icon ?? workspace.icon,
          color: color ?? workspace.color,
          createdAt: workspace.createdAt,
          updatedAt: DateTime.now(),
        );
        _workspaces[index] = updatedWorkspace;
        
        if (_currentWorkspace?.id == workspaceId) {
          _currentWorkspace = updatedWorkspace;
        }
        
        await _saveWorkspacesToStorage();
        _clearError();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = "Failed to update workspace";
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteWorkspace(String workspaceId) async {
    _setLoading(true);
    try {
      final workspace = _workspaces.firstWhere((w) => w.id == workspaceId);
      if (workspace.type == WorkspaceType.general) {
        _errorMessage = "Cannot delete General workspace";
        _setLoading(false);
        return false;
      }
      
      // ✅ FIXED: Using _workspaceService instead of WorkspaceApi
      await _workspaceService.deleteWorkspace(workspaceId);
      _workspaces.removeWhere((w) => w.id == workspaceId);
      
      if (_currentWorkspace?.id == workspaceId && _workspaces.isNotEmpty) {
        _currentWorkspace = _workspaces.first;
      }
      
      await _saveWorkspacesToStorage();
      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _workspaces.removeWhere((w) => w.id == workspaceId);
      if (_currentWorkspace?.id == workspaceId && _workspaces.isNotEmpty) {
        _currentWorkspace = _workspaces.first;
      }
      await _saveWorkspacesToStorage();
      notifyListeners();
      return true;
    } finally {
      _setLoading(false);
    }
  }

  // ============ WORKSPACE SELECTION ============

  void selectWorkspace(Workspace workspace) {
    _currentWorkspace = workspace;
    _saveWorkspacesToStorage();
    notifyListeners();
  }

  void selectWorkspaceById(String workspaceId) {
    try {
      final workspace = _workspaces.firstWhere((w) => w.id == workspaceId);
      _currentWorkspace = workspace;
      _saveWorkspacesToStorage();
      notifyListeners();
    } catch (e) {
      // Workspace not found
    }
  }

  void setFilter(String filter) {
    _currentFilter = filter.toLowerCase();
    notifyListeners();
  }

  // ============ USER-SPECIFIC LOADING ============

  Future<void> loadUserWorkspaces(String userId) async {
    setCurrentUserId(userId);
    _setLoading(true);
    try {
      // ✅ FIXED: Using _workspaceService instead of WorkspaceApi
      final response = await _workspaceService.getWorkspaces();
      if (response['success'] == true) {
        _workspaces = (response['data'] as List)
            .map((json) => Workspace.fromJson(json))
            .toList();
        
        _ensureDefaultWorkspace();
        if (_workspaces.isNotEmpty) {
          _currentWorkspace = _workspaces.first;
        }
        await _saveWorkspacesToStorage();
        _clearError();
      } else {
        _errorMessage = response['error'];
        await _loadWorkspacesFromStorage();
      }
    } catch (e) {
      _errorMessage = "Failed to load workspaces";
      await _loadWorkspacesFromStorage();
    } finally {
      _setLoading(false);
    }
  }

  // ============ CLEAR DATA ON LOGOUT ============

  void clearWorkspaces() {
    _workspaces.clear();
    _currentWorkspace = null;
    _currentUserId = null;
    _ensureDefaultWorkspace();
    _saveWorkspacesToStorage();
    notifyListeners();
  }

  // ============ HELPER METHODS ============

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _clearError() {
    _errorMessage = null;
  }
  
  Future<void> refresh() async {
    if (_currentUserId != null) {
      await loadUserWorkspaces(_currentUserId!);
    } else {
      await loadWorkspaces();
    }
  }
  
  Workspace? getWorkspaceById(String id) {
    try {
      return _workspaces.firstWhere((w) => w.id == id);
    } catch (e) {
      return null;
    }
  }
  
  bool hasWorkspace(String id) {
    return _workspaces.any((w) => w.id == id);
  }
}
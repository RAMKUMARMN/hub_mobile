// lib/providers/workspace_provider.dart
import 'package:flutter/material.dart';
import '../models/workspace/workspace.dart';
import '../models/workspace_items/workspace_item.dart';
import '../services/api/workspace_api.dart';
import '../services/api/api_services.dart';
import './app_state.dart';

class WorkspaceProvider extends ChangeNotifier {
  List<Workspace> _workspaces = [];
  Workspace? _currentWorkspace;
  String _currentFilter = 'all';
  bool _isLoading = false;
  String? _errorMessage;
  
  // Getters
  List<Workspace> get workspaces => _workspaces;
  Workspace? get currentWorkspace => _currentWorkspace;
  String get currentFilter => _currentFilter;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  WorkspaceProvider() {
    _ensureDefaultWorkspace();
  }

  void _ensureDefaultWorkspace() {
    if (_workspaces.isEmpty) {
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
      _currentWorkspace = generalWorkspace;
    }
  }

  Future<void> loadWorkspaces() async {
    _setLoading(true);
    try {
      final response = await WorkspaceApi.getWorkspaces();
      if (response['success'] == true) {
        _workspaces = (response['data'] as List)
            .map((json) => Workspace.fromJson(json))
            .toList();
        
        _ensureDefaultWorkspace();
        
        if (_currentWorkspace == null && _workspaces.isNotEmpty) {
          _currentWorkspace = _workspaces.first;
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
      final newWorkspace = Workspace(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        type: WorkspaceType.project,
        icon: icon,
        color: color,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _workspaces.add(newWorkspace);

      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = "Failed to create workspace";
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
        _workspaces[index] = Workspace(
          id: workspace.id,
          name: name ?? workspace.name,
          type: workspace.type,
          icon: icon ?? workspace.icon,
          color: color ?? workspace.color,
          createdAt: workspace.createdAt,
          updatedAt: DateTime.now(),
        );
        if (_currentWorkspace?.id == workspaceId) {
          _currentWorkspace = _workspaces[index];
        }
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
      
      _workspaces.removeWhere((w) => w.id == workspaceId);
      
      if (_currentWorkspace?.id == workspaceId && _workspaces.isNotEmpty) {
        _currentWorkspace = _workspaces.first;
      }
      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = "Failed to delete workspace";
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void selectWorkspace(Workspace workspace) {
    _currentWorkspace = workspace;
    notifyListeners();
  }

  void selectWorkspaceById(String workspaceId) {
    try {
      final workspace = _workspaces.firstWhere((w) => w.id == workspaceId);
      _currentWorkspace = workspace;
      notifyListeners();
    } catch (e) {
      // Workspace not found
    }
  }

  void setFilter(String filter) {
    _currentFilter = filter.toLowerCase();
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _clearError() {
    _errorMessage = null;
  }
  
  Future<void> refresh() async {
    await loadWorkspaces();
  }

  // lib/providers/workspace_provider.dart

// Add this method
Future<void> loadUserWorkspaces(String userId) async {
  _setLoading(true);
  try {
    final response = await WorkspaceApi.getWorkspaces();
    if (response['success'] == true) {
      _workspaces = (response['data'] as List)
          .map((json) => Workspace.fromJson(json))
          .toList();
      
      // Don't add default workspace - backend already has it
      if (_workspaces.isNotEmpty) {
        _currentWorkspace = _workspaces.first;
      }
      _clearError();
    } else {
      _errorMessage = response['error'];
    }
  } catch (e) {
    _errorMessage = "Failed to load workspaces";
  } finally {
    _setLoading(false);
  }
}
}
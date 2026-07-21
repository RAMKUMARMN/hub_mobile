// lib/models/workspace_type.dart
enum WorkspaceType {
  general,
  project,
}

extension WorkspaceTypeExtension on WorkspaceType {
  String get displayName {
    switch (this) {
      case WorkspaceType.general:
        return 'General';
      case WorkspaceType.project:
        return 'Project';
    }
  }
  
  String get icon {
    switch (this) {
      case WorkspaceType.general:
        return '🏠';
      case WorkspaceType.project:
        return '📁';
    }
  }
}
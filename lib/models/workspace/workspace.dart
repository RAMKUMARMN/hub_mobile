import 'package:flutter/material.dart';

class Workspace {
  final String id;
  final String name;
  final WorkspaceType type;
  final String icon;
  final Color color;
  final DateTime createdAt;
  final DateTime updatedAt;

  Workspace({
    required this.id,
    required this.name,
    this.type = WorkspaceType.project,
    this.icon = '📁',
    this.color = Colors.blue,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.index,
    'icon': icon,
    'color': color.toARGB32(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };



factory Workspace.fromJson(Map<String, dynamic> json) {
  WorkspaceType workspaceType = WorkspaceType.project;

  // Handle backend sending either string or int type
  if (json['type'] is int) {
    final index = json['type'] as int;
    if (index >= 0 && index < WorkspaceType.values.length) {
      workspaceType = WorkspaceType.values[index];
    }
  } else if (json['type'] is String) {
    workspaceType =
        json['type'].toString().toLowerCase() == 'general'
            ? WorkspaceType.general
            : WorkspaceType.project;
  }

  // Handle backend sending hex color string (#0080FF)
  Color workspaceColor = Colors.blue;

  if (json['color'] is int) {
    workspaceColor = Color(json['color']);
  } else if (json['color'] is String) {
    try {
      String colorString = json['color'].toString().replaceFirst('#', '');

      if (colorString.length == 6) {
        colorString = 'FF$colorString';
      }

      workspaceColor = Color(
        int.parse(colorString, radix: 16),
      );
    } catch (_) {
      workspaceColor = Colors.blue;
    }
  }

  return Workspace(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? 'Untitled',
    type: workspaceType,
    icon: json['icon']?.toString() ?? '📁',
    color: workspaceColor,

    // Support BOTH backend snake_case and frontend camelCase
    createdAt: DateTime.parse(
      (json['created_at'] ?? json['createdAt']).toString(),
    ),

    updatedAt: DateTime.parse(
      (json['updated_at'] ?? json['updatedAt']).toString(),
    ),
  );
}
}

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
}
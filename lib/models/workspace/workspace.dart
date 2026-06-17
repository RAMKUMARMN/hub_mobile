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

  factory Workspace.fromJson(Map<String, dynamic> json) => Workspace(
    id: json['id'],
    name: json['name'],
    type: WorkspaceType.values[json['type']],
    icon: json['icon'],
    color: Color(json['color']),
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );
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
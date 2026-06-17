// lib/models/workspace_items/note.dart
import 'package:flutter/material.dart';
import 'workspace_item.dart';

class Note extends WorkspaceItem {
  final String content;
  final List<String> tags;
  final bool isFavorite;

  Note({
    required super.id,
    required super.workspaceId,
    required super.title,
    required super.subtitle,
    required super.icon,
    required this.content,
    this.tags = const [],
    this.isFavorite = false,
    required super.createdAt,
    required super.updatedAt,
  });

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'workspaceId': workspaceId,
    'title': title,
    'subtitle': subtitle,
    'icon': icon.codePoint,
    'content': content,
    'tags': tags,
    'isFavorite': isFavorite,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  // ✅ ADD THIS FACTORY METHOD
  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      workspaceId: json['workspaceId'],
      title: json['title'],
      subtitle: json['subtitle'],
      icon: IconData(json['icon'], fontFamily: 'MaterialIcons'),
      content: json['content'] ?? '',
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      isFavorite: json['isFavorite'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  String get preview => content.length > 100 ? '${content.substring(0, 100)}...' : content;
}
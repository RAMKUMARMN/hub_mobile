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

  // FIXED: backend NoteResponse sends:
  //   id, workspace_id, title, content, tags, is_favorite, created_at, updated_at
  // There is no "subtitle" field from the backend — derive one from content
  // instead, the same way Document derives its subtitle from filetype.
  // Falls back to camelCase keys too, since local SharedPreferences storage
  // (via toJson() above) still uses camelCase — this makes fromJson handle
  // both sources correctly rather than only one.
  factory Note.fromJson(Map<String, dynamic> json) {
    final content = (json['content'] ?? '').toString();
    final createdAt = DateTime.parse(
      (json['created_at'] ?? json['createdAt']).toString(),
    );

    return Note(
      id: json['id'].toString(),
      workspaceId: (json['workspace_id'] ?? json['workspaceId'])?.toString() ?? '',
      title: (json['title'] ?? 'Untitled').toString(),
      // Backend has no subtitle field — derive a short preview instead.
      subtitle: (json['subtitle'] ??
              (content.length > 60 ? '${content.substring(0, 60)}...' : content))
          .toString(),
      icon: Icons.notes_rounded,
      content: content,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      isFavorite: (json['is_favorite'] ?? json['isFavorite'] ?? false) as bool,
      createdAt: createdAt,
      updatedAt: json['updated_at'] != null || json['updatedAt'] != null
          ? DateTime.parse((json['updated_at'] ?? json['updatedAt']).toString())
          : createdAt,
    );
  }

  String get preview => content.length > 100 ? '${content.substring(0, 100)}...' : content;
}
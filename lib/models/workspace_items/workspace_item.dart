// lib/models/workspace_items/workspace_item.dart
import 'package:flutter/material.dart';

abstract class WorkspaceItem {
  final String id;
  final String workspaceId;
  final String title;
  final String subtitle;
  final IconData icon;
  final DateTime createdAt;
  final DateTime updatedAt;

  WorkspaceItem({
    required this.id,
    required this.workspaceId,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson();

  // Helper methods
  bool get hasDeadline => subtitle.toLowerCase().contains('due') || subtitle.toLowerCase().contains('deadline');
  
  String get formattedSubtitle {
    final lowerSubtitle = subtitle.toLowerCase();
    if (lowerSubtitle.contains('pending')) return ' $subtitle';
    if (lowerSubtitle.contains('completed')) return ' $subtitle';
    if (lowerSubtitle.contains('overdue')) return ' $subtitle';
    if (lowerSubtitle.contains('reminder')) return ' $subtitle';
    return subtitle;
  }
}
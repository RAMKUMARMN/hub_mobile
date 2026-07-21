// lib/models/notification_item.dart
import 'package:flutter/material.dart';

class NotificationItem {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final String category;
  final String? workspaceId;
  final DateTime createdAt;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.category,
    this.workspaceId,
    required this.createdAt,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'icon': icon.codePoint,
    'category': category,
    'workspaceId': workspaceId,
    'createdAt': createdAt.toIso8601String(),
    'isRead': isRead,
  };

  factory NotificationItem.fromJson(Map<String, dynamic> json, {required IconData icon}) => NotificationItem(
    id: json['id'],
    title: json['title'],
    subtitle: json['subtitle'],
    icon: icon,
    category: json['category'],
    workspaceId: json['workspaceId'],
    createdAt: DateTime.parse(json['createdAt']),
    isRead: json['isRead'],
  );
  
  String get timeAgo {
    final difference = DateTime.now().difference(createdAt);
    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'Just now';
  }
}
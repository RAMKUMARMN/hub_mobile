// lib/models/workspace_items/task.dart

import 'package:flutter/material.dart';
import 'workspace_item.dart';

// MUST MATCH BACKEND ENUMS (UPPERCASE)
enum TaskPriority {
  low,    // Maps to backend "LOW"
  medium, // Maps to backend "MEDIUM"  
  high,   // Maps to backend "HIGH"
  critical // Maps to backend "CRITICAL"
}

enum TaskStatus {
  pending,     // Maps to backend "PENDING"
  inProgress,  // Maps to backend "IN_PROGRESS"
  completed,   // Maps to backend "COMPLETED"
  cancelled    // Maps to backend "CANCELLED" (changed from archived)
}

extension TaskPriorityExtension on TaskPriority {
  String get apiValue {
    switch (this) {
      case TaskPriority.low: return 'LOW';
      case TaskPriority.medium: return 'MEDIUM';
      case TaskPriority.high: return 'HIGH';
      case TaskPriority.critical: return 'CRITICAL';
    }
  }
  
  String get displayName {
    switch (this) {
      case TaskPriority.low: return 'Low';
      case TaskPriority.medium: return 'Medium';
      case TaskPriority.high: return 'High';
      case TaskPriority.critical: return 'Critical';
    }
  }
  
  Color get color {
    switch (this) {
      case TaskPriority.low: return Colors.green;
      case TaskPriority.medium: return Colors.orange;
      case TaskPriority.high: return Colors.red;
      case TaskPriority.critical: return Colors.purple;
    }
  }
  
  static TaskPriority fromApiValue(String value) {
    switch (value.toUpperCase()) {
      case 'LOW': return TaskPriority.low;
      case 'MEDIUM': return TaskPriority.medium;
      case 'HIGH': return TaskPriority.high;
      case 'CRITICAL': return TaskPriority.critical;
      default: return TaskPriority.medium;
    }
  }
}

extension TaskStatusExtension on TaskStatus {
  String get apiValue {
    switch (this) {
      case TaskStatus.pending: return 'PENDING';
      case TaskStatus.inProgress: return 'IN_PROGRESS';
      case TaskStatus.completed: return 'COMPLETED';
      case TaskStatus.cancelled: return 'CANCELLED';
    }
  }
  
  String get displayName {
    switch (this) {
      case TaskStatus.pending: return 'Pending';
      case TaskStatus.inProgress: return 'In Progress';
      case TaskStatus.completed: return 'Completed';
      case TaskStatus.cancelled: return 'Cancelled';
    }
  }
  
  static TaskStatus fromApiValue(String value) {
    switch (value.toUpperCase()) {
      case 'PENDING': return TaskStatus.pending;
      case 'IN_PROGRESS': return TaskStatus.inProgress;
      case 'COMPLETED': return TaskStatus.completed;
      case 'CANCELLED': return TaskStatus.cancelled;
      default: return TaskStatus.pending;
    }
  }
}

class Task extends WorkspaceItem {
  final String description;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime? dueDate;
  final DateTime? reminderAt;
  final bool reminderEnabled;
  final bool reminderCompleted;
  
  // Backend also has these fields
  final String? userId;  // Added for backend compatibility
  final DateTime? completedAt;

  Task({
    required super.id,
    required super.workspaceId,
    required super.title,
    required super.subtitle,
    required super.icon,
    required this.description,
    required this.priority,
    required this.status,
    this.dueDate,
    this.reminderAt,
    this.reminderEnabled = false,
    this.reminderCompleted = false,
    this.userId,
    this.completedAt,
    required super.createdAt,
    required super.updatedAt,
  });

  bool get hasReminder => reminderEnabled && reminderAt != null;
  bool get isReminderOverdue => hasReminder && reminderAt!.isBefore(DateTime.now()) && !reminderCompleted;
  bool get isReminderUpcoming => hasReminder && reminderAt!.isAfter(DateTime.now()) && !reminderCompleted;
  bool get isOverdue => dueDate != null && dueDate!.isBefore(DateTime.now()) && status != TaskStatus.completed;
  bool get isCompleted => status == TaskStatus.completed;

  Task copyWith({
    String? id,
    String? workspaceId,
    String? title,
    String? subtitle,
    IconData? icon,
    String? description,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? dueDate,
    DateTime? reminderAt,
    bool? reminderEnabled,
    bool? reminderCompleted,
    String? userId,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      icon: icon ?? this.icon,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      reminderAt: reminderAt ?? this.reminderAt,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderCompleted: reminderCompleted ?? this.reminderCompleted,
      userId: userId ?? this.userId,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'workspaceId': workspaceId,
    'title': title,
    'subtitle': subtitle,
    'icon': icon.codePoint,
    'description': description,
    'priority': priority.index,
    'status': status.index,
    'dueDate': dueDate?.toIso8601String(),
    'reminderAt': reminderAt?.toIso8601String(),
    'reminderEnabled': reminderEnabled,
    'reminderCompleted': reminderCompleted,
    'userId': userId,
    'completedAt': completedAt?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  /// Convert to API format for sending to backend
  Map<String, dynamic> toApiJson() => {
    'workspace_id': workspaceId,
    'title': title,
    'description': description,
    'priority': priority.apiValue,
    'status': status.apiValue,
    'due_date': dueDate?.toIso8601String(),
    'reminder_at': reminderAt?.toIso8601String(),
  };

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      workspaceId: json['workspaceId'],
      title: json['title'],
      subtitle: json['subtitle'],
      icon: IconData(json['icon'], fontFamily: 'MaterialIcons'),
      description: json['description'] ?? '',
      priority: TaskPriority.values[json['priority']],
      status: TaskStatus.values[json['status']],
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      reminderAt: json['reminderAt'] != null ? DateTime.parse(json['reminderAt']) : null,
      reminderEnabled: json['reminderEnabled'] ?? false,
      reminderCompleted: json['reminderCompleted'] ?? false,
      userId: json['userId'],
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
  
  /// Create from backend API response
  factory Task.fromApiJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'].toString(),
      workspaceId: json['workspace_id'].toString(),
      title: json['title'],
      subtitle: json['description'] ?? '',
      icon: Icons.task_alt,
      description: json['description'] ?? '',
      priority: TaskPriorityExtension.fromApiValue(json['priority'] ?? 'MEDIUM'),
      status: TaskStatusExtension.fromApiValue(json['status'] ?? 'PENDING'),
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      reminderAt: json['reminder_at'] != null ? DateTime.parse(json['reminder_at']) : null,
      reminderEnabled: json['reminder_at'] != null,
      reminderCompleted: false,
      userId: json['user_id']?.toString(),
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
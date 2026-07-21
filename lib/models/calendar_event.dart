// lib/models/calendar_event.dart
enum NotificationMode {
  timeBased,   // Maps to backend "TIME_BASED" - notify 1 hour before
  dayStart,    // Maps to backend "DAY_START" - daily digest at 8 AM
}

extension NotificationModeExtension on NotificationMode {
  String get apiValue {
    switch (this) {
      case NotificationMode.timeBased:
        return 'TIME_BASED';
      case NotificationMode.dayStart:
        return 'DAY_START';
    }
  }
  
  static NotificationMode fromApiValue(String value) {
    switch (value.toUpperCase()) {
      case 'TIME_BASED':
        return NotificationMode.timeBased;
      case 'DAY_START':
        return NotificationMode.dayStart;
      default:
        return NotificationMode.timeBased;
    }
  }
  
  String get displayName {
    switch (this) {
      case NotificationMode.timeBased:
        return '1 hour before';
      case NotificationMode.dayStart:
        return 'Daily digest (8 AM)';
    }
  }
}

enum RecurrenceFrequency {
  daily,
  weekly,
  monthly,
  yearly,
}

extension RecurrenceFrequencyExtension on RecurrenceFrequency {
  String get apiValue {
    switch (this) {
      case RecurrenceFrequency.daily:
        return 'DAILY';
      case RecurrenceFrequency.weekly:
        return 'WEEKLY';
      case RecurrenceFrequency.monthly:
        return 'MONTHLY';
      case RecurrenceFrequency.yearly:
        return 'YEARLY';
    }
  }
  
  static RecurrenceFrequency fromApiValue(String value) {
    switch (value.toUpperCase()) {
      case 'DAILY':
        return RecurrenceFrequency.daily;
      case 'WEEKLY':
        return RecurrenceFrequency.weekly;
      case 'MONTHLY':
        return RecurrenceFrequency.monthly;
      case 'YEARLY':
        return RecurrenceFrequency.yearly;
      default:
        return RecurrenceFrequency.weekly;
    }
  }
}

class RecurrenceRule {
  final RecurrenceFrequency frequency;
  final int interval;
  final List<int>? byDay;  // 0=Monday, 6=Sunday for weekly
  final DateTime? until;
  
  RecurrenceRule({
    required this.frequency,
    this.interval = 1,
    this.byDay,
    this.until,
  });
  
  Map<String, dynamic> toJson() => {
    'freq': frequency.apiValue,
    'interval': interval,
    if (byDay != null) 'byday': byDay!.map((d) => _dayToRfc5545(d)).toList(),
    if (until != null) 'until': until!.toIso8601String(),
  };
  
  factory RecurrenceRule.fromJson(Map<String, dynamic> json) {
    return RecurrenceRule(
      frequency: RecurrenceFrequencyExtension.fromApiValue(json['freq']),
      interval: json['interval'] ?? 1,
      byDay: json['byday'] != null 
          ? (json['byday'] as List).map((d) => _dayFromRfc5545(d)).toList()
          : null,
      until: json['until'] != null ? DateTime.parse(json['until']) : null,
    );
  }
  
  static String _dayToRfc5545(int day) {
    const days = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
    return days[day % 7];
  }
  
  static int _dayFromRfc5545(String day) {
    const days = {'MO': 0, 'TU': 1, 'WE': 2, 'TH': 3, 'FR': 4, 'SA': 5, 'SU': 6};
    return days[day] ?? 0;
  }
}

class CalendarEvent {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isAllDay;
  final RecurrenceRule? recurrenceRule;
  final String? linkedTodoId;
  final NotificationMode notificationMode;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  CalendarEvent({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.startTime,
    this.endTime,
    this.isAllDay = false,
    this.recurrenceRule,
    this.linkedTodoId,
    this.notificationMode = NotificationMode.timeBased,
    required this.createdAt,
    required this.updatedAt,
  });
  
  bool get hasEndTime => endTime != null;
  bool get isRecurring => recurrenceRule != null;
  Duration get duration {
    if (endTime == null) return Duration.zero;
    return endTime!.difference(startTime);
  }
  
  String get formattedDate {
    if (isAllDay) {
      return '${startTime.day}/${startTime.month}/${startTime.year}';
    }
    return '${startTime.day}/${startTime.month}/${startTime.year} at ${_formatTime(startTime)}';
  }
  
  String get formattedTimeRange {
    if (isAllDay) return 'All day';
    if (endTime == null) return _formatTime(startTime);
    return '${_formatTime(startTime)} - ${_formatTime(endTime!)}';
  }
  
  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  
  CalendarEvent copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    bool? isAllDay,
    RecurrenceRule? recurrenceRule,
    String? linkedTodoId,
    NotificationMode? notificationMode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isAllDay: isAllDay ?? this.isAllDay,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      linkedTodoId: linkedTodoId ?? this.linkedTodoId,
      notificationMode: notificationMode ?? this.notificationMode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'title': title,
    'description': description,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'isAllDay': isAllDay,
    'recurrenceRule': recurrenceRule?.toJson(),
    'linkedTodoId': linkedTodoId,
    'notificationMode': notificationMode.apiValue,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
  
  /// Convert to API format for sending to backend
  Map<String, dynamic> toApiJson() => {
    'title': title,
    if (description != null) 'description': description,
    'start_time': startTime.toIso8601String(),
    if (endTime != null) 'end_time': endTime!.toIso8601String(),
    'is_all_day': isAllDay,
    if (recurrenceRule != null) 'recurrence_rule': recurrenceRule!.toJson(),
    if (linkedTodoId != null) 'linked_todo_id': linkedTodoId,
    'notification_mode': notificationMode.apiValue,
  };
  
  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'],
      userId: json['userId'],
      title: json['title'],
      description: json['description'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      isAllDay: json['isAllDay'] ?? false,
      recurrenceRule: json['recurrenceRule'] != null 
          ? RecurrenceRule.fromJson(json['recurrenceRule'])
          : null,
      linkedTodoId: json['linkedTodoId'],
      notificationMode: NotificationModeExtension.fromApiValue(json['notificationMode'] ?? 'TIME_BASED'),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
  
  /// Create from backend API response
  factory CalendarEvent.fromApiJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      title: json['title'],
      description: json['description'],
      startTime: DateTime.parse(json['start_time']),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      isAllDay: json['is_all_day'] ?? false,
      recurrenceRule: json['recurrence_rule'] != null 
          ? RecurrenceRule.fromJson(json['recurrence_rule'])
          : null,
      linkedTodoId: json['linked_todo_id']?.toString(),
      notificationMode: NotificationModeExtension.fromApiValue(json['notification_mode'] ?? 'TIME_BASED'),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
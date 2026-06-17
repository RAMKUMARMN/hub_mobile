// lib/models/focus_session.dart

class FocusSession {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationSeconds;  // Planned duration
  final int actualSeconds;    // Actual focused time
  final bool completed;
  final String? taskId;       // Optional: link to a task
  
  FocusSession({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.durationSeconds,
    this.actualSeconds = 0,
    this.completed = false,
    this.taskId,
  });
  
  int get remainingSeconds => durationSeconds - actualSeconds;
  double get progress => actualSeconds / durationSeconds;
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'durationSeconds': durationSeconds,
    'actualSeconds': actualSeconds,
    'completed': completed,
    'taskId': taskId,
  };
  
  factory FocusSession.fromJson(Map<String, dynamic> json) => FocusSession(
    id: json['id'],
    startTime: DateTime.parse(json['startTime']),
    endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
    durationSeconds: json['durationSeconds'],
    actualSeconds: json['actualSeconds'],
    completed: json['completed'],
    taskId: json['taskId'],
  );
}
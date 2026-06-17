// lib/services/local/notification_service.dart

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

// ============ NOTIFICATION PRIORITY ENUM ============
enum NotificationPriority {
  high,    // Deadline in <2 hours, Overdue tasks
  medium,  // Daily planning, Task postponed 2+ times
  low,     // General reminders, Inactivity alerts
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // ============ INITIALIZATION ============

  Future<void> initialize() async {
    if (_initialized) return;
    
    tz.initializeTimeZones();
    
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    } catch (e) {
      debugPrint('Timezone error: $e, falling back to UTC');
      tz.setLocalLocation(tz.UTC);
    }
    
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _plugin.initialize(settings, onDidReceiveNotificationResponse: _onNotificationTap);
    await _createNotificationChannels();
    
    _initialized = true;
  }
  
  Future<void> _createNotificationChannels() async {
    const androidChannel = AndroidNotificationChannel(
      'smart_hub_channel',
      'SmartHub Notifications',
      description: 'Task reminders and productivity alerts',
      importance: Importance.high,
      playSound: true,
    );
    
    const scheduledChannel = AndroidNotificationChannel(
      'scheduled_reminders',
      'Scheduled Reminders',
      description: 'Scheduled task reminders',
      importance: Importance.high,
      playSound: true,
    );
    
    const urgentChannel = AndroidNotificationChannel(
      'urgent_channel',
      'Urgent Reminders',
      description: 'Urgent deadlines and critical alerts',
      importance: Importance.max,
      playSound: true,
    );
    
    await _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(androidChannel);
    
    await _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(scheduledChannel);
    
    await _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(urgentChannel);
  }
  
  void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }
  
  Future<bool> requestPermissions() async {
    if (!_initialized) await initialize();
    
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      final result = await androidPlugin.requestNotificationsPermission();
      return result ?? false;
    }
    return true;
  }
  
  Future<bool> areNotificationsEnabled() async {
    if (!_initialized) await initialize();
    
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      return await androidPlugin.areNotificationsEnabled() ?? false;
    }
    return true;
  }

  // ============ PRIORITY-BASED NOTIFICATION METHODS ============
  
  Future<void> _showPrioritizedNotification({
    required String title,
    required String body,
    required String payload,
    required NotificationPriority priority,
  }) async {
    // FIXED: Added 'await' before Future<bool>
    if (!await _shouldShowNotification(payload, priority)) return;
    if (!(await areNotificationsGloballyEnabled())) return;
    
    final importance = priority == NotificationPriority.high 
        ? Importance.max
        : (priority == NotificationPriority.medium ? Importance.high : Importance.defaultImportance);
    
    final androidPriority = priority == NotificationPriority.high 
        ? Priority.high
        : (priority == NotificationPriority.medium ? Priority.high : Priority.defaultPriority);
    
    final channelId = priority == NotificationPriority.high 
        ? 'urgent_channel' 
        : 'smart_hub_channel';
    
    final androidDetails = AndroidNotificationDetails(
      channelId,
      priority == NotificationPriority.high ? 'Urgent Reminders' : 'SmartHub Notifications',
      importance: importance,
      priority: androidPriority,
      channelDescription: 'Task reminders and productivity alerts',
    );
    
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    
    await _plugin.show(
      payload.hashCode,
      title,
      body,
      details,
      payload: payload,
    );
    
    await _trackShownNotification(payload);
  }
  
  Future<bool> _shouldShowNotification(String payload, NotificationPriority priority) async {
    final prefs = await SharedPreferences.getInstance();
    final lastShown = prefs.getString('last_notification_$payload');
    
    if (lastShown != null) {
      final lastTime = DateTime.parse(lastShown);
      final hoursSince = DateTime.now().difference(lastTime).inHours;
      
      if (priority == NotificationPriority.low && hoursSince < 24) return false;
      if (priority == NotificationPriority.medium && hoursSince < 6) return false;
      if (priority == NotificationPriority.high && hoursSince < 1) return false;
    }
    
    return true;
  }
  
  Future<void> _trackShownNotification(String payload) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_notification_$payload', DateTime.now().toIso8601String());
  }

  // ============ TASK DEADLINE NOTIFICATIONS ============

  Future<void> scheduleDeadlineNotification({
    required String taskName,
    required DateTime deadline,
    required String taskId,
  }) async {
    if (!_initialized) await initialize();
    
    final now = DateTime.now();
    final hoursUntilDeadline = deadline.difference(now).inHours;
    
    if (hoursUntilDeadline < 0) return;
    
    if (hoursUntilDeadline <= 2 && hoursUntilDeadline > 0) {
      await _showPrioritizedNotification(
        title: '⚠️ Deadline Approaching',
        body: '$taskName is due in ${_formatTimeUntil(deadline)}',
        payload: 'deadline_urgent_$taskId',
        priority: NotificationPriority.high,
      );
    }
    
    if (hoursUntilDeadline > 24) {
      await _scheduleAtSpecificTime(
        title: '📅 Deadline Tomorrow',
        body: '$taskName is due tomorrow',
        scheduledTime: deadline.subtract(const Duration(days: 1)),
        payload: 'deadline_tomorrow_$taskId',
        priority: NotificationPriority.medium,
      );
    }
    
    if (hoursUntilDeadline > 1) {
      await _scheduleAtSpecificTime(
        title: '⏰ Urgent Deadline',
        body: '$taskName is due in 1 hour',
        scheduledTime: deadline.subtract(const Duration(hours: 1)),
        payload: 'deadline_1hour_$taskId',
        priority: NotificationPriority.high,
      );
    }
  }

  // ============ OVERDUE TASK ALERTS ============

  Future<void> scheduleOverdueSummary(List<String> overdueTasks) async {
    if (!_initialized) await initialize();
    if (overdueTasks.isEmpty) return;
    
    final body = overdueTasks.length == 1
        ? '${overdueTasks[0]} is overdue'
        : '${overdueTasks.length} tasks are overdue';
    
    await _showPrioritizedNotification(
      title: '❌ Overdue Tasks',
      body: body,
      payload: 'overdue_summary',
      priority: NotificationPriority.high,
    );
  }

  // ============ CUSTOM USER REMINDERS ============

  Future<void> scheduleCustomReminder({
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String reminderId,
    NotificationPriority priority = NotificationPriority.medium,
  }) async {
    if (!_initialized) await initialize();
    if (scheduledTime.isBefore(DateTime.now())) return;
    
    await _scheduleAtSpecificTime(
      title: title,
      body: body,
      scheduledTime: scheduledTime,
      payload: 'reminder_$reminderId',
      priority: priority,
    );
  }

  // ============ TASK POSTPONEMENT ALERTS ============

  Future<void> sendTaskPostponedAlert(String taskName, int timesPostponed) async {
    if (!_initialized) await initialize();
    if (timesPostponed < 2) return;
    
    String message;
    NotificationPriority priority;
    
    if (timesPostponed == 2) {
      message = 'You\'ve postponed "$taskName" twice. Time to tackle it?';
      priority = NotificationPriority.medium;
    } else if (timesPostponed <= 4) {
      message = '⚠️ "$taskName" postponed $timesPostponed times';
      priority = NotificationPriority.medium;
    } else {
      message = '🚨 "$taskName" postponed $timesPostponed times';
      priority = NotificationPriority.high;
    }
    
    await _showPrioritizedNotification(
      title: '🤔 Productivity Insight',
      body: message,
      payload: 'postponed_${taskName.hashCode}',
      priority: priority,
    );
  }

  // ============ INACTIVITY REMINDERS ============

  Future<void> sendInactivityAlert({
    required String workspaceName,
    required int daysInactive,
  }) async {
    if (!_initialized) await initialize();
    if (daysInactive < 3) return;
    
    NotificationPriority priority = NotificationPriority.low;
    String title = '💡 Workspace Reminder';
    
    if (daysInactive >= 7) {
      title = '⚠️ Long Inactivity';
      priority = NotificationPriority.medium;
    }
    
    await _showPrioritizedNotification(
      title: title,
      body: 'You haven\'t opened "$workspaceName" in $daysInactive days.',
      payload: 'inactivity_$workspaceName',
      priority: priority,
    );
  }

  // ============ DAILY PLANNING REMINDER ============

  Future<void> scheduleDailyPlanningReminder({required TimeOfDay time}) async {
    if (!_initialized) await initialize();
    
    final now = DateTime.now();
    DateTime scheduledDate = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    await _scheduleAtSpecificTime(
      title: '📝 Daily Planning',
      body: 'Plan tomorrow\'s tasks before ending the day.',
      scheduledTime: scheduledDate,
      payload: 'daily_planning',
      priority: NotificationPriority.low,
    );
  }

  // ============ PRODUCTIVITY SUMMARY (Weekly) ============

  Future<void> scheduleWeeklySummary({
    required DateTime scheduledTime,
    required int completedTasks,
    required int totalFocusMinutes,
  }) async {
    if (!_initialized) await initialize();
    
    await _scheduleAtSpecificTime(
      title: '📊 Weekly Productivity Summary',
      body: 'You completed $completedTasks tasks and focused for $totalFocusMinutes minutes this week!',
      scheduledTime: scheduledTime,
      payload: 'weekly_summary',
      priority: NotificationPriority.low,
    );
  }

  // ============ CANCEL NOTIFICATIONS ============

  Future<void> cancelNotification(String notificationId) async {
    await _plugin.cancel(notificationId.hashCode);
  }

  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  // ============ PRIVATE METHODS ============

  Future<void> _scheduleAtSpecificTime({
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String payload,
    NotificationPriority priority = NotificationPriority.medium,
  }) async {
    if (scheduledTime.isBefore(DateTime.now())) return;
    // FIXED: Added 'await' before Future<bool>
    if (!await _shouldShowNotification(payload, priority)) return;
    if (!(await areNotificationsGloballyEnabled())) return;
    
    final importance = priority == NotificationPriority.high 
        ? Importance.max
        : (priority == NotificationPriority.medium ? Importance.high : Importance.defaultImportance);
    
    final androidPriority = priority == NotificationPriority.high 
        ? Priority.high
        : (priority == NotificationPriority.medium ? Priority.high : Priority.defaultPriority);
    
    final channelId = priority == NotificationPriority.high 
        ? 'urgent_channel' 
        : 'scheduled_reminders';
    
    final androidDetails = AndroidNotificationDetails(
      channelId,
      priority == NotificationPriority.high ? 'Urgent Reminders' : 'Scheduled Reminders',
      importance: importance,
      priority: androidPriority,
      channelDescription: 'Scheduled task reminders',
    );
    
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    
    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);
    
    await _plugin.zonedSchedule(
      payload.hashCode,
      title,
      body,
      tzScheduledTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
    
    await _trackShownNotification(payload);
  }

  String _formatTimeUntil(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);
    
    if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours';
    } else {
      return '${difference.inDays} days';
    }
  }
  
  // ============ UTILITY METHODS ============
  
  Future<void> clearNotificationTracking() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (var key in keys) {
      if (key.startsWith('last_notification_')) {
        await prefs.remove(key);
      }
    }
  }
  
  Future<bool> areNotificationsGloballyEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? true;
  }
  
  Future<void> setNotificationsGloballyEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
    
    if (!enabled) {
      await cancelAllNotifications();
    }
  }
}
// lib/services/local/productivity_analyzer.dart
import '../../providers/app_state.dart';

class ProductivityAnalyzer {
  /// Analyze task postponement patterns
  static String? getPostponementInsight(Map<String, int> taskPostponements) {
    if (taskPostponements.isEmpty) return null;
    
    final mostPostponed = taskPostponements.entries.reduce((a, b) => a.value > b.value ? a : b);
    
    if (mostPostponed.value >= 3) {
      return 'You\'ve postponed "${mostPostponed.key}" ${mostPostponed.value} times. Consider breaking it into smaller tasks.';
    }
    return null;
  }
  
  /// Find most productive time range
  static String getMostProductiveTimeRange(List<DateTime> taskCompletionTimes) {
    if (taskCompletionTimes.isEmpty) return 'unknown';
    
    final hourCounts = List.filled(24, 0);
    for (var time in taskCompletionTimes) {
      hourCounts[time.hour]++;
    }
    
    int maxHour = 0;
    for (int i = 0; i < 24; i++) {
      if (hourCounts[i] > hourCounts[maxHour]) {
        maxHour = i;
      }
    }
    
    final startHour = maxHour;
    final endHour = maxHour + 2;
    return '$startHour:00 - $endHour:00';
  }
  
  /// Calculate completion rate
  static double calculateCompletionRate(int completed, int total) {
    if (total == 0) return 0.0;
    return completed / total;
  }
  
  /// Get most productive day of week
  static String getMostProductiveDay(List<DateTime> taskCompletionTimes) {
    if (taskCompletionTimes.isEmpty) return 'unknown';
    
    final dayCounts = List.filled(7, 0);
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    
    for (var time in taskCompletionTimes) {
      int weekday = time.weekday - 1;
      dayCounts[weekday]++;
    }
    
    int maxDay = 0;
    for (int i = 0; i < 7; i++) {
      if (dayCounts[i] > dayCounts[maxDay]) {
        maxDay = i;
      }
    }
    
    return days[maxDay];
  }
  
  /// Generate user productivity summary
  static String generateSummary(AppState appState) {
    final totalItems = appState.workspaceItems.length;
    final pendingTasks = appState.pendingTasksCount;
    final recentActivities = appState.recentActivities.length;
    
    return '''
📊 Productivity Summary:
• Total items: $totalItems
• Pending tasks: $pendingTasks
• Recent activities: $recentActivities
    ''';
  }
}
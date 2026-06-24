// lib/utils/date_formatters.dart
import 'package:intl/intl.dart';

class DateFormatters {
  // ============ BASIC FORMATTERS ============
  
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
  
  static String formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }
  
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }
  
  static String formatDateTime12Hour(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy hh:mm a').format(dateTime);
  }
  
  // ============ RELATIVE FORMATTERS ============
  
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 365) {
      return formatDate(dateTime);
    } else if (difference.inDays > 30) {
      return DateFormat('MMM d').format(dateTime);
    } else if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()} week${(difference.inDays / 7).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
  
  // ============ DAY FORMATTERS ============
  
  static String getDayName(DateTime date) {
    return DateFormat('EEEE').format(date);
  }
  
  static String getShortDayName(DateTime date) {
    return DateFormat('EEE').format(date);
  }
  
  static String getMonthName(DateTime date) {
    return DateFormat('MMMM').format(date);
  }
  
  static String getShortMonthName(DateTime date) {
    return DateFormat('MMM').format(date);
  }
  
  static String getYear(DateTime date) {
    return DateFormat('yyyy').format(date);
  }
  
  // ============ WEEK FORMATTERS ============
  
  static String getWeekRange(DateTime date) {
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return '${formatDate(startOfWeek)} - ${formatDate(endOfWeek)}';
  }
  
  static int getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceStart = date.difference(firstDayOfYear).inDays;
    return ((daysSinceStart + firstDayOfYear.weekday) / 7).ceil();
  }
  
  // ============ TIME RANGE FORMATTERS ============
  
  static String formatTimeRange(DateTime start, DateTime end) {
    return '${formatTime(start)} - ${formatTime(end)}';
  }
  
  static String formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }
  
  // ============ SMART FORMATTERS ============
  
  static String smartDateFormat(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else if (dateOnly.isAfter(today.subtract(const Duration(days: 7)))) {
      return getShortDayName(date);
    } else {
      return formatDate(date);
    }
  }
  
  static String smartDateTimeFormat(DateTime dateTime) {
    final datePart = smartDateFormat(dateTime);
    final timePart = formatTime(dateTime);
    return '$datePart at $timePart';
  }
  
  // ============ ISO STRING HELPERS ============
  
  static DateTime? parseIsoString(String? isoString) {
    if (isoString == null || isoString.isEmpty) return null;
    try {
      return DateTime.parse(isoString);
    } catch (e) {
      return null;
    }
  }
  
  static String toIsoString(DateTime dateTime) {
    return dateTime.toIso8601String();
  }
  
  // ============ DATE RANGE HELPERS ============
  
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
  
  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }
  
  static bool isTomorrow(DateTime date) {
    return isSameDay(date, DateTime.now().add(const Duration(days: 1)));
  }
  
  static bool isYesterday(DateTime date) {
    return isSameDay(date, DateTime.now().subtract(const Duration(days: 1)));
  }
  
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
  
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }
  
  // ============ LIST GENERATORS ============
  
  static List<DateTime> getDatesInRange(DateTime start, DateTime end) {
    final dates = <DateTime>[];
    var current = startOfDay(start);
    final endDate = startOfDay(end);
    
    while (current.isBefore(endDate) || current == endDate) {
      dates.add(current);
      current = current.add(const Duration(days: 1));
    }
    
    return dates;
  }
  
  static List<String> getTimeSlots({int intervalMinutes = 30}) {
    final slots = <String>[];
    for (int hour = 0; hour < 24; hour++) {
      for (int minute = 0; minute < 60; minute += intervalMinutes) {
        slots.add('${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');
      }
    }
    return slots;
  }
}
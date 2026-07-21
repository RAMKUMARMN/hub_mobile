// lib/screens/calendar/calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../providers/workspace_provider.dart';
import '../../models/workspace_items/task.dart';
import '../../themes/app_colors.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<CalendarEvent>> _events = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    
    final appState = Provider.of<AppState>(context, listen: false);
    final workspaceProvider = Provider.of<WorkspaceProvider>(context, listen: false);
    final workspaceId = workspaceProvider.currentWorkspace?.id;
    
    _events = {};
    
    // ✅ FIXED: Use getItemsForWorkspace instead of workspaceItems
    final items = workspaceId != null 
        ? appState.getItemsForWorkspace(workspaceId)
        : appState.getAllWorkspaceItems();
    
    for (var item in items) {
      // Check if it's a task with due date
      if (item is Task && item.dueDate != null) {
        _addEvent(item.dueDate!, CalendarEvent(
          title: item.title,
          type: 'task',
          isCompleted: item.isCompleted,
        ));
      }
      // Check for deadline in subtitle
      else if (item.subtitle.toLowerCase().contains('due') || 
               item.subtitle.toLowerCase().contains('deadline')) {
        final eventDate = _extractDateFromText(item.subtitle);
        if (eventDate != null) {
          _addEvent(eventDate, CalendarEvent(
            title: item.title,
            type: 'deadline',
          ));
        }
      }
      // Check for reminder
      else if (item.subtitle.toLowerCase().contains('reminder')) {
        final eventDate = _extractDateFromText(item.subtitle);
        if (eventDate != null) {
          _addEvent(eventDate, CalendarEvent(
            title: item.title,
            type: 'reminder',
          ));
        }
      }
    }
    
    setState(() => _isLoading = false);
  }

  DateTime? _extractDateFromText(String text) {
    // Try to extract date from text (simplified)
    // Format: "dd/mm/yyyy" or "dd-mm-yyyy"
    final regExp = RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{4})');
    final match = regExp.firstMatch(text);
    if (match != null) {
      try {
        final day = int.parse(match.group(1)!);
        final month = int.parse(match.group(2)!);
        final year = int.parse(match.group(3)!);
        return DateTime(year, month, day);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  void _addEvent(DateTime date, CalendarEvent event) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    if (!_events.containsKey(normalizedDate)) {
      _events[normalizedDate] = [];
    }
    // Check for duplicate
    final exists = _events[normalizedDate]!.any((e) => e.title == event.title);
    if (!exists) {
      _events[normalizedDate]!.add(event);
    }
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
  }

  void _showEventDetails(CalendarEvent event, DateTime date) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              event.type == 'deadline' ? Icons.warning_amber_rounded : 
              (event.type == 'reminder' ? Icons.notifications : Icons.task_rounded),
              color: event.type == 'deadline' ? Colors.red : 
                     (event.type == 'reminder' ? Colors.orange : Colors.green),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(event.title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: ${_formatDate(date)}'),
            const SizedBox(height: 8),
            Text('Type: ${event.type.toUpperCase()}'),
            if (event.isCompleted == true) ...[
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  SizedBox(width: 8),
                  Text('Completed', style: TextStyle(color: Colors.green)),
                ],
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (event.type == 'task' && event.isCompleted != true)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Task marked as completed!')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Mark Complete'),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showAddEventDialog() {
    final titleController = TextEditingController();
    String selectedType = 'task';
    DateTime selectedDate = _selectedDay ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add Event'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    hintText: 'Event title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Event Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'task', child: Text('Task')),
                    DropdownMenuItem(value: 'deadline', child: Text('Deadline')),
                    DropdownMenuItem(value: 'reminder', child: Text('Reminder')),
                  ],
                  onChanged: (value) => setDialogState(() => selectedType = value!),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text('Date: ${_formatDate(selectedDate)}'),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setDialogState(() => selectedDate = picked);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (titleController.text.isNotEmpty) {
                    _addEvent(selectedDate, CalendarEvent(
                      title: titleController.text,
                      type: selectedType,
                    ));
                    setState(() {});
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Event added!')),
                    );
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final cardColor = Theme.of(context).cardColor;
    
    return PopScope(canPop: !Navigator.canPop(context),onPopInvokedWithResult: (didPop, result) {
      if (didPop) return; // If already popped by system, do nothing
      Navigator.pop(context); // Pop internally (back one screen)
    },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Calendar'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showAddEventDialog,
              tooltip: 'Add Event',
            ),
            IconButton(
              icon: const Icon(Icons.today),
              onPressed: () {
                setState(() {
                  _focusedDay = DateTime.now();
                  _selectedDay = DateTime.now();
                });
              },
              tooltip: 'Today',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadEvents,
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  TableCalendar(
                    firstDay: DateTime.utc(2024, 1, 1),
                    lastDay: DateTime.utc(2026, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: CalendarFormat.month,
                    eventLoader: _getEventsForDay,
                    selectedDayPredicate: (day) {
                      return _selectedDay != null && 
                             day.year == _selectedDay!.year &&
                             day.month == _selectedDay!.month &&
                             day.day == _selectedDay!.day;
                    },
                    onDaySelected: _onDaySelected,
                    onPageChanged: (focusedDay) => setState(() => _focusedDay = focusedDay),
                    calendarStyle: CalendarStyle(
                      todayDecoration: const BoxDecoration(
                        color: AppColors.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: const BoxDecoration(
                        color: AppColors.aiCyan,
                        shape: BoxShape.circle,
                      ),
                      weekendTextStyle: TextStyle(color: Colors.red.shade300),
                      defaultTextStyle: TextStyle(color: textColor),
                      markerDecoration: const BoxDecoration(
                        color: AppColors.aiCyan,
                        shape: BoxShape.circle,
                      ),
                    ),
                    headerStyle: HeaderStyle(
                      titleCentered: true,
                      formatButtonVisible: false,
                      titleTextStyle: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                      leftChevronIcon: Icon(Icons.chevron_left, color: textColor),
                      rightChevronIcon: Icon(Icons.chevron_right, color: textColor),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Events for selected day
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedDay != null ? 'Events for ${_formatDate(_selectedDay!)}' : 'Select a date',
                            style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: _buildEventsList(_getEventsForDay(_selectedDay ?? DateTime.now())),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildEventsList(List<CalendarEvent> events) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_busy, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('No events for this day', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _showAddEventDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Event'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: event.type == 'deadline' 
                  ? Colors.red.withValues(alpha: 0.2) 
                  : (event.type == 'reminder' 
                      ? Colors.orange.withValues(alpha: 0.2)
                      : Colors.green.withValues(alpha: 0.2)),
              child: Icon(
                event.type == 'deadline' ? Icons.warning_amber_rounded : 
                (event.type == 'reminder' ? Icons.notifications : Icons.task_rounded),
                color: event.type == 'deadline' ? Colors.red : 
                       (event.type == 'reminder' ? Colors.orange : Colors.green),
                size: 20,
              ),
            ),
            title: Text(event.title),
            subtitle: Text(event.type.toUpperCase()),
            trailing: event.isCompleted == true
                ? const Icon(Icons.check_circle, color: Colors.green)
                : null,
            onTap: () => _showEventDetails(event, _selectedDay ?? DateTime.now()),
          ),
        );
      },
    );
  }
}

// Calendar Event model
class CalendarEvent {
  final String title;
  final String type; // task, deadline, or reminder
  final bool? isCompleted;

  CalendarEvent({
    required this.title,
    required this.type,
    this.isCompleted,
  });
}
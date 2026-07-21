// lib/screens/workspace/workspace_content.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_state.dart';
import '../../../providers/workspace_provider.dart';
import '../../../models/workspace_items/task.dart';
import '../../../models/workspace_items/note.dart';
import '../../../models/workspace_items/document.dart';
import '../../../models/workspace_items/workspace_item.dart';
import '../../../services/local/notification_service.dart';
import '../../../themes/app_colors.dart';
import '../workspace_items/task_card.dart';
import '../workspace_items/note_card.dart';
import '../workspace_items/document_card.dart';

class WorkspaceContent extends StatelessWidget {
  const WorkspaceContent({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final workspaceProvider = Provider.of<WorkspaceProvider>(context);
    final currentWorkspace = workspaceProvider.currentWorkspace;
    final filter = workspaceProvider.currentFilter.toLowerCase();
    
    if (currentWorkspace == null) {
      return const Center(child: Text('Select a workspace'));
    }
    
    final allItems = appState.getItemsForWorkspace(currentWorkspace.id);
    
    final filteredItems = allItems.where((item) {
      if (filter == 'all') return true;
      if (filter == 'tasks') return item is Task;
      if (filter == 'notes') return item is Note;
      if (filter == 'files') return item is Document;
      return true;
    }).toList();
    
    if (filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_getEmptyIcon(filter), size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _getEmptyMessage(filter),
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            if (allItems.isNotEmpty && filter != 'all')
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: TextButton(
                  onPressed: () {
                    workspaceProvider.setFilter('all');
                  },
                  child: const Text('Show all items'),
                ),
              ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        
        if (item is Task) {
          return TaskCard(
            task: item,
            onToggleComplete: () => _toggleTaskComplete(context, item),
            onEdit: () => _editTask(context, item),
            onDelete: () => _deleteItem(context, item, appState),
          );
        } else if (item is Note) {
          return NoteCard(
            note: item,
            onTap: () => _openNote(context, item),
            onDelete: () => _deleteItem(context, item, appState),
          );
        } else if (item is Document) {
          return DocumentCard(
            document: item,
            onDelete: () => _deleteItem(context, item, appState),
          );
        }
        
        return const SizedBox.shrink();
      },
    );
  }
  
  void _toggleTaskComplete(BuildContext context, Task task) {
    final appState = Provider.of<AppState>(context, listen: false);
    final workspaceProvider = Provider.of<WorkspaceProvider>(context, listen: false);
    final workspaceId = workspaceProvider.currentWorkspace?.id ?? task.workspaceId;
    
    final updatedTask = task.copyWith(
      status: task.status == TaskStatus.completed ? TaskStatus.pending : TaskStatus.completed,
      updatedAt: DateTime.now(),
    );
    
    final items = appState.getItemsForWorkspace(workspaceId);
    final index = items.indexWhere((item) => item.id == task.id);
    if (index != -1) {
      appState.updateWorkspaceItem(index, updatedTask, workspaceId: workspaceId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(updatedTask.status == TaskStatus.completed 
              ? 'Task completed! ✅' 
              : 'Task marked as pending'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }
  
  void _deleteItem(BuildContext context, WorkspaceItem item, AppState appState) {
    final workspaceProvider = Provider.of<WorkspaceProvider>(context, listen: false);
    final workspaceId = workspaceProvider.currentWorkspace?.id ?? item.workspaceId;
    
    final items = appState.getItemsForWorkspace(workspaceId);
    final index = items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      final deletedItem = item;
      appState.removeWorkspaceItem(index, workspaceId: workspaceId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${deletedItem.title} deleted'),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              appState.addWorkspaceItem(deletedItem, workspaceId: workspaceId);
            },
          ),
        ),
      );
    }
  }
  
  Future<DateTime?> _showDateTimePicker(BuildContext context, {DateTime? initialDateTime}) async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: initialDateTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return null;
    if (!context.mounted) return null;
    
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDateTime ?? DateTime.now()),
    );
    if (time == null) return null;
    
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }
  
  void _editTask(BuildContext context, Task task) {
    final TextEditingController titleController = TextEditingController(text: task.title);
    final TextEditingController descriptionController = TextEditingController(text: task.description);
    String selectedPriority = task.priority.name;
    DateTime? selectedDueDate = task.dueDate;
    bool enableReminder = task.reminderEnabled;
    DateTime? selectedReminderTime = task.reminderAt;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Task'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(hintText: 'Task title'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(hintText: 'Description'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedPriority,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'low', child: Text('🔵 Low')),
                          DropdownMenuItem(value: 'medium', child: Text('🟡 Medium')),
                          DropdownMenuItem(value: 'high', child: Text('🔴 High')),
                        ],
                        onChanged: (value) => setDialogState(() => selectedPriority = value!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: Text(
                      selectedDueDate != null 
                          ? 'Due: ${_formatDate(selectedDueDate!)}' 
                          : 'Set due date (optional)',
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDueDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDueDate = picked);
                      }
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Set Reminder'),
                    subtitle: const Text('Get notified before this task'),
                    value: enableReminder,
                    onChanged: (val) {
                      setDialogState(() {
                        enableReminder = val;
                        if (!enableReminder) {
                          selectedReminderTime = null;
                        }
                      });
                    },
                  ),
                  if (enableReminder)
                    ListTile(
                      leading: const Icon(Icons.access_time, color: AppColors.aiCyan),
                      title: Text(
                        selectedReminderTime != null 
                            ? 'Reminder: ${_formatDateTime(selectedReminderTime!)}' 
                            : 'Select reminder time',
                        style: TextStyle(
                          color: selectedReminderTime != null ? AppColors.aiCyan : null,
                        ),
                      ),
                      onTap: () async {
                        final picked = await _showDateTimePicker(context, initialDateTime: selectedReminderTime);
                        if (picked != null) {
                          setDialogState(() => selectedReminderTime = picked);
                        }
                      },
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final appState = Provider.of<AppState>(context, listen: false);
                  final workspaceProvider = Provider.of<WorkspaceProvider>(context, listen: false);
                  final workspaceId = workspaceProvider.currentWorkspace?.id ?? task.workspaceId;
                  
                  if (enableReminder && selectedReminderTime == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select a reminder time')),
                    );
                    return;
                  }
                  
                  TaskPriority priorityEnum;
                  switch (selectedPriority) {
                    case 'high': priorityEnum = TaskPriority.high; break;
                    case 'medium': priorityEnum = TaskPriority.medium; break;
                    default: priorityEnum = TaskPriority.low;
                  }
                  
                  final updatedTask = task.copyWith(
                    title: titleController.text.trim(),
                    subtitle: descriptionController.text.isEmpty ? "Task" : descriptionController.text,
                    description: descriptionController.text,
                    priority: priorityEnum,
                    dueDate: selectedDueDate,
                    reminderAt: enableReminder ? selectedReminderTime : null,
                    reminderEnabled: enableReminder,
                    reminderCompleted: enableReminder ? false : task.reminderCompleted,
                    updatedAt: DateTime.now(),
                  );
                  
                  final items = appState.getItemsForWorkspace(workspaceId);
                  final index = items.indexWhere((i) => i.id == task.id);
                  if (index != -1) {
                    appState.updateWorkspaceItem(index, updatedTask, workspaceId: workspaceId);
                    
                    if (enableReminder && selectedReminderTime != null) {
                      if (task.reminderAt != null) {
                        await NotificationService().cancelNotification(task.id);
                      }
                      await NotificationService().scheduleCustomReminder(
                        title: 'Task Reminder',
                        body: updatedTask.title,
                        scheduledTime: selectedReminderTime!,
                        reminderId: updatedTask.id,
                      );
                    } else if (!enableReminder && task.reminderEnabled) {
                      await NotificationService().cancelNotification(task.id);
                    }
                  }
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Task updated!')),
                    );
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  void _openNote(BuildContext context, Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(note.title),
        content: SingleChildScrollView(child: Text(note.content)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
  
  IconData _getEmptyIcon(String filter) {
    switch (filter) {
      case 'tasks': return Icons.task_alt;
      case 'notes': return Icons.note_add;
      case 'files': return Icons.upload_file;
      default: return Icons.inbox;
    }
  }
  
  String _getEmptyMessage(String filter) {
    switch (filter) {
      case 'tasks': return 'No tasks yet.\nTap + to add one';
      case 'notes': return 'No notes yet.\nTap + to create a note';
      case 'files': return 'No files uploaded.\nTap + to upload';
      default: return 'No items yet.\nTap + to add something';
    }
  }
}
// lib/services/local/task_service.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../providers/workspace_provider.dart';
import '../../models/workspace_items/task.dart';
import '../api/task_api_service.dart';
import '../../utils/helpers.dart';
import '../../utils/validators.dart';
import 'notification_service.dart';

class TaskService {
  final BuildContext context;
  final TaskApiService _taskApi = TaskApiService();

  TaskService({required this.context});

  /// Get all tasks from current workspace
  List<Task> getTasks() {
    final appState = Provider.of<AppState>(context, listen: false);
    final workspaceProvider = Provider.of<WorkspaceProvider>(context, listen: false);
    final workspaceId = workspaceProvider.currentWorkspace?.id;
    
    if (workspaceId == null) return [];
    
    return appState.getItemsForWorkspace(workspaceId)
        .whereType<Task>()
        .where((task) => task.workspaceId == workspaceId)
        .toList();
  }

  /// Get pending tasks count
  int getPendingTasksCount() {
    final tasks = getTasks();
    return tasks.where((task) => task.status != TaskStatus.completed).length;
  }

  /// Get overdue tasks count
  int getOverdueTasksCount() {
    final tasks = getTasks();
    return tasks.where((task) => task.isOverdue).length;
  }

  /// Create a new task
  Future<bool> createTask({
    required String title,
    String description = '',
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
    DateTime? reminderAt,
  }) async {
    if (!Validators.isNotEmpty(title)) {
      Helpers.showError(context, 'Task title is required');
      return false;
    }
    
    final appState = Provider.of<AppState>(context, listen: false);
    final workspaceProvider = Provider.of<WorkspaceProvider>(context, listen: false);
    final workspaceId = workspaceProvider.currentWorkspace?.id;
    
    if (workspaceId == null) {
      Helpers.showError(context, 'No workspace selected');
      return false;
    }
    
    try {
      // ✅ FIXED: Using _taskApi instead of TaskApi
      final response = await _taskApi.createTask(
        title: title,
        description: description,
        priority: priority,
        dueDate: dueDate,
        reminderAt: reminderAt,
        workspaceId: workspaceId,
      );
      
      if (response['success'] == true) {
        final backendData = response['data'];
        
        final newTask = Task(
          id: backendData?['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          workspaceId: workspaceId,
          title: backendData?['title'] ?? title,
          subtitle: 'Priority: ${priority.displayName}',
          icon: _getPriorityIcon(priority),
          description: backendData?['description'] ?? description,
          priority: priority,
          status: TaskStatus.pending,
          dueDate: dueDate,
          reminderAt: reminderAt,
          reminderEnabled: reminderAt != null,
          reminderCompleted: false,
          userId: backendData?['user_id']?.toString(),
          completedAt: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        appState.addWorkspaceItem(newTask, workspaceId: workspaceId);
        
        if (dueDate != null) {
          await NotificationService().scheduleDeadlineNotification(
            taskName: title,
            deadline: dueDate,
            taskId: newTask.id,
          );
        }
        
        if (reminderAt != null) {
          await NotificationService().scheduleCustomReminder(
            title: 'Task Reminder',
            body: title,
            scheduledTime: reminderAt,
            reminderId: newTask.id,
          );
        }
        
        appState.addActivity('✅ Task created: $title');
        if (context.mounted) {
          Helpers.showSuccess(context, 'Task created!');
        }
        return true;
      } else {
        if (context.mounted) {
          Helpers.showError(context, response['error'] ?? 'Failed to create task');
        }
        return false;
      }
    } catch (e) {
      debugPrint('Create task error: $e');
      if (context.mounted) {
        Helpers.showError(context, 'Failed to create task: ${e.toString()}');
      }
      return false;
    }
  }

  /// Complete a task
  Future<bool> completeTask(String taskId) async {
    final appState = Provider.of<AppState>(context, listen: false);
    
    try {
      // ✅ FIXED: Using _taskApi instead of TaskApi
      final response = await _taskApi.updateTask(
        taskId: taskId,
        status: TaskStatus.completed,
      );
      
      if (response['success'] == true) {
        // Find which workspace the task belongs to
        String? workspaceId;
        Task? oldTask;
        
        for (var item in appState.getAllWorkspaceItems()) {
          if (item is Task && item.id == taskId) {
            oldTask = item;
            workspaceId = appState.findWorkspaceIdForItem(taskId);
            break;
          }
        }
        
        if (workspaceId != null && oldTask != null) {
          final items = appState.getItemsForWorkspace(workspaceId);
          final index = items.indexWhere((item) => item.id == taskId);
          if (index != -1) {
            final updatedTask = oldTask.copyWith(
              status: TaskStatus.completed,
              completedAt: DateTime.now(),
            );
            appState.updateWorkspaceItem(index, updatedTask, workspaceId: workspaceId);
            appState.addActivity('✅ Task completed: ${oldTask.title}');
          }
        }
        if (context.mounted) {
          Helpers.showSuccess(context, 'Task completed!');
        }
        return true;
      } else {
        if (context.mounted) {
          Helpers.showError(context, response['error'] ?? 'Failed to complete task');
        }
        return false;
      }
    } catch (e) {
      if (context.mounted) {
        Helpers.showError(context, 'Failed to complete task: ${e.toString()}');
      }
      return false;
    }
  }

  /// Update task status
  Future<bool> updateTaskStatus(String taskId, TaskStatus status) async {
    try {
      // ✅ FIXED: Using _taskApi instead of TaskApi
      final response = await _taskApi.updateTask(
        taskId: taskId,
        status: status,
      );
      
      if (response['success'] == true) {
        final appState = Provider.of<AppState>(context, listen: false);
        
        // Find which workspace the task belongs to
        String? workspaceId;
        Task? oldTask;
        
        for (var item in appState.getAllWorkspaceItems()) {
          if (item is Task && item.id == taskId) {
            oldTask = item;
            workspaceId = appState.findWorkspaceIdForItem(taskId);
            break;
          }
        }
        
        if (workspaceId != null && oldTask != null) {
          final items = appState.getItemsForWorkspace(workspaceId);
          final index = items.indexWhere((item) => item.id == taskId);
          if (index != -1) {
            final updatedTask = oldTask.copyWith(
              status: status,
              completedAt: status == TaskStatus.completed ? DateTime.now() : null,
            );
            appState.updateWorkspaceItem(index, updatedTask, workspaceId: workspaceId);
          }
        }
        if (context.mounted) {
          Helpers.showSuccess(context, 'Task updated');
        }
        return true;
      }
      if (context.mounted) {
        Helpers.showError(context, response['error'] ?? 'Failed to update task');
      }
      return false;
    } catch (e) {
      if (context.mounted) {
        Helpers.showError(context, 'Failed to update task: ${e.toString()}');
      }
      return false;
    }
  }

  /// Delete a task
  Future<bool> deleteTask(String taskId) async {
    try {
      // ✅ FIXED: Using _taskApi instead of TaskApi
      final response = await _taskApi.deleteTask(taskId);
      if (response['success'] == true) {
        if (context.mounted) {
          Helpers.showSuccess(context, 'Task deleted');
        }
        return true;
      }
      if (context.mounted) {
        Helpers.showError(context, response['error'] ?? 'Failed to delete task');
      }
      return false;
    } catch (e) {
      if (context.mounted) {
        Helpers.showError(context, 'Failed to delete task: ${e.toString()}');
      }
      return false;
    }
  }

  /// Show create task dialog
  void showCreateTaskDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    TaskPriority selectedPriority = TaskPriority.medium;
    DateTime? selectedDueDate;
    bool enableReminder = false;
    DateTime? selectedReminderTime;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Create Task'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      hintText: 'Task title',
                      border: OutlineInputBorder(),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      hintText: 'Description (optional)',
                      border: OutlineInputBorder(),
                    ),
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
                      child: DropdownButton<TaskPriority>(
                        value: selectedPriority,
                        isExpanded: true,
                        hint: const Text('Select Priority'),
                        items: const [
                          DropdownMenuItem(
                            value: TaskPriority.low,
                            child: Text('🔵 Low Priority'),
                          ),
                          DropdownMenuItem(
                            value: TaskPriority.medium,
                            child: Text('🟡 Medium Priority'),
                          ),
                          DropdownMenuItem(
                            value: TaskPriority.high,
                            child: Text('🔴 High Priority'),
                          ),
                          DropdownMenuItem(
                            value: TaskPriority.critical,
                            child: Text('🟣 Critical Priority'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => selectedPriority = value);
                          }
                        },
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
                        initialDate: DateTime.now(),
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
                      leading: const Icon(Icons.access_time),
                      title: Text(
                        selectedReminderTime != null 
                            ? 'Reminder: ${_formatDateTime(selectedReminderTime!)}' 
                            : 'Select reminder time',
                      ),
                      onTap: () async {
                        final picked = await _showDateTimePicker(context);
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
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.trim().isEmpty) {
                    Helpers.showError(context, 'Please enter a task title');
                    return;
                  }
                  
                  if (enableReminder && selectedReminderTime == null) {
                    Helpers.showError(context, 'Please select a reminder time');
                    return;
                  }
                  
                  Navigator.pop(dialogContext);
                  await createTask(
                    title: titleController.text.trim(),
                    description: descriptionController.text,
                    priority: selectedPriority,
                    dueDate: selectedDueDate,
                    reminderAt: enableReminder ? selectedReminderTime : null,
                  );
                },
                child: const Text('Create'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Helper to show DateTime picker
  Future<DateTime?> _showDateTimePicker(BuildContext context) async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date == null) return null;
    
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    
    if (time == null) return null;
    
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  /// Navigate to tasks (workspace screen)
  void viewTasks() {
    Navigator.pushNamed(context, '/workspace');
  }

  // ============ HELPER METHODS ============

  IconData _getPriorityIcon(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.critical:
        return Icons.warning_rounded;
      case TaskPriority.high:
        return Icons.flag;
      case TaskPriority.medium:
        return Icons.flag_outlined;
      case TaskPriority.low:
        return Icons.flag_outlined;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
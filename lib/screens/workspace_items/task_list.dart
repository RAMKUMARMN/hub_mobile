// lib/screens/workspace_items/task_list.dart
import 'package:flutter/material.dart';
import '../../../models/workspace_items/task.dart';
import 'task_card.dart';

class TaskList extends StatelessWidget {
  final List<Task> tasks;
  final Function(Task) onTaskEdit;
  final Function(Task) onTaskToggleComplete;
  final Function(Task) onTaskDelete;

  const TaskList({
    super.key,
    required this.tasks,
    required this.onTaskEdit,
    required this.onTaskToggleComplete,
    required this.onTaskDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No tasks yet',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to create a task',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return TaskCard(
          task: task,
          onToggleComplete: () => onTaskToggleComplete(task),
          onEdit: () => onTaskEdit(task),
          onDelete: () => onTaskDelete(task),
        );
      },
    );
  }
}
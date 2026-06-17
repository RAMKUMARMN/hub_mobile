// lib/screens/workspace_items/task_card.dart

import 'package:flutter/material.dart';
import '../../../models/workspace_items/task.dart';
import '../../../themes/app_colors.dart';
import '../../../widgets/glass/glass_card.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onToggleComplete;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TaskCard({
    super.key,
    required this.task,
    this.onToggleComplete,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final secondaryText = Theme.of(context).textTheme.bodyMedium?.color;
    final isCompleted = task.status == TaskStatus.completed;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Checkbox for complete/incomplete
              GestureDetector(
                onTap: onToggleComplete,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCompleted ? Colors.green : AppColors.aiCyan,
                      width: 2,
                    ),
                    color: isCompleted ? Colors.green : Colors.transparent,
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: onEdit,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          color: isCompleted ? secondaryText : textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (task.description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            task.description,
                            style: TextStyle(
                              color: secondaryText,
                              fontSize: 13,
                              decoration: isCompleted ? TextDecoration.lineThrough : null,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Priority badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: task.priority.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  task.priority.displayName,
                  style: TextStyle(
                    fontSize: 11,
                    color: task.priority.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Menu button for edit/delete
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20),
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit?.call();
                  } else if (value == 'delete') {
                    _confirmDelete(context);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Due date section
          if (task.dueDate != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 12, color: secondaryText),
                const SizedBox(width: 4),
                Text(
                  _formatDate(task.dueDate!),
                  style: TextStyle(color: secondaryText, fontSize: 12),
                ),
                if (task.isOverdue && !isCompleted)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Overdue',
                        style: TextStyle(color: Colors.red, fontSize: 10),
                      ),
                    ),
                  ),
              ],
            ),
          ],
          // Reminder section (NEW)
          // lib/screens/workspace_items/task_card.dart - Update the reminder section

// Replace the reminder section with this:
if (task.hasReminder && !task.isCompleted) ...[
  const SizedBox(height: 4),
  Row(
    crossAxisAlignment: CrossAxisAlignment.start,  // Changed to start
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Icon(Icons.notifications_outlined, size: 12, color: AppColors.aiCyan),
      ),
      const SizedBox(width: 4),
      Expanded(  // ADDED Expanded to prevent overflow
        child: Text(
          'Reminder: ${_formatDateTime(task.reminderAt!)}',
          style: TextStyle(color: AppColors.aiCyan, fontSize: 11),
          maxLines: 2,  // Allow wrapping
          overflow: TextOverflow.ellipsis,
        ),
      ),
      if (task.isReminderOverdue)
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Overdue',
              style: TextStyle(color: Colors.orange, fontSize: 10),
            ),
          ),
        ),
    ],
  ),
],
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              onDelete?.call();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
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
}
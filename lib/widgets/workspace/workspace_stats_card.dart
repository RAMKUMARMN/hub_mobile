// lib/widgets/workspace/workspace_stats_card.dart
import 'package:flutter/material.dart';
import '../../themes/app_colors.dart';
import '../glass/glass_card.dart';

class WorkspaceStatsCard extends StatelessWidget {
  final int tasksCount;
  final int remindersCount;
  final int notesCount;
  final int filesCount;
  final Function(String) onStatTap;

  const WorkspaceStatsCard({
    super.key,
    required this.tasksCount,
    required this.remindersCount,
    required this.notesCount,
    required this.filesCount,
    required this.onStatTap,
  });

  @override
  Widget build(BuildContext context) {
    final secondaryText = Theme.of(context).textTheme.bodyMedium?.color;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildStatItem(
            context,  // ← PASS context
            title: 'Tasks',
            count: tasksCount,
            icon: Icons.check_circle_outline_rounded,
            color: Colors.green,
            onTap: () => onStatTap('Tasks'),
          ),
          Container(
            width: 1,
            height: 40,
            color: secondaryText?.withValues(alpha: 0.2),
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
          _buildStatItem(
            context,  // ← PASS context
            title: 'Reminders',
            count: remindersCount,
            icon: Icons.notifications_active_rounded,
            color: Colors.orange,
            onTap: () => onStatTap('Reminders'),
          ),
          Container(
            width: 1,
            height: 40,
            color: secondaryText?.withValues(alpha: 0.2),
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
          _buildStatItem(
            context,  // ← PASS context
            title: 'Notes',
            count: notesCount,
            icon: Icons.notes_rounded,
            color: Colors.purple,
            onTap: () => onStatTap('Notes'),
          ),
          Container(
            width: 1,
            height: 40,
            color: secondaryText?.withValues(alpha: 0.2),
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
          _buildStatItem(
            context,  // ← PASS context
            title: 'Files',
            count: filesCount,
            icon: Icons.folder_rounded,
            color: Colors.blue,
            onTap: () => onStatTap('Files'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,  // ← ADD context parameter
    {
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              count.toString(),
              style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(title, style: const TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class WorkspaceProgressStatsCard extends StatelessWidget {
  final int totalItems;
  final int completedItems;
  final int pendingItems;
  final double completionRate;

  const WorkspaceProgressStatsCard({
    super.key,
    required this.totalItems,
    required this.completedItems,
    required this.pendingItems,
    required this.completionRate,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final secondaryText = Theme.of(context).textTheme.bodyMedium?.color;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress Overview',
                style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              Text(
                '${(completionRate * 100).toStringAsFixed(0)}%',
                style: const TextStyle(color: AppColors.aiCyan, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: completionRate,
              backgroundColor: secondaryText?.withValues(alpha: 0.2),
              color: AppColors.aiCyan,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildProgressStat(context, 'Total', totalItems, Colors.grey),  // ← PASS context
              _buildProgressStat(context, 'Completed', completedItems, Colors.green),  // ← PASS context
              _buildProgressStat(context, 'Pending', pendingItems, Colors.orange),  // ← PASS context
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStat(BuildContext context, String label, int value, Color color) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(color: textColor?.withValues(alpha: 0.7), fontSize: 10),
        ),
      ],
    );
  }
}
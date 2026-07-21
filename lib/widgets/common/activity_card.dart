// lib/widgets/activity_card.dart
import 'package:flutter/material.dart';
import '../../themes/app_colors.dart';
import '../glass/glass_card.dart';
import '../../utils/helpers.dart';

class ActivityCard extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  final DateTime? timestamp;
  final IconData? customIcon;

  const ActivityCard({
    super.key,
    required this.title,
    this.onTap,
    this.timestamp,
    this.customIcon,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final secondaryText = Theme.of(context).textTheme.bodyMedium?.color;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.aiCyan.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              customIcon ?? _getActivityIcon(title),
              color: AppColors.aiCyan,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: textColor, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (timestamp != null)
                  Text(
                    Helpers.getTimeAgo(timestamp!),
                    style: TextStyle(color: secondaryText, fontSize: 10),
                  ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: textColor?.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }

  IconData _getActivityIcon(String activity) {
    final lowerActivity = activity.toLowerCase();
    if (lowerActivity.contains('upload')) return Icons.upload_file_rounded;
    if (lowerActivity.contains('note')) return Icons.notes_rounded;
    if (lowerActivity.contains('task')) return Icons.check_circle_outline_rounded;
    if (lowerActivity.contains('ai') || lowerActivity.contains('summary')) {
      return Icons.auto_awesome_rounded;
    }
    if (lowerActivity.contains('reminder')) return Icons.notifications_active_rounded;
    if (lowerActivity.contains('workspace')) return Icons.folder_rounded;
    return Icons.access_time_rounded;
  }
}
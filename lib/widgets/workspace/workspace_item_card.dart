// lib/widgets/workspace/workspace_item_card.dart
import 'package:flutter/material.dart';
import '../../models/workspace_items/workspace_item.dart';
import '../../themes/app_colors.dart';
import '../glass/glass_card.dart';  // ← FIXED: correct path

class WorkspaceItemCard extends StatelessWidget {
  final WorkspaceItem item;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final bool isSelected;
  final bool isSelectionMode;

  const WorkspaceItemCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onDelete,
    this.isSelected = false,
    this.isSelectionMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final secondaryText = Theme.of(context).textTheme.bodyMedium?.color;

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.zero,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.aiCyan.withValues(alpha: 0.2), AppColors.primaryBlue.withValues(alpha: 0.2)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(item.icon, color: AppColors.aiCyan, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  item.formattedSubtitle,
                  style: TextStyle(color: secondaryText, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isSelectionMode)
            Checkbox(
              value: isSelected,
              onChanged: (_) => onTap(),
              activeColor: AppColors.aiCyan,
              shape: const CircleBorder(),
            )
          else if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              color: Colors.red.shade300,
              onPressed: onDelete,
            )
          else
            Icon(Icons.chevron_right, color: secondaryText?.withValues(alpha: 0.5)),
        ],
      ),
    );
  }
}
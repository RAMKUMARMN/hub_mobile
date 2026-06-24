// lib/screens/workspace/workspace_header.dart
import 'package:flutter/material.dart';
import '../../../models/workspace/workspace.dart';
import '../../../themes/app_colors.dart';
import '../../../widgets/glass/glass_card.dart';

class WorkspaceHeader extends StatelessWidget {
  final Workspace? workspace;
  final VoidCallback? onEdit;

  const WorkspaceHeader({
    super.key,
    this.workspace,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final secondaryText = Theme.of(context).textTheme.bodyMedium?.color;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryBlue, AppColors.aiCyan],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                workspace?.icon ?? '📁',
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workspace?.name ?? 'General Workspace',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  workspace?.type.displayName ?? 'Project',
                  style: TextStyle(color: secondaryText, fontSize: 12),
                ),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.aiCyan),
              onPressed: onEdit,
            ),
        ],
      ),
    );
  }
}
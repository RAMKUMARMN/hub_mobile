// lib/screens/ai/ai_workspace_context.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/workspace_provider.dart';
import '../../themes/app_colors.dart';
import '../../models/workspace/workspace.dart';

class AIWorkspaceContext extends StatelessWidget {
  final Workspace? workspace;
  final Function(Workspace)? onWorkspaceChanged;

  const AIWorkspaceContext({
    super.key,
    this.workspace,
    this.onWorkspaceChanged,
  });

  @override
  Widget build(BuildContext context) {
    final workspaceProvider = Provider.of<WorkspaceProvider>(context);
    final secondaryText = Theme.of(context).textTheme.bodyMedium?.color;
    final cardColor = Theme.of(context).cardColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.aiCyan.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome, size: 16, color: AppColors.aiCyan),
          ),
          const SizedBox(width: 8),
          Text(
            'AI has context from:',
            style: TextStyle(color: secondaryText, fontSize: 12),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showWorkspaceSelector(context, workspaceProvider),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.aiCyan.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    workspace?.name ?? 'General',
                    style: const TextStyle(
                      color: AppColors.aiCyan,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, color: AppColors.aiCyan, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showWorkspaceSelector(BuildContext context, WorkspaceProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Workspace for AI Context',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...provider.workspaces.map((workspace) => ListTile(
              leading: Text(workspace.icon, style: const TextStyle(fontSize: 24)),
              title: Text(workspace.name),
              trailing: provider.currentWorkspace?.id == workspace.id
                  ? const Icon(Icons.check_circle, color: AppColors.aiCyan)
                  : null,
              onTap: () {
                onWorkspaceChanged?.call(workspace);
                provider.selectWorkspace(workspace);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }
}
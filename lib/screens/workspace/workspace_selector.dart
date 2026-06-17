// lib/screens/workspace/workspace_selector.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/workspace_provider.dart';
import '../../../themes/app_colors.dart';
import '../../../widgets/glass/glass_card.dart';

class WorkspaceSelector extends StatelessWidget {
  const WorkspaceSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final workspaceProvider = Provider.of<WorkspaceProvider>(context);
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    
    return GestureDetector(
      onTap: () => _showWorkspaceMenu(context, workspaceProvider),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              workspaceProvider.currentWorkspace?.name ?? 'General',
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_drop_down, color: AppColors.aiCyan),
          ],
        ),
      ),
    );
  }

  void _showWorkspaceMenu(BuildContext context, WorkspaceProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Workspace',
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
                  provider.selectWorkspace(workspace);
                  Navigator.pop(context);
                },
              )),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.add_circle_outline, color: AppColors.aiCyan),
                title: const Text('Create New Workspace'),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateWorkspaceDialog(context, provider);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateWorkspaceDialog(BuildContext context, WorkspaceProvider provider) {
  final controller = TextEditingController();
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('New Workspace'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(hintText: 'Workspace name'),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (controller.text.isNotEmpty) {
              final success = await provider.createWorkspace(controller.text);
              if (context.mounted) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Workspace created!')),
                  );
                }
              }
            }
          },
          child: const Text('Create'),
        ),
      ],
    ),
  );
}
}
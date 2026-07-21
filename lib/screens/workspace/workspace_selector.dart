// lib/screens/workspace/workspace_selector.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/workspace_provider.dart';
import '../../../themes/app_colors.dart';
import '../../../widgets/glass/glass_card.dart';
import '../../../models/workspace/workspace.dart';

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
              ...provider.workspaces.map((workspace) => _buildWorkspaceTile(
                context,
                workspace,
                provider,
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

  Widget _buildWorkspaceTile(
    BuildContext context,
    Workspace workspace,
    WorkspaceProvider provider,
  ) {
    final isSelected = provider.currentWorkspace?.id == workspace.id;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final secondaryText = Theme.of(context).textTheme.bodyMedium?.color;
    
    // ✅ Check if this is the default "General" workspace
    final isDefaultWorkspace = workspace.type == WorkspaceType.general;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected 
            ? AppColors.aiCyan.withValues(alpha: 0.1) 
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // ✅ Main tap area - selects workspace
          Expanded(
            child: GestureDetector(
              onTap: () {
                provider.selectWorkspace(workspace);
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // ✅ Show lock icon for default workspace
                    if (isDefaultWorkspace) ...[
                      Icon(
                        Icons.lock_outline,
                        size: 16,
                        color: secondaryText?.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      workspace.name,
                      style: TextStyle(
                        color: isSelected ? AppColors.aiCyan : textColor,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // ✅ Edit button - DISABLED for default workspace
          IconButton(
            icon: Icon(
              Icons.edit_outlined,
              size: 20,
              color: isDefaultWorkspace 
                  ? secondaryText?.withValues(alpha: 0.3) 
                  : secondaryText,
            ),
            onPressed: isDefaultWorkspace 
                ? null  // ✅ Disabled for General
                : () {
                    Navigator.pop(context);
                    _showEditWorkspaceDialog(context, provider, workspace);
                  },
          ),
          
          // ✅ Delete button - HIDDEN for default workspace
          if (!isDefaultWorkspace)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              color: Colors.red.shade300,
              onPressed: () {
                Navigator.pop(context);
                _confirmDeleteWorkspace(context, provider, workspace);
              },
            ),
        ],
      ),
    );
  }

  void _showEditWorkspaceDialog(
    BuildContext context,
    WorkspaceProvider provider,
    Workspace workspace,
  ) {
    final controller = TextEditingController(text: workspace.name);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Workspace Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Workspace name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != workspace.name) {
                final success = await provider.updateWorkspace(
                  workspace.id,
                  name: newName,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Workspace renamed!')),
                    );
                  }
                }
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteWorkspace(
    BuildContext context,
    WorkspaceProvider provider,
    Workspace workspace,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Workspace'),
        content: Text(
          'Are you sure you want to delete "${workspace.name}"? '
          'All tasks, notes, and files in this workspace will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await provider.deleteWorkspace(workspace.id);
              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Workspace "${workspace.name}" deleted!'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
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
          decoration: const InputDecoration(
            hintText: 'Workspace name',
            border: OutlineInputBorder(),
          ),
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
                final success = await provider.createWorkspace(
                  controller.text,
                  icon: '📁',
                  color: Colors.blue,
                );
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
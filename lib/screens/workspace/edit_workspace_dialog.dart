// lib/screens/workspace/edit_workspace_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/workspace_provider.dart';
import '../../../models/workspace/workspace.dart';
import '../../../themes/app_colors.dart';
import '../../../widgets/glass/glass_card.dart';

class EditWorkspaceDialog extends StatefulWidget {
  final Workspace workspace;

  const EditWorkspaceDialog({super.key, required this.workspace});

  @override
  State<EditWorkspaceDialog> createState() => _EditWorkspaceDialogState();
}

class _EditWorkspaceDialogState extends State<EditWorkspaceDialog> {
  late TextEditingController _nameController;
  late String _selectedIcon;
  late Color _selectedColor;
  bool _isLoading = false;

  final List<String> _icons = ['📁', '💼', '🎓', '💻', '🎨', '📊', '🏥', '🍔', '✈️', '🏠'];
  final List<Color> _colors = [
    Colors.blue, Colors.green, Colors.orange, Colors.purple,
    Colors.red, Colors.teal, Colors.pink, Colors.indigo,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.workspace.name);
    _selectedIcon = widget.workspace.icon;
    _selectedColor = widget.workspace.color;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateWorkspace() async {
    if (_nameController.text.trim().isEmpty) return;
    
    setState(() => _isLoading = true);
    
    final workspaceProvider = Provider.of<WorkspaceProvider>(context, listen: false);
    final success = await workspaceProvider.updateWorkspace(
      widget.workspace.id,
      name: _nameController.text.trim(),
      icon: _selectedIcon,
      color: _selectedColor,
    );
    
    setState(() => _isLoading = false);
    
    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Workspace updated!')),
      );
    }
  }

  Future<void> _deleteWorkspace() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Workspace'),
        content: Text('Are you sure you want to delete "${widget.workspace.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    setState(() => _isLoading = true);
    
    final workspaceProvider = Provider.of<WorkspaceProvider>(context, listen: false);
    final success = await workspaceProvider.deleteWorkspace(widget.workspace.id);
    
    setState(() => _isLoading = false);
    
    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Workspace deleted!'), backgroundColor: Colors.orange),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Colors.transparent,
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Edit Workspace',
              style: TextStyle(
                color: textColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            // Name input
            TextField(
              controller: _nameController,
              style: TextStyle(color: textColor),
              decoration: const InputDecoration(
                hintText: 'Workspace name',
                border: OutlineInputBorder(),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Icon selector
            const Text('Choose Icon', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _icons.length,
                itemBuilder: (context, index) {
                  final icon = _icons[index];
                  final isSelected = _selectedIcon == icon;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = icon),
                    child: Container(
                      width: 50,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.aiCyan.withValues(alpha: 0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected ? Border.all(color: AppColors.aiCyan) : null,
                      ),
                      child: Center(
                        child: Text(icon, style: const TextStyle(fontSize: 28)),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Color selector
            const Text('Choose Color', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _colors.length,
                itemBuilder: (context, index) {
                  final color = _colors[index];
                  final isSelected = _selectedColor == color;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      width: 36,
                      height: 36,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 24),
            
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _deleteWorkspace,
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Delete'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateWorkspace,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
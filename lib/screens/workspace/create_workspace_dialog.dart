// lib/screens/workspace/create_workspace_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/workspace_provider.dart';
import '../../../themes/app_colors.dart';

class CreateWorkspaceDialog extends StatefulWidget {
  const CreateWorkspaceDialog({super.key});

  @override
  State<CreateWorkspaceDialog> createState() => _CreateWorkspaceDialogState();
}

class _CreateWorkspaceDialogState extends State<CreateWorkspaceDialog> {
  final TextEditingController _nameController = TextEditingController();
  String _selectedIcon = '📁';
  Color _selectedColor = Colors.blue;
  bool _isLoading = false;

  final List<String> _icons = ['📁', '💼', '🎓', '💻', '🎨', '📊', '🏥', '🍔', '✈️', '🏠'];
  final List<Color> _colors = [
    Colors.blue, Colors.green, Colors.orange, Colors.purple,
    Colors.red, Colors.teal, Colors.pink, Colors.indigo,
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createWorkspace() async {
    if (_nameController.text.trim().isEmpty) return;
    
    setState(() => _isLoading = true);
    
    final workspaceProvider = Provider.of<WorkspaceProvider>(context, listen: false);
    final success = await workspaceProvider.createWorkspace(
      _nameController.text.trim(),
      icon: _selectedIcon,
      color: _selectedColor,
    );
    
    setState(() => _isLoading = false);
    
    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Workspace "${_nameController.text}" created!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Colors.transparent,
      child: SingleChildScrollView(  // ← ADD THIS to prevent overflow
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.aiCyan.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Create Workspace',
                style: TextStyle(
                  color: textColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              
              TextField(
                controller: _nameController,
                autofocus: true,
                style: TextStyle(color: textColor),
                decoration: const InputDecoration(
                  hintText: 'Workspace name',
                  border: OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 20),
              
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
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createWorkspace,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Create'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
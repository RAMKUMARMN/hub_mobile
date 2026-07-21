// lib/widgets/workspace/workspace_filter_chips.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/workspace_provider.dart';
import '../../themes/app_colors.dart';

class WorkspaceFilterChips extends StatelessWidget {
  const WorkspaceFilterChips({super.key});

  @override
  Widget build(BuildContext context) {
    final workspaceProvider = Provider.of<WorkspaceProvider>(context);
    final currentFilter = workspaceProvider.currentFilter;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildFilterChip('All', 'all', currentFilter == 'all', context, workspaceProvider),
          const SizedBox(width: 8),
          _buildFilterChip('Tasks', 'tasks', currentFilter == 'tasks', context, workspaceProvider),
          const SizedBox(width: 8),
          _buildFilterChip('Notes', 'notes', currentFilter == 'notes', context, workspaceProvider),
          const SizedBox(width: 8),
          _buildFilterChip('Files', 'files', currentFilter == 'files', context, workspaceProvider),
          const SizedBox(width: 8),
          _buildFilterChip('Reminders', 'reminders', currentFilter == 'reminders', context, workspaceProvider),
        ],
      ),
    );
  }
  
  Widget _buildFilterChip(String label, String filter, bool isSelected, BuildContext context, WorkspaceProvider provider) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          provider.setFilter(filter);
        }
      },
      backgroundColor: Colors.transparent,
      selectedColor: AppColors.aiCyan.withValues(alpha: 0.2),
      checkmarkColor: AppColors.aiCyan,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.aiCyan : null,
      ),
    );
  }
}
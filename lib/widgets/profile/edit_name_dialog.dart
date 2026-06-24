// lib/widgets/profile/edit_name_dialog.dart
import 'package:flutter/material.dart';
import '../../themes/app_colors.dart';

class EditNameDialog extends StatelessWidget {
  final String currentName;
  final Function(String) onNameUpdated;

  const EditNameDialog({
    super.key,
    required this.currentName,
    required this.onNameUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final TextEditingController nameController = TextEditingController(text: currentName);
    
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.edit, size: 24),
          SizedBox(width: 8),
          Text('Edit Name'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Change your display name',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              hintText: 'Enter your name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.person_outline),
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.words,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final newName = nameController.text.trim();
            
            if (newName.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Name cannot be empty'), backgroundColor: Colors.red),
              );
              return;
            }
            
            if (newName == currentName) {
              Navigator.pop(context);
              return;
            }
            
            Navigator.pop(context);
            onNameUpdated(newName);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.aiCyan,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
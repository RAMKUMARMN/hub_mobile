// lib/widgets/quick_action_card.dart
import 'package:flutter/material.dart';
import '../../themes/app_colors.dart';
import '../../services/local/note_service.dart';
import '../../services/local/file_service.dart';
import '../glass/glass_card.dart';

class QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Map<String, dynamic>? actionData;

  const QuickActionCard({
    super.key,
    required this.icon,
    required this.title,
    this.onTap,
    this.actionData,
  });

  void _handleDefaultAction(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title in progress...'),
        duration: const Duration(seconds: 1),
      ),
    );

    switch (title.toLowerCase()) {
      case 'upload':
        FileService(context: context).showUploadDialog();
        break;
      case 'ask ai':
        Navigator.pushNamed(context, '/ai');
        break;
      case 'notes':
        NoteService(context: context).showCreateNoteDialog();
        break;
      case 'tasks':
        Navigator.pushNamed(context, '/workspace');
        break;
      case 'reminder':
        // Reminder handled by ReminderService
        break;
      case 'smart note':
        Navigator.pushNamed(context, '/smart-note');
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title feature coming soon!')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return GestureDetector(
      onTap: onTap ?? () => _handleDefaultAction(context),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.aiCyan, size: 36),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
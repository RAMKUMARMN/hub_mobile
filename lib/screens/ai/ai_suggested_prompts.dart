// lib/screens/ai/ai_suggested_prompts.dart
import 'package:flutter/material.dart';
import '../../themes/app_colors.dart';

class AISuggestedPrompts extends StatelessWidget {
  final List<String> prompts;
  final Function(String) onPromptSelected;

  const AISuggestedPrompts({
    super.key,
    required this.prompts,
    required this.onPromptSelected,
  });

  @override
  Widget build(BuildContext context) {
    final secondaryText = Theme.of(context).textTheme.bodyMedium?.color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              'Try asking:',
              style: TextStyle(
                color: secondaryText,
                fontSize: 12,
              ),
            ),
          ),
          SizedBox(
            height: 42,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: prompts.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: FilterChip(
                    label: Text(prompts[index]),
                    onSelected: (_) => onPromptSelected(prompts[index]),
                    backgroundColor: Theme.of(context).cardColor,
                    selectedColor: AppColors.aiCyan.withValues(alpha: 0.2),
                    labelStyle: const TextStyle(
                      color: AppColors.aiCyan,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
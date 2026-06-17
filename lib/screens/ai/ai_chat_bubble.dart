// lib/screens/ai/ai_chat_bubble.dart
import 'package:flutter/material.dart';
import '../../themes/app_colors.dart';

class AIChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;
  final VoidCallback onCopy;

  const AIChatBubble({
    super.key,
    required this.message,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
    required this.onCopy,
  });

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final secondaryText = Theme.of(context).textTheme.bodyMedium?.color;
    final cardColor = Theme.of(context).cardColor;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onCopy,
        child: Container(
          margin: const EdgeInsets.only(bottom: 18),
          constraints: const BoxConstraints(maxWidth: 300),
          child: Column(
            crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isUser 
                      ? AppColors.primaryBlue 
                      : (isError ? Colors.red.shade700 : cardColor),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: SelectableText(
                  message,
                  style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(timestamp),
                      style: TextStyle(fontSize: 10, color: secondaryText),
                    ),
                    const SizedBox(width: 8),
                    if (!isUser)
                      Icon(
                        Icons.copy_outlined,
                        size: 12,
                        color: secondaryText,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
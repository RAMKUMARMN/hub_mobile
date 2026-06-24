// lib/screens/ai/ai_chat_widgets.dart
import 'package:flutter/material.dart';
import '../../themes/app_colors.dart';

// ============================================================================
// AIChatBubble - Chat message bubble
// ============================================================================

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

// ============================================================================
// Typing Indicator - Shows when AI is thinking
// ============================================================================

Widget buildTypingIndicator() {
  return Builder(
    builder: (context) {
      final textColor = Theme.of(context).textTheme.bodyLarge?.color;
      final cardColor = Theme.of(context).cardColor;

      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 18),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.aiCyan),
              ),
              const SizedBox(width: 14),
              Text(
                "AI is thinking...",
                style: TextStyle(color: textColor),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// ============================================================================
// Empty State - Shown when no messages
// ============================================================================

Widget buildEmptyState() {
  return Builder(
    builder: (context) {
      final secondaryText = Theme.of(context).textTheme.bodyMedium?.color;

      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: AppColors.aiCyan,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Start a conversation',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Ask me about your tasks, notes, or anything\nin your workspace',
                textAlign: TextAlign.center,
                style: TextStyle(color: secondaryText, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// ============================================================================
// Loading Shimmer - Shown when AI is loading
// ============================================================================

Widget buildLoadingShimmer() {
  return Builder(
    builder: (context) {
      final secondaryText = Theme.of(context).textTheme.bodyMedium?.color;

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.aiCyan),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading AI Assistant...',
              style: TextStyle(color: secondaryText),
            ),
          ],
        ),
      );
    },
  );
}
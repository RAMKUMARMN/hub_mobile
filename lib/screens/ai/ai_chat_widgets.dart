// lib/screens/ai/ai_chat_widgets.dart
import 'package:flutter/material.dart';
import '../../themes/app_colors.dart';

// ============================================================================
// AIChatBubble - Chat message bubble with thinking & sources support
// ============================================================================

class AIChatBubble extends StatefulWidget {
  final String message;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;
  final VoidCallback onCopy;
  final String? thinking;
  final List<Map<String, dynamic>>? sources;

  const AIChatBubble({
    super.key,
    required this.message,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
    required this.onCopy,
    this.thinking,
    this.sources,
  });

  @override
  State<AIChatBubble> createState() => _AIChatBubbleState();
}

class _AIChatBubbleState extends State<AIChatBubble> {
  bool _thinkingExpanded = false;

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final secondaryText = Theme.of(context).textTheme.bodyMedium?.color;
    final cardColor = Theme.of(context).cardColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ✅ FIXED: Use theme-aware text color instead of hardcoded white
    final answerTextColor = widget.isUser
        ? Colors.white
        : (isDark ? Colors.white : Colors.black87);

    return Align(
      alignment: widget.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: widget.onCopy,
        child: Container(
          margin: const EdgeInsets.only(bottom: 18),
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            crossAxisAlignment:
                widget.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [

              // ── Thought Process collapsible block (AI only) ──────────────
              if (!widget.isUser &&
                  widget.thinking != null &&
                  widget.thinking!.isNotEmpty)
                _ThinkingBlock(
                  thinking: widget.thinking!,
                  expanded: _thinkingExpanded,
                  onToggle: () =>
                      setState(() => _thinkingExpanded = !_thinkingExpanded),
                ),

              // ── Main message bubble ──────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.isUser
                      ? AppColors.primaryBlue
                      : (widget.isError ? Colors.red.shade700 : cardColor),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: SelectableText(
                  widget.message,
                  style: TextStyle(
                    color: answerTextColor,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ),

              // ── Source citation cards (AI only, when RAG is active) ──────
              if (!widget.isUser &&
                  widget.sources != null &&
                  widget.sources!.isNotEmpty)
                _SourcesRow(sources: widget.sources!),

              // ── Timestamp row ────────────────────────────────────────────
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(widget.timestamp),
                      style: TextStyle(fontSize: 10, color: secondaryText),
                    ),
                    const SizedBox(width: 8),
                    if (!widget.isUser)
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
// _ThinkingBlock - Collapsible DeepSeek reasoning panel
// ============================================================================

class _ThinkingBlock extends StatelessWidget {
  final String thinking;
  final bool expanded;
  final VoidCallback onToggle;

  const _ThinkingBlock({
    required this.thinking,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onToggle,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: AppColors.aiCyan.withValues(alpha: isDark ? 0.08 : 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.aiCyan.withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.psychology_outlined,
                      size: 14, color: AppColors.aiCyan),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Thought Process',
                      style: TextStyle(
                        color: AppColors.aiCyan,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: AppColors.aiCyan,
                  ),
                ],
              ),
            ),
            // Collapsible content
            if (expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Text(
                  thinking,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: isDark
                        ? Colors.white70
                        : Colors.black54,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// _SourcesRow - Horizontal scroll of RAG citation cards
// ============================================================================

class _SourcesRow extends StatelessWidget {
  final List<Map<String, dynamic>> sources;

  const _SourcesRow({required this.sources});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        height: 56,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: sources.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final src = sources[index];
            final filename = src['filename']?.toString() ??
                src['document_id']?.toString() ??
                'Source ${index + 1}';
            final page = src['page_number']?.toString();

            return Container(
              constraints: const BoxConstraints(maxWidth: 140),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.aiCyan.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.aiCyan.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.article_outlined,
                          size: 12, color: AppColors.aiCyan),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          filename,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.aiCyan,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (page != null)
                    Text(
                      'Page $page',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.aiCyan.withValues(alpha: 0.7),
                      ),
                    ),
                ],
              ),
            );
          },
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
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.aiCyan),
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
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.aiCyan),
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
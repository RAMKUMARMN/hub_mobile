// lib/screens/ai/ai_input_widgets.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../themes/app_colors.dart';
import '../../models/workspace/workspace.dart';

// ============================================================================
// AIInputArea - Input bar with text field and send button
// ============================================================================

class AIInputArea extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onFileUpload;
  final bool isTyping;

  const AIInputArea({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onFileUpload,
    required this.isTyping,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final secondaryText = Theme.of(context).textTheme.bodyMedium?.color;
    final cardColor = Theme.of(context).cardColor;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: onFileUpload,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.attach_file, size: 22, color: AppColors.aiCyan),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: controller,
                  onSubmitted: (_) => onSend(),
                  style: TextStyle(color: textColor),
                  maxLines: 5,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: "Ask SmartHub AI...",
                    hintStyle: TextStyle(color: secondaryText?.withValues(alpha: 0.6)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    suffixIcon: controller.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: secondaryText, size: 18),
                            onPressed: () => controller.clear(),
                          )
                        : null,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: isTyping ? null : onSend,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isTyping ? Colors.grey : AppColors.primaryBlue,
                  shape: BoxShape.circle,
                ),
                child: isTyping
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// AISuggestedPrompts - Suggested prompt chips
// ============================================================================

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
              style: TextStyle(color: secondaryText, fontSize: 12),
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

// ============================================================================
// AIFileUpload - Upload bottom sheet content
// ============================================================================

class AIFileUpload extends StatelessWidget {
  final Workspace? currentWorkspace;
  final Function(String filePath, String fileName) onFileSelected;

  const AIFileUpload({
    super.key,
    required this.currentWorkspace,
    required this.onFileSelected,
  });

  Future<void> _pickFile(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      onFileSelected(image.path, image.name);
    }
  }

  Future<void> _pickDocument(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('File upload coming soon!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Upload to AI',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.aiCyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  currentWorkspace?.name ?? 'General',
                  style: const TextStyle(
                    color: AppColors.aiCyan,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Files will be saved to "${currentWorkspace?.name ?? 'General'}" workspace',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildUploadOption(
                icon: Icons.camera_alt,
                label: 'Camera',
                onTap: () => _pickFile(ImageSource.camera),
              ),
              _buildUploadOption(
                icon: Icons.photo_library,
                label: 'Gallery',
                onTap: () => _pickFile(ImageSource.gallery),
              ),
              _buildUploadOption(
                icon: Icons.picture_as_pdf,
                label: 'Document',
                onTap: () => _pickDocument(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Upload images or documents for AI analysis',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade300,
              foregroundColor: Colors.black,
            ),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.aiCyan.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.aiCyan, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
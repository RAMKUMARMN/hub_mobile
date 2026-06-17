// lib/screens/ai/ai_file_upload.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../themes/app_colors.dart';

class AIFileUpload extends StatelessWidget {
  final Function(String filePath, String fileName) onFileSelected;

  const AIFileUpload({
    super.key,
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
    // Temporarily disabled due to package issues
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('File upload coming soon!')),
    );
    
    // Original code commented out
    // final result = await FilePicker.platform.pickFiles();
    // if (result != null) {
    //   onFileSelected(result.files.single.path!, result.files.single.name);
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Upload to AI',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                onTap: () => _pickDocument(context),  // ← Pass context here
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Upload images or documents for AI analysis',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
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
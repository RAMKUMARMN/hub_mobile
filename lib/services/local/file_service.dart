// lib/services/local/file_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/app_state.dart';
import '../../providers/workspace_provider.dart';
import '../../models/workspace_items/document.dart';
import '../api/document_api.dart';
import '../../utils/helpers.dart';

class FileService {
  final BuildContext context;
  final ImagePicker _picker = ImagePicker();
  
  FileService({required this.context});

  Future<bool> uploadFile({
    required File file,
    required String fileType,
    String? customFileName,
  }) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final workspaceProvider = Provider.of<WorkspaceProvider>(context, listen: false);
    final workspaceId = workspaceProvider.currentWorkspace?.id;
    
    print('=== UPLOAD DEBUG ===');
    print('Current workspace ID: $workspaceId');
    print('Current workspace name: ${workspaceProvider.currentWorkspace?.name}');
    
    if (workspaceId == null) {
      Helpers.showError(context, 'No workspace selected');
      return false;
    }
    
    Helpers.showInfo(context, 'Uploading $fileType...');
    
    try {
      final response = await DocumentApi.uploadDocument(
        file: file,
        workspaceId: workspaceId,
      );
      
      if (response['success'] == true) {
        final fileName = customFileName ?? file.path.split('/').last;
        final fileSize = await file.length();
        final backendData = response['data'];
        
        // Create document from backend response
        final document = Document(
          id: backendData?['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          workspaceId: workspaceId,
          title: fileName,
          subtitle: 'Uploaded to ${workspaceProvider.currentWorkspace?.name ?? 'General'}',
          icon: _getFileIcon(fileType),
          filePath: backendData?['filepath'] ?? file.path,
          fileType: backendData?['filetype'] ?? fileType,
          fileSize: backendData?['size'] ?? fileSize,
          thumbnail: backendData?['thumbnail'],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        // Add to local state
        appState.addWorkspaceItem(document, workspaceId: workspaceId);
        appState.addActivity('📄 $fileName uploaded to workspace');
        Helpers.showSuccess(context, '$fileType uploaded successfully!');
        
        print('Added document to workspace: $workspaceId');
        print('Total items now: ${appState.workspaceItems.length}');
        
        // Refresh to ensure we have the latest from backend
        await _refreshDocuments(workspaceId, appState);
        
        return true;
      } else {
        Helpers.showError(context, response['error'] ?? 'Upload failed');
        return false;
      }
    } catch (e) {
      print('Upload error: $e');
      Helpers.showError(context, 'Upload failed: ${e.toString()}');
      return false;
    }
  }

  Future<void> _refreshDocuments(String workspaceId, AppState appState) async {
    try {
      final response = await DocumentApi.getDocuments(workspaceId: workspaceId);
      if (response['success'] == true) {
        final documents = response['data'] as List;
        
        // Remove old documents for this workspace
        final items = appState.workspaceItems.toList();
        for (var item in items) {
          if (item is Document && item.workspaceId == workspaceId) {
            final index = appState.workspaceItems.indexOf(item);
            if (index != -1) {
              appState.removeWorkspaceItem(index);
            }
          }
        }
        
        // Add fresh documents from backend
        for (var docJson in documents) {
          final document = Document.fromJson(docJson);
          appState.addWorkspaceItem(document, workspaceId: workspaceId);
        }
      }
    } catch (e) {
      print('Refresh error: $e');
    }
  }

  /// Pick image from gallery
  Future<void> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        await uploadFile(
          file: File(image.path),
          fileType: 'Image',
          customFileName: image.name,
        );
      }
    } catch (e) {
      Helpers.showError(context, 'Failed to pick image: ${e.toString()}');
    }
  }

  /// Pick image from camera
  Future<void> takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        await uploadFile(
          file: File(image.path),
          fileType: 'Photo',
          customFileName: image.name,
        );
      }
    } catch (e) {
      Helpers.showError(context, 'Failed to take photo: ${e.toString()}');
    }
  }

  /// Pick any document (PDF, DOC, TXT, etc.)
  Future<void> pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'md'],
      );
      
      if (result != null) {
        final file = File(result.files.single.path!);
        final extension = result.files.single.extension ?? 'file';
        await uploadFile(
          file: file,
          fileType: extension.toUpperCase(),
          customFileName: result.files.single.name,
        );
      }
    } catch (e) {
      Helpers.showError(context, 'Failed to pick document: ${e.toString()}');
    }
  }

  /// Show upload dialog (reusable)
  void showUploadDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomContext) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Upload File', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildUploadOption(
              icon: Icons.description,
              title: 'Document',
              subtitle: '.pdf, .doc, .docx, .txt',
              onTap: pickDocument,
            ),
            const SizedBox(height: 12),
            _buildUploadOption(
              icon: Icons.image,
              title: 'Gallery',
              subtitle: '.jpg, .png, .gif',
              onTap: pickImage,
            ),
            const SizedBox(height: 12),
            _buildUploadOption(
              icon: Icons.camera_alt,
              title: 'Camera',
              subtitle: 'Take a photo',
              onTap: takePhoto,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(bottomContext),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade300,
              ),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF0BD1FA).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFF0BD1FA)),
      ),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  IconData _getFileIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'image':
      case 'photo':
      case 'jpeg':
      case 'jpg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'document':
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'txt':
      case 'md':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }
}
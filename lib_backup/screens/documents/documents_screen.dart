import 'dart:async';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../models/document.dart';
import '../../services/api_service.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  List<Document> _documents = [];
  bool _isLoading = true;
  bool _isUploading = false;
  String? _error;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDocuments() async {
    try {
      final response = await ApiService().dio.get('/documents/');
      final docs = (response.data as List)
          .map((d) => Document.fromJson(d as Map<String, dynamic>))
          .toList();
      setState(() {
        _documents = docs;
        _isLoading = false;
        _error = null;
      });
      // Poll while any document is still processing
      if (docs.any((d) => !d.processed)) {
        _pollTimer?.cancel();
        _pollTimer = Timer(const Duration(seconds: 3), _loadDocuments);
      }
    } on DioException catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load documents: ${e.message}';
      });
    }
  }

  Future<void> _uploadDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'md', 'docx'],
      withData: true, // ensures bytes are available on iOS document picker
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    if (file.bytes == null && file.path == null) return;

    setState(() { _isUploading = true; });
    try {
      final filename = file.name;
      final contentType = DioMediaType.parse(_mimeTypeFor(filename));
      final MultipartFile multipartFile = file.bytes != null
          ? MultipartFile.fromBytes(
              file.bytes!,
              filename: filename,
              contentType: contentType,
            )
          : await MultipartFile.fromFile(
              file.path!,
              filename: filename,
              contentType: contentType,
            );
      final formData = FormData.fromMap({'file': multipartFile});
      await ApiService().dio.post('/documents/upload', data: formData);
      await _loadDocuments();
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: ${e.message ?? "Unknown error"}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() { _isUploading = false; });
    }
  }

  String _mimeTypeFor(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':  return 'application/pdf';
      case 'docx': return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt':
      case 'md':   return 'text/plain';
      default:     return 'application/octet-stream';
    }
  }

  Future<void> _deleteDocument(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete document?'),
        content: const Text('This will remove the document and all its indexed chunks.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiService().dio.delete('/documents/$id');
      setState(() { _documents.removeWhere((d) => d.id == id); });
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: ${e.message ?? "Unknown error"}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: _loadDocuments, child: const Text('Retry')),
                    ],
                  ),
                )
              : _documents.isEmpty
                  ? const Center(child: Text('No documents yet. Upload your first document!'))
                  : RefreshIndicator(
                      onRefresh: _loadDocuments,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _documents.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final doc = _documents[index];
                          return Card(
                            child: ListTile(
                              leading: _docIcon(doc.fileType),
                              title: Text(doc.filename),
                              subtitle: Text(
                                doc.processed
                                    ? '${doc.chunkCount} chunks • ${_formatSize(doc.fileSize)}'
                                    : 'Processing...',
                                style: TextStyle(
                                  color: doc.processed ? Colors.green.shade700 : Colors.orange,
                                ),
                              ),
                              trailing: doc.processed
                                  ? IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: () => _deleteDocument(doc.id),
                                    )
                                  : const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_documents',
        onPressed: _isUploading ? null : _uploadDocument,
        icon: _isUploading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.upload_file),
        label: Text(_isUploading ? 'Uploading...' : 'Upload'),
      ),
    );
  }

  Widget _docIcon(String type) {
    IconData icon;
    Color color;
    switch (type.toLowerCase()) {
      case 'pdf':
        icon = Icons.picture_as_pdf;
        color = Colors.red;
      case 'txt':
      case 'md':
        icon = Icons.article;
        color = Colors.blue;
      default:
        icon = Icons.insert_drive_file;
        color = Colors.grey;
    }
    return Icon(icon, color: color, size: 32);
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}


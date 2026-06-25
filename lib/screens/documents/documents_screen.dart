import 'dart:async';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/document.dart';
import '../../services/api_service.dart';
import '../../services/document_cache.dart';
import '../../utils/error_formatter.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/skeleton_loader.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  List<Document> _documents = [];
  bool _isLoading = true;
  bool _isUploading = false;
  bool _backendLoaded = false;
  bool _isOffline = false;
  String? _error;
  Timer? _pollTimer;
  GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    _loadCachedDocuments();
    _loadDocuments();
  }

  Future<void> _loadCachedDocuments() async {
    final cached = await DocumentCache.loadDocuments();
    if (!mounted || _backendLoaded || cached.isEmpty) return;
    setState(() {
      _documents = cached;
      _isLoading = false;
      _listKey = GlobalKey<AnimatedListState>();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDocuments() async {
    try {
      final response = await ApiService().dio.get('/documents/');
      if (!mounted) return;
      _backendLoaded = true;
      final docs = (response.data as List)
          .map((d) => Document.fromJson(d as Map<String, dynamic>))
          .toList();
      setState(() {
        _documents = docs;
        _isLoading = false;
        _error = null;
        _listKey = GlobalKey<AnimatedListState>();
      });
      await DocumentCache.saveDocuments(docs);
      // Poll while any document is still processing
      if (docs.any((d) => !d.processed)) {
        _pollTimer?.cancel();
        _pollTimer = Timer(const Duration(seconds: 3), _loadDocuments);
      }
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (_documents.isEmpty) {
          _error = ErrorFormatter.format(e);
        } else {
          _isOffline = true;
        }
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
          SnackBar(content: Text(ErrorFormatter.format(e, fallback: 'Upload failed.'))),
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
      HapticFeedback.lightImpact();
      
      final idx = _documents.indexWhere((d) => d.id == id);
      if (idx != -1) {
        final doc = _documents[idx];
        _documents.removeAt(idx);
        _listKey.currentState?.removeItem(
          idx,
          (context, animation) => _buildItem(doc, animation),
          duration: const Duration(milliseconds: 200),
        );
      }
      await DocumentCache.saveDocuments(_documents);
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorFormatter.format(e, fallback: 'Delete failed.'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          OfflineBanner(isOffline: _isOffline),
          Expanded(
            child: _isLoading
                ? const SkeletonLoader()
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
                      child: AnimatedList(
                        key: _listKey,
                        padding: const EdgeInsets.all(16),
                        initialItemCount: _documents.length,
                        itemBuilder: (context, index, animation) {
                          return _buildItem(_documents[index], animation);
                        },
                      ),
                    ),
          ),
        ],
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

  Widget _buildItem(Document doc, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: Card(
          margin: const EdgeInsets.only(bottom: 8),
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
        ),
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


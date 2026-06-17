// lib/screens/workspace_items/document_list.dart
import 'package:flutter/material.dart';
import '../../../models/workspace_items/document.dart';
import 'document_card.dart';

class DocumentList extends StatelessWidget {
  final List<Document> documents;
  final Function(Document) onDocumentDelete;

  const DocumentList({
    super.key,
    required this.documents,
    required this.onDocumentDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.upload_file, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No documents yet',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to upload',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final document = documents[index];
        return DocumentCard(
          document: document,
          onDelete: () => onDocumentDelete(document),
        );
      },
    );
  }
}
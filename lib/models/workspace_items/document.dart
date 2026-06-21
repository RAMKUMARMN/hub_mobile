// lib/models/workspace_items/document.dart

import 'package:flutter/material.dart';
import 'workspace_item.dart';
import '../../themes/app_colors.dart';

class Document extends WorkspaceItem {
  final String filePath;
  final String fileType;
  final int fileSize;
  final String? thumbnail;

  Document({
    required super.id,
    required super.workspaceId,
    required super.title,
    required super.subtitle,
    required super.icon,
    required this.filePath,
    required this.fileType,
    required this.fileSize,
    this.thumbnail,
    required super.createdAt,
    required super.updatedAt,
  });

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'workspaceId': workspaceId,
    'title': title,
    'subtitle': subtitle,
    'icon': icon.codePoint,
    'filePath': filePath,
    'fileType': fileType,
    'fileSize': fileSize,
    'thumbnail': thumbnail,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  // FIXED: backend DocumentResponse sends:
  //   id, workspace_id, filename, filetype, size, created_at
  // It does NOT send: title, subtitle, filePath, updatedAt (camelCase
  // versions never existed; updated_at doesn't exist on this endpoint at all).
  factory Document.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.parse(
      (json['created_at'] ?? json['createdAt']).toString(),
    );

    return Document(
      id: json['id'].toString(),
      workspaceId: (json['workspace_id'] ?? json['workspaceId'])?.toString() ?? '',
      // Backend has no "title"/"subtitle" fields for documents — derive
      // sensible display values from filename/filetype instead.
      title: (json['filename'] ?? json['title'] ?? 'Untitled').toString(),
      subtitle: (json['filetype'] ?? json['subtitle'] ?? '').toString(),
      icon: Icons.insert_drive_file,
      // Backend has no file path/URL field on this response — use download
      // endpoint id-based lookup instead of expecting a literal path.
      filePath: (json['filePath'] ?? json['file_path'] ?? '').toString(),
      fileType: (json['filetype'] ?? json['fileType'] ?? '').toString(),
      fileSize: json['size'] is int
          ? json['size'] as int
          : int.tryParse((json['size'] ?? json['fileSize'] ?? '0').toString()) ?? 0,
      thumbnail: json['thumbnail']?.toString(),
      createdAt: createdAt,
      // Backend doesn't return updated_at for documents; fall back to
      // created_at rather than crashing on a non-nullable DateTime.
      updatedAt: json['updated_at'] != null || json['updatedAt'] != null
          ? DateTime.parse((json['updated_at'] ?? json['updatedAt']).toString())
          : createdAt,
    );
  }
  
  String get formattedFileSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData get fileIcon {
    final type = fileType.toLowerCase();
    if (type.contains('pdf')) return Icons.picture_as_pdf;
    if (type.contains('image')) return Icons.image;
    if (type.contains('word') || type.contains('doc')) return Icons.description;
    if (type.contains('sheet') || type.contains('excel')) return Icons.table_chart;
    if (type.contains('slide') || type.contains('powerpoint')) return Icons.slideshow;
    return Icons.insert_drive_file;
  }

  Color get fileColor {
    final type = fileType.toLowerCase();
    if (type.contains('pdf')) return Colors.red;
    if (type.contains('image')) return Colors.purple;
    if (type.contains('word') || type.contains('doc')) return Colors.blue;
    if (type.contains('sheet') || type.contains('excel')) return Colors.green;
    if (type.contains('slide') || type.contains('powerpoint')) return Colors.orange;
    return AppColors.aiCyan;
  }
}
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

  // ✅ ADD THIS FACTORY METHOD
  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'],
      workspaceId: json['workspaceId'],
      title: json['title'],
      subtitle: json['subtitle'],
      icon: IconData(json['icon'], fontFamily: 'MaterialIcons'),
      filePath: json['filePath'],
      fileType: json['fileType'],
      fileSize: json['fileSize'],
      thumbnail: json['thumbnail'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
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
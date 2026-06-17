class Document {
  final String id;
  final String filename;
  final String fileType;
  final int fileSize;
  final bool processed;
  final int chunkCount;
  final String createdAt;

  const Document({
    required this.id,
    required this.filename,
    required this.fileType,
    required this.fileSize,
    required this.processed,
    required this.chunkCount,
    required this.createdAt,
  });

  factory Document.fromJson(Map<String, dynamic> json) => Document(
        id: json['id'] as String,
        filename: json['filename'] as String,
        fileType: json['file_type'] as String? ?? '',
        fileSize: (json['file_size'] as num?)?.toInt() ?? 0,
        processed: json['processed'] as bool? ?? false,
        chunkCount: (json['chunk_count'] as num?)?.toInt() ?? 0,
        createdAt: json['created_at'] as String? ?? '',
      );
}

/// The kind of media a [MediaItem] represents.
enum MediaType {
  voice,
  photo,
  video;

  /// Default MIME type used when detection fails.
  static const String defaultMimeType = 'application/octet-stream';

  static MediaType fromName(String? value) => MediaType.values.firstWhere(
        (t) => t.name == value,
        orElse: () => MediaType.photo,
      );

  /// Derives the media type from a MIME type (e.g. `image/jpeg` → [photo]).
  static MediaType fromMimeType(String? mimeType) {
    final mime = (mimeType ?? defaultMimeType).toLowerCase();
    if (mime.startsWith('image/')) return MediaType.photo;
    if (mime.startsWith('video/')) return MediaType.video;
    if (mime.startsWith('audio/')) return MediaType.voice;
    return MediaType.photo;
  }

  /// The tag string sent to the backend / S3 metadata.
  String get tag => switch (this) {
        MediaType.photo => 'Photo',
        MediaType.video => 'Video',
        MediaType.voice => 'VoiceRecording',
      };
}

/// Lifecycle of a locally-captured file as it makes its way to S3.
enum UploadStatus {
  /// Saved to local storage, not uploaded yet.
  pending,

  /// Upload is currently in flight.
  uploading,

  /// Object confirmed in S3.
  uploaded,

  /// Last upload attempt failed; the periodic sync will retry.
  failed;

  static UploadStatus fromName(String? value) => UploadStatus.values.firstWhere(
        (s) => s.name == value,
        orElse: () => UploadStatus.pending,
      );
}

/// A voice recording / photo / video captured on the device.
///
/// The original file always lives on the phone first ([localPath]); the S3
/// upload happens in the background and never blocks capture.
class MediaItem {
  final String id;
  final MediaType type;

  /// Absolute path of the original file in the app's local documents dir.
  final String localPath;
  final String fileName;
  final String mimeType;
  final int sizeBytes;
  final String createdAt;

  final UploadStatus status;

  /// How many upload attempts have been made so far.
  final int attempts;

  /// S3 object key once (or while) uploaded.
  final String? s3Key;
  final String? lastError;

  const MediaItem({
    required this.id,
    required this.type,
    required this.localPath,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
    required this.createdAt,
    this.status = UploadStatus.pending,
    this.attempts = 0,
    this.s3Key,
    this.lastError,
  });

  bool get isUploaded => status == UploadStatus.uploaded;
  bool get needsUpload =>
      status == UploadStatus.pending || status == UploadStatus.failed;

  /// Tag string derived from the stored [MediaType].
  String get mediaTypeTag => type.tag;

  MediaItem copyWith({
    UploadStatus? status,
    int? attempts,
    String? s3Key,
    String? lastError,
    bool clearError = false,
  }) {
    return MediaItem(
      id: id,
      type: type,
      localPath: localPath,
      fileName: fileName,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      createdAt: createdAt,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      s3Key: s3Key ?? this.s3Key,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'local_path': localPath,
        'file_name': fileName,
        'mime_type': mimeType,
        'size_bytes': sizeBytes,
        'created_at': createdAt,
        'status': status.name,
        'attempts': attempts,
        's3_key': s3Key,
        'last_error': lastError,
      };

  factory MediaItem.fromJson(Map<String, dynamic> json) => MediaItem(
        id: json['id'] as String,
        type: MediaType.fromName(json['type'] as String?),
        localPath: json['local_path'] as String,
        fileName: json['file_name'] as String? ?? '',
        mimeType: json['mime_type'] as String? ?? 'application/octet-stream',
        sizeBytes: (json['size_bytes'] as num?)?.toInt() ?? 0,
        createdAt: json['created_at'] as String? ?? '',
        status: UploadStatus.fromName(json['status'] as String?),
        attempts: (json['attempts'] as num?)?.toInt() ?? 0,
        s3Key: json['s3_key'] as String?,
        lastError: json['last_error'] as String?,
      );
}

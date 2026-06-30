class Note {
  final String id;
  final String title;
  final String content;
  final String? tags;
  final bool pinned;
  final String createdAt;
  final String updatedAt;

  const Note({
    required this.id,
    required this.title,
    required this.content,
    this.tags,
    required this.pinned,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'] as String,
        title: json['title'] as String,
        content: json['content'] as String? ?? '',
        tags: json['tags'] as String?,
        pinned: json['pinned'] as bool? ?? false,
        createdAt: json['created_at'] as String? ?? '',
        updatedAt: json['updated_at'] as String? ?? '',
      );

  Note copyWith({
    String? title,
    String? content,
    String? tags,
    bool? pinned,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      pinned: pinned ?? this.pinned,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class Todo {
  final String id;
  final String title;
  final String? description;
  final bool completed;
  final String? dueDate;
  final String createdAt;

  const Todo({
    required this.id,
    required this.title,
    this.description,
    required this.completed,
    this.dueDate,
    required this.createdAt,
  });

  factory Todo.fromJson(Map<String, dynamic> json) => Todo(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        completed: json['completed'] as bool? ?? false,
        dueDate: json['due_date'] as String?,
        createdAt: json['created_at'] as String? ?? '',
      );

  Todo copyWith({bool? completed}) => Todo(
        id: id,
        title: title,
        description: description,
        completed: completed ?? this.completed,
        dueDate: dueDate,
        createdAt: createdAt,
      );
}

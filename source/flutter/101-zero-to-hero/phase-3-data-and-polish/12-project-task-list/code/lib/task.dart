enum Priority { low, normal, high }

class Task {
  const Task({
    required this.id,
    required this.title,
    this.notes = '',
    this.priority = Priority.normal,
    this.done = false,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    final priorityName = json['priority'] as String? ?? 'normal';
    return Task(
      id: json['id'] as int,
      title: json['title'] as String,
      notes: json['notes'] as String? ?? '',
      priority: Priority.values.firstWhere(
        (value) => value.name == priorityName,
        orElse: () => Priority.normal,
      ),
      done: json['done'] as bool? ?? false,
    );
  }

  final int id;
  final String title;
  final String notes;
  final Priority priority;
  final bool done;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'title': title,
      'notes': notes,
      'priority': priority.name,
      'done': done,
    };
  }

  Task copyWith({
    String? title,
    String? notes,
    Priority? priority,
    bool? done,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      priority: priority ?? this.priority,
      done: done ?? this.done,
    );
  }
}

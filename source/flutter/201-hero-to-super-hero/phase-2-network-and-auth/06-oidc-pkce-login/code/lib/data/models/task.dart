enum TaskStatus {
  todo('todo', 'To do'),
  inProgress('in_progress', 'In progress'),
  blocked('blocked', 'Blocked'),
  done('done', 'Done'),
  cancelled('cancelled', 'Cancelled');

  const TaskStatus(this.wire, this.label);

  final String wire;
  final String label;

  static TaskStatus fromWire(String wire) {
    return values.firstWhere(
      (status) => status.wire == wire,
      orElse: () => TaskStatus.todo,
    );
  }
}

enum TaskPriority {
  low,
  medium,
  high,
  urgent;

  static TaskPriority fromWire(String wire) {
    return values.firstWhere(
      (priority) => priority.name == wire,
      orElse: () => TaskPriority.medium,
    );
  }
}

class Task {
  const Task({
    required this.id,
    required this.projectId,
    required this.title,
    this.description = '',
    this.status = TaskStatus.todo,
    this.priority = TaskPriority.medium,
    this.dueDate,
    this.version = 1,
    required this.createdAt,
  });

  final String id;
  final String projectId;
  final String title;
  final String description;
  final TaskStatus status;
  final TaskPriority priority;
  final String? dueDate;
  final int version;
  final DateTime createdAt;

  bool get isDone => status == TaskStatus.done;

  Task copyWith({
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    int? version,
  }) {
    return Task(
      id: id,
      projectId: projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate,
      version: version ?? this.version,
      createdAt: createdAt,
    );
  }
}

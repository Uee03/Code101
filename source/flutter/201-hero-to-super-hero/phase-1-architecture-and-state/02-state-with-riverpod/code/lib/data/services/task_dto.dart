class TaskDto {
  const TaskDto({
    required this.id,
    required this.projectId,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.dueDate,
    required this.version,
    required this.createdAt,
  });

  final String id;
  final String projectId;
  final String title;
  final String description;
  final String status;
  final String priority;
  final String? dueDate;
  final int version;
  final DateTime createdAt;
}

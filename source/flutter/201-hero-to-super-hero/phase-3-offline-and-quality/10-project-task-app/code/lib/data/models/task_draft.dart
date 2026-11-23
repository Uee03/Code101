import 'task.dart';

/// What the person typed in the task form.
class TaskDraft {
  const TaskDraft({
    required this.title,
    this.description = '',
    this.priority = TaskPriority.medium,
    this.dueDate,
  });

  factory TaskDraft.fromTask(Task task) {
    return TaskDraft(
      title: task.title,
      description: task.description,
      priority: task.priority,
      dueDate: task.dueDate,
    );
  }

  final String title;
  final String description;
  final TaskPriority priority;

  /// A date as yyyy-MM-dd, or null for "no due date".
  final String? dueDate;

  /// A JSON Merge Patch (RFC 7396): only the fields that differ from [original].
  /// A key with the value null means "clear this field"; a missing key means "leave it".
  Map<String, Object?> patchFrom(Task original) {
    return {
      if (title != original.title) 'title': title,
      if (description != original.description) 'description': description,
      if (priority != original.priority) 'priority': priority.name,
      if (dueDate != original.dueDate) 'dueDate': dueDate,
    };
  }
}

/// The current value of the named fields of [task], used to undo a discarded edit.
Map<String, Object?> taskFields(Task task, Iterable<String> keys) {
  final all = <String, Object?>{
    'title': task.title,
    'description': task.description,
    'priority': task.priority.name,
    'dueDate': task.dueDate,
  };
  return {for (final key in keys) key: all[key]};
}

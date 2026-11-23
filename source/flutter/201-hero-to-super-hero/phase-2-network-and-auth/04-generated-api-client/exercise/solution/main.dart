// Exercise 04: header and payload rules of the API. Run with: dart run main.dart
import 'dart:convert';

enum Status {
  todo('todo'),
  inProgress('in_progress'),
  done('done');

  const Status(this.wire);

  final String wire;
}

class TaskResponse {
  const TaskResponse(this.id, this.title, this.status, this.version);

  final String id;
  final String title;
  final String status;
  final int version;
}

class Task {
  const Task(this.id, this.title, this.status, this.version);

  final String id;
  final String title;
  final Status status;
  final int version;
}

String ifMatch(int version) {
  return '"$version"';
}

Task toTask(TaskResponse response) {
  final status = Status.values.firstWhere(
    (value) => value.wire == response.status,
    orElse: () => Status.todo,
  );
  return Task(response.id, response.title, status, response.version);
}

Map<String, Object?> mergePatch({
  String? title,
  String? dueDate,
  bool clearDueDate = false,
}) {
  return {
    if (title != null) 'title': title,
    if (dueDate != null) 'dueDate': dueDate,
    if (clearDueDate) 'dueDate': null,
  };
}

void main() {
  print(ifMatch(3));
  print(toTask(const TaskResponse('t1', 'Write notes', 'in_progress', 2)).status.name);
  print(jsonEncode(mergePatch(title: 'New title')));
  print(jsonEncode(mergePatch(clearDueDate: true)));
  print(jsonEncode(mergePatch(title: 'A', dueDate: '2026-12-01')));
}

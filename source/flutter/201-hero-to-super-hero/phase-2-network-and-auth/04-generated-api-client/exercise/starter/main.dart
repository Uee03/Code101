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
  // TODO 1: return the version inside double quotes, for example "3"
  //         (the quote characters are part of the header value)
  return '';
}

Task toTask(TaskResponse response) {
  // TODO 2: build a Task. Find the Status whose wire text equals response.status;
  //         when none matches use Status.todo.
  return Task(response.id, response.title, Status.todo, response.version);
}

Map<String, Object?> mergePatch({
  String? title,
  String? dueDate,
  bool clearDueDate = false,
}) {
  // TODO 3: build the JSON Merge Patch map. Include only the fields that were given.
  //         When clearDueDate is true include 'dueDate' with the value null.
  return {};
}

void main() {
  print(ifMatch(3));
  print(toTask(const TaskResponse('t1', 'Write notes', 'in_progress', 2)).status.name);
  print(jsonEncode(mergePatch(title: 'New title')));
  print(jsonEncode(mergePatch(clearDueDate: true)));
  print(jsonEncode(mergePatch(title: 'A', dueDate: '2026-12-01')));
}

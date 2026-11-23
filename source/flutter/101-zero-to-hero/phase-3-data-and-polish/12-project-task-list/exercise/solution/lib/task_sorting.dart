import 'task.dart';

// Exercise 12: sort the visible tasks.
// Copy this file into lib/ of your task_list project, next to task.dart.
List<Task> sortTasks(List<Task> tasks) {
  final sorted = List.of(tasks);
  sorted.sort((a, b) {
    if (a.done != b.done) {
      return a.done ? 1 : -1;
    }
    final byPriority = b.priority.index.compareTo(a.priority.index);
    if (byPriority != 0) {
      return byPriority;
    }
    return a.title.toLowerCase().compareTo(b.title.toLowerCase());
  });
  return sorted;
}

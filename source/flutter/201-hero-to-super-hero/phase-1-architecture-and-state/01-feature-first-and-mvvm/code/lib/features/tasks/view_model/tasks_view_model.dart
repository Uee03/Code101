import 'package:flutter/foundation.dart';

import '../../../core/result.dart';
import '../../../data/models/task.dart';
import '../../../data/repositories/task_repository.dart';

class TasksViewModel extends ChangeNotifier {
  TasksViewModel({
    required TaskRepository repository,
    required this.projectId,
  }) : _repository = repository;

  final TaskRepository _repository;
  final String projectId;

  List<Task> _tasks = const [];
  bool _loading = false;
  String? _error;

  List<Task> get tasks => _tasks;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    final result = await _repository.loadTasks(projectId);
    switch (result) {
      case Ok(value: final loaded):
        _tasks = loaded;
      case Err(error: final failure):
        _error = failure.toString();
    }
    _loading = false;
    notifyListeners();
  }

  /// Returns null on success, or a message for the view to show.
  Future<String?> add(String title) async {
    final result = await _repository.createTask(projectId, title: title);
    switch (result) {
      case Ok(value: final created):
        _tasks = [created, ..._tasks];
        notifyListeners();
        return null;
      case Err(error: final failure):
        return failure.toString();
    }
  }

  Future<String?> complete(Task task) async {
    final result = await _repository.completeTask(task);
    switch (result) {
      case Ok(value: final updated):
        _tasks = [
          for (final item in _tasks)
            if (item.id == updated.id) updated else item,
        ];
        notifyListeners();
        return null;
      case Err(error: final failure):
        return failure.toString();
    }
  }
}

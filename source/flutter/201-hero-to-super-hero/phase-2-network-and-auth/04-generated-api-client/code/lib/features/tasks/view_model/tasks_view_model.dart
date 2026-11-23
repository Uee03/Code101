import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/result.dart';
import '../../../data/models/task.dart';

final tasksViewModelProvider =
    AsyncNotifierProvider.family<TasksViewModel, List<Task>, String>(
  TasksViewModel.new,
);

class TasksViewModel extends AsyncNotifier<List<Task>> {
  TasksViewModel(this.projectId);

  final String projectId;

  @override
  Future<List<Task>> build() async {
    final result = await ref.watch(taskRepositoryProvider).loadTasks(projectId);
    switch (result) {
      case Ok(value: final tasks):
        return tasks;
      case Err(error: final failure):
        throw failure;
    }
  }

  /// Returns null on success, or a message for the view to show.
  Future<String?> add(String title) async {
    final result = await ref
        .read(taskRepositoryProvider)
        .createTask(projectId, title: title);
    if (!ref.mounted) {
      return null;
    }
    switch (result) {
      case Ok(value: final created):
        state = AsyncData([created, ...state.value ?? const []]);
        return null;
      case Err(error: final failure):
        return failure.toString();
    }
  }

  Future<String?> complete(Task task) async {
    final result = await ref.read(taskRepositoryProvider).completeTask(task);
    if (!ref.mounted) {
      return null;
    }
    switch (result) {
      case Ok(value: final updated):
        state = AsyncData([
          for (final item in state.value ?? const <Task>[])
            if (item.id == updated.id) updated else item,
        ]);
        return null;
      case Err(error: final failure):
        return failure.toString();
    }
  }
}

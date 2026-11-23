import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/result.dart';
import '../../../data/models/task.dart';

/// The list comes from the local database and updates whenever a row changes.
final tasksViewModelProvider =
    StreamNotifierProvider.family<TasksViewModel, List<Task>, String>(
  TasksViewModel.new,
);

/// Asks the server for page 1 and stores it. Its state is only "loading, done or failed".
final tasksRefreshProvider = FutureProvider.autoDispose.family<void, String>((
  ref,
  projectId,
) async {
  final result = await ref.watch(taskRepositoryProvider).refreshTasks(projectId);
  if (result case Err(error: final failure)) {
    throw failure;
  }
});

class TasksViewModel extends StreamNotifier<List<Task>> {
  TasksViewModel(this.projectId);

  final String projectId;

  @override
  Stream<List<Task>> build() {
    return ref.watch(taskRepositoryProvider).watchTasks(projectId);
  }

  /// Saves the task on the phone and asks the sync engine to send it.
  /// Returns null on success, or the failure for the view to describe.
  Future<Object?> add(String title) async {
    final result = await ref
        .read(taskRepositoryProvider)
        .createTask(projectId, title: title);
    if (!ref.mounted) {
      return null;
    }
    switch (result) {
      case Ok():
        unawaited(ref.read(syncEngineProvider).drain());
        return null;
      case Err(error: final failure):
        return failure;
    }
  }

  Future<Object?> complete(Task task) async {
    final result = await ref.read(taskRepositoryProvider).completeTask(task);
    if (!ref.mounted) {
      return null;
    }
    switch (result) {
      case Ok():
        unawaited(ref.read(syncEngineProvider).drain());
        return null;
      case Err(error: final failure):
        return failure;
    }
  }
}

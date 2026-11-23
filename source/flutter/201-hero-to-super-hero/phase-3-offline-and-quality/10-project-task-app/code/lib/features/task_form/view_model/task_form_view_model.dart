import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/result.dart';
import '../../../data/models/task.dart';
import '../../../data/models/task_draft.dart';

final taskFormViewModelProvider = Provider<TaskFormViewModel>(
  TaskFormViewModel.new,
);

class TaskFormViewModel {
  TaskFormViewModel(this._ref);

  final Ref _ref;

  /// Returns null when the task was saved on the phone, or the failure to describe.
  Future<Object?> create(
    String projectId,
    TaskDraft draft, {
    required String requestId,
  }) async {
    final result = await _ref
        .read(taskRepositoryProvider)
        .createTask(projectId, draft, requestId: requestId);
    return _finish(result);
  }

  /// [original] is the task as it was when the form opened: its version goes into If-Match.
  Future<Object?> update(Task original, TaskDraft draft) async {
    final result = await _ref
        .read(taskRepositoryProvider)
        .updateTask(original, draft);
    return _finish(result);
  }

  Object? _finish(Result<void> result) {
    switch (result) {
      case Ok():
        unawaited(_ref.read(syncEngineProvider).drain());
        return null;
      case Err(error: final failure):
        return failure;
    }
  }
}

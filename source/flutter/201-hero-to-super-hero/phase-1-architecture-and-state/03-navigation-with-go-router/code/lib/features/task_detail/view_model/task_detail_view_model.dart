import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/result.dart';
import '../../../data/models/task.dart';

final taskDetailProvider = FutureProvider.family<Task, String>((
  ref,
  taskId,
) async {
  final result = await ref.watch(taskRepositoryProvider).getTask(taskId);
  switch (result) {
    case Ok(value: final task):
      return task;
    case Err(error: final failure):
      throw failure;
  }
});

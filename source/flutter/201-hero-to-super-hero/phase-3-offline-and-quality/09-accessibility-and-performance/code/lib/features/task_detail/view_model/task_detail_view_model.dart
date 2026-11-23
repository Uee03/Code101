import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/result.dart';
import '../../../data/models/task.dart';

/// The task comes from the local database, so a task opened from the list shows at once.
final taskDetailProvider = StreamProvider.autoDispose.family<Task?, String>((
  ref,
  taskId,
) {
  return ref.watch(taskRepositoryProvider).watchTask(taskId);
});

/// Fetches the newest copy from the server and stores it. Failing is not fatal.
final taskDetailRefreshProvider = FutureProvider.autoDispose.family<void, String>((
  ref,
  taskId,
) async {
  final result = await ref.watch(taskRepositoryProvider).refreshTask(taskId);
  if (result case Err(error: final failure)) {
    throw failure;
  }
});

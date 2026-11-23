import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/task_repository.dart';
import '../data/services/fake_task_service.dart';

final taskServiceProvider = Provider<FakeTaskService>(
  (ref) => FakeTaskService(),
);

final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => TaskRepository(ref.watch(taskServiceProvider)),
);

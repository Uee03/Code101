import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/task_repository.dart';
import '../data/services/fake_task_service.dart';

final taskServiceProvider = Provider<FakeTaskService>(
  (ref) => FakeTaskService(),
);

final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => TaskRepository(ref.watch(taskServiceProvider)),
);

/// The project shown after sign-in. Lesson 04 reads it from build configuration.
final defaultProjectIdProvider = Provider<String>((ref) => demoProjectId);

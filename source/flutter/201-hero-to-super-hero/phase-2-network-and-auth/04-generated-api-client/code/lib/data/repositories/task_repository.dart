import 'package:dio/dio.dart' show DioException;
import 'package:uuid/uuid.dart';

import '../../core/result.dart';
import '../generated/tasks_api.dart' as dto;
import '../models/task.dart';
import '../services/api_service.dart';

class TaskRepository {
  TaskRepository(this._api);

  final ApiService _api;

  Future<Result<List<Task>>> loadTasks(String projectId) async {
    try {
      final page = await _api.listTasks(projectId);
      return Ok([for (final item in page.items) _toTask(item)]);
    } on DioException catch (error) {
      return Err(error);
    }
  }

  Future<Result<Task>> getTask(String id) async {
    try {
      return Ok(_toTask(await _api.getTask(id)));
    } on DioException catch (error) {
      return Err(error);
    }
  }

  /// A new key per call: a retry after a timeout could still create a duplicate.
  /// Lesson 08 fixes that by storing the key with the pending write.
  Future<Result<Task>> createTask(
    String projectId, {
    required String title,
    String description = '',
  }) async {
    try {
      final created = await _api.createTask(
        projectId,
        title: title,
        description: description,
        idempotencyKey: const Uuid().v4(),
      );
      return Ok(_toTask(created));
    } on DioException catch (error) {
      return Err(error);
    }
  }

  Future<Result<Task>> completeTask(Task task) async {
    try {
      return Ok(_toTask(await _api.completeTask(task.id, task.version)));
    } on DioException catch (error) {
      return Err(error);
    }
  }

  Task _toTask(dto.Task$Response item) {
    return Task(
      id: item.id,
      projectId: item.projectId,
      title: item.title,
      description: item.description,
      status: TaskStatus.fromWire(item.status.value),
      priority: TaskPriority.fromWire(item.priority.value),
      dueDate: item.dueDate,
      version: item.version,
      createdAt: item.createdAt,
    );
  }
}

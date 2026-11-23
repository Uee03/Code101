import 'package:dio/dio.dart' show DioException;
import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import '../../core/api_problem.dart';
import '../../core/result.dart';
import '../generated/tasks_api.dart' as dto;
import '../local/database.dart';
import '../models/sync_state.dart';
import '../models/task.dart';
import '../services/api_service.dart';
import '../services/task_local_service.dart';

/// Screens read the local database. The network only updates it.
class TaskRepository {
  TaskRepository(this._api, this._local);

  final ApiService _api;
  final TaskLocalService _local;

  Stream<List<Task>> watchTasks(String projectId) {
    return _local
        .watchProject(projectId)
        .map((rows) => [for (final row in rows) _fromRow(row)]);
  }

  Stream<Task?> watchTask(String id) {
    return _local.watchOne(id).map((row) => row == null ? null : _fromRow(row));
  }

  /// Fetches page 1 and stores it. The list on screen changes by itself.
  Future<Result<void>> refreshTasks(String projectId) async {
    try {
      final page = await _api.listTasks(projectId);
      await _local.replaceSynced(projectId, [
        for (final item in page.items) _toCompanion(item),
      ]);
      return const Ok(null);
    } on DioException catch (error) {
      return Err(ApiProblem.of(error));
    }
  }

  Future<Result<void>> refreshTask(String id) async {
    try {
      await _local.upsert(_toCompanion(await _api.getTask(id)));
      return const Ok(null);
    } on DioException catch (error) {
      return Err(ApiProblem.of(error));
    }
  }

  /// Still write-through: the server answers first, then the cache learns.
  /// Lesson 08 replaces this with a local write plus a queued request.
  Future<Result<void>> createTask(
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
      await _local.upsert(_toCompanion(created));
      return const Ok(null);
    } on DioException catch (error) {
      return Err(ApiProblem.of(error));
    }
  }

  Future<Result<void>> completeTask(Task task) async {
    try {
      final done = await _api.completeTask(task.id, task.version);
      await _local.upsert(_toCompanion(done));
      return const Ok(null);
    } on DioException catch (error) {
      return Err(ApiProblem.of(error));
    }
  }

  Future<void> clearLocal() => _local.clearAll();

  Task _fromRow(TaskRow row) {
    return Task(
      id: row.id,
      projectId: row.projectId,
      title: row.title,
      description: row.description,
      status: TaskStatus.fromWire(row.status),
      priority: TaskPriority.fromWire(row.priority),
      dueDate: row.dueDate,
      version: row.version,
      createdAt: row.createdAt,
      syncState: SyncState.fromName(row.syncState),
    );
  }

  TasksCompanion _toCompanion(dto.Task$Response item) {
    return TasksCompanion.insert(
      id: item.id,
      projectId: item.projectId,
      title: item.title,
      status: item.status.value,
      priority: item.priority.value,
      createdAt: item.createdAt,
      description: Value(item.description),
      dueDate: Value(item.dueDate),
      version: Value(item.version),
      syncState: Value(SyncState.synced.name),
    );
  }
}

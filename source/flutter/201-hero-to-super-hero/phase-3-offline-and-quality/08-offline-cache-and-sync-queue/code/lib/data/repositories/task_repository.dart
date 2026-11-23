import 'dart:convert';

import 'package:dio/dio.dart' show DioException;
import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import '../../core/api_problem.dart';
import '../../core/result.dart';
import '../local/database.dart';
import '../models/outbox_types.dart';
import '../models/sync_state.dart';
import '../models/task.dart';
import '../models/task_mapper.dart';
import '../services/api_service.dart';
import '../services/task_local_service.dart';
import '../sync/outbox_dao.dart';

/// Screens read the local database. A write changes the database and the queue in one
/// transaction; the sync engine delivers it later.
class TaskRepository {
  TaskRepository(this._api, this._local, this._outbox, this._db);

  final ApiService _api;
  final TaskLocalService _local;
  final OutboxDao _outbox;
  final AppDatabase _db;

  Stream<List<Task>> watchTasks(String projectId) {
    return _local
        .watchProject(projectId)
        .map((rows) => [for (final row in rows) TaskMapper.fromRow(row)]);
  }

  Stream<Task?> watchTask(String id) {
    return _local
        .watchOne(id)
        .map((row) => row == null ? null : TaskMapper.fromRow(row));
  }

  /// Fetches page 1 and stores it. The list on screen changes by itself.
  Future<Result<void>> refreshTasks(String projectId) async {
    try {
      final page = await _api.listTasks(projectId);
      await _local.replaceSynced(projectId, [
        for (final item in page.items) TaskMapper.toCompanion(item),
      ]);
      return const Ok(null);
    } on DioException catch (error) {
      return Err(ApiProblem.of(error));
    }
  }

  Future<Result<void>> refreshTask(String id) async {
    try {
      final existing = await _local.find(id);
      if (existing != null && existing.syncState != SyncState.synced.name) {
        // The phone holds a newer change than the server: do not overwrite it.
        return const Ok(null);
      }
      await _local.upsert(TaskMapper.toCompanion(await _api.getTask(id)));
      return const Ok(null);
    } on DioException catch (error) {
      return Err(ApiProblem.of(error));
    }
  }

  /// Works offline. The task gets a local id; the queue row id doubles as the Idempotency-Key.
  Future<Result<void>> createTask(
    String projectId, {
    required String title,
    String description = '',
  }) async {
    final now = DateTime.now();
    try {
      await _db.transaction(() async {
        final localId = const Uuid().v4();
        await _local.upsert(
          TasksCompanion.insert(
            id: localId,
            projectId: projectId,
            title: title,
            status: TaskStatus.todo.wire,
            priority: TaskPriority.medium.name,
            createdAt: now,
            description: Value(description),
            syncState: Value(SyncState.pending.name),
          ),
        );
        await _outbox.insert(
          OutboxCompanion.insert(
            id: const Uuid().v4(),
            kind: OutboxKind.createTask.wire,
            entityId: localId,
            payload: jsonEncode({
              'projectId': projectId,
              'title': title,
              'description': description,
            }),
            createdAt: now.millisecondsSinceEpoch,
          ),
        );
      });
      return const Ok(null);
    } on Exception catch (error) {
      return Err(error);
    }
  }

  Future<Result<void>> completeTask(Task task) async {
    try {
      await _db.transaction(() async {
        await _local.setStatus(task.id, TaskStatus.done, SyncState.pending);
        await _outbox.insert(
          OutboxCompanion.insert(
            id: const Uuid().v4(),
            kind: OutboxKind.completeTask.wire,
            entityId: task.id,
            payload: jsonEncode({'previousStatus': task.status.wire}),
            baseVersion: Value(task.version),
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
      });
      return const Ok(null);
    } on Exception catch (error) {
      return Err(error);
    }
  }

  /// "Retry now" on the queue screen.
  Future<void> retryQueued(OutboxRow row) {
    return _db.transaction(() async {
      await _outbox.reset(row.seq);
      await _local.setSyncState(row.entityId, SyncState.pending);
    });
  }

  /// Throws away this queued write and every later one about the same task,
  /// because the later ones only make sense on top of this one.
  Future<void> discardQueued(OutboxRow row) {
    return _db.transaction(() async {
      final chain = await _outbox.forEntity(row.entityId);
      for (final item in chain.where((queued) => queued.seq >= row.seq)) {
        await _outbox.delete(item.seq);
      }
      if (row.kind == OutboxKind.createTask.wire) {
        await _local.delete(row.entityId);
        return;
      }
      final payload = jsonDecode(row.payload) as Map<String, Object?>;
      final previous = TaskStatus.fromWire(
        payload['previousStatus'] as String? ?? TaskStatus.todo.wire,
      );
      await _local.setStatus(row.entityId, previous, SyncState.synced);
    });
  }

  Future<void> clearLocal() => _local.clearAll();
}

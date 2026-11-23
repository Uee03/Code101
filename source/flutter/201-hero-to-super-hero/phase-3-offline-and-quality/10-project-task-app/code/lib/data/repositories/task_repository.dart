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
import '../models/task_draft.dart';
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

  /// Works offline. [requestId] is made when the form opens and is used twice: as the local
  /// task id and as the queue row id, which the server receives as the Idempotency-Key.
  /// Saving twice with the same [requestId] changes nothing the second time.
  Future<Result<void>> createTask(
    String projectId,
    TaskDraft draft, {
    required String requestId,
  }) async {
    final now = DateTime.now();
    try {
      await _db.transaction(() async {
        await _local.upsert(
          TasksCompanion.insert(
            id: requestId,
            projectId: projectId,
            title: draft.title,
            status: TaskStatus.todo.wire,
            priority: draft.priority.name,
            createdAt: now,
            description: Value(draft.description),
            dueDate: Value(draft.dueDate),
            syncState: Value(SyncState.pending.name),
          ),
        );
        await _outbox.insert(
          OutboxCompanion.insert(
            id: requestId,
            kind: OutboxKind.createTask.wire,
            entityId: requestId,
            payload: jsonEncode({
              'projectId': projectId,
              'title': draft.title,
              'description': draft.description,
              'priority': draft.priority.name,
              'dueDate': draft.dueDate,
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

  /// Edits [original] (the task as it was when the form opened). The queued request will
  /// send If-Match with original.version and a merge patch with only the changed fields.
  Future<Result<void>> updateTask(Task original, TaskDraft edited) async {
    final patch = edited.patchFrom(original);
    if (patch.isEmpty) {
      return const Ok(null);
    }
    try {
      await _db.transaction(() async {
        await _local.applyPatch(original.id, patch, SyncState.pending);
        await _queueEdit(original, patch);
      });
      return const Ok(null);
    } on Exception catch (error) {
      return Err(error);
    }
  }

  /// Rule 2 of the design: an edit joins a write that has not been picked up yet.
  Future<void> _queueEdit(Task original, Map<String, Object?> patch) async {
    final create = await _outbox.pendingOfKind(
      original.id,
      OutboxKind.createTask,
    );
    if (create != null) {
      final payload = _decode(create.payload)..addAll(patch);
      await _outbox.replacePayload(create.seq, jsonEncode(payload));
      return;
    }
    final update = await _outbox.pendingOfKind(
      original.id,
      OutboxKind.updateTask,
    );
    if (update != null) {
      final payload = _decode(update.payload);
      final merged = {
        ...Map<String, Object?>.from(payload['patch']! as Map),
        ...patch,
      };
      // The oldest value of each field wins in "before", so a discard goes back to the start.
      final before = {
        ...taskFields(original, patch.keys),
        ...Map<String, Object?>.from(payload['before']! as Map),
      };
      await _outbox.replacePayload(
        update.seq,
        jsonEncode({'patch': merged, 'before': before}),
      );
      return;
    }
    await _outbox.insert(
      OutboxCompanion.insert(
        id: const Uuid().v4(),
        kind: OutboxKind.updateTask.wire,
        entityId: original.id,
        payload: jsonEncode({
          'patch': patch,
          'before': taskFields(original, patch.keys),
        }),
        baseVersion: Value(original.version),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
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

  /// "Retry now" and "Keep mine" on the queue screen. After a conflict the server copy
  /// is read first, so the retry is sent on top of the version that won.
  Future<Result<void>> retryQueued(OutboxRow row) async {
    try {
      int? serverVersion;
      if (row.state == OutboxState.conflict.wire &&
          row.kind != OutboxKind.createTask.wire) {
        serverVersion = (await _api.getTask(row.entityId)).version;
      }
      await _db.transaction(() async {
        if (serverVersion != null) {
          await _outbox.setRowBaseVersion(row.seq, serverVersion);
        }
        await _outbox.reset(row.seq);
        await _local.setSyncState(row.entityId, SyncState.pending);
      });
      return const Ok(null);
    } on DioException catch (error) {
      return Err(ApiProblem.of(error));
    }
  }

  /// "Discard" and "Take theirs": throws away this queued write and every later one about
  /// the same task (they only make sense on top of it), then puts the old values back.
  Future<void> discardQueued(OutboxRow row) async {
    await _db.transaction(() async {
      final chain = await _outbox.forEntity(row.entityId);
      for (final item in chain.where((queued) => queued.seq >= row.seq)) {
        await _outbox.delete(item.seq);
      }
      await _restore(row);
    });
    if (row.kind != OutboxKind.createTask.wire) {
      await refreshTask(row.entityId);
    }
  }

  Future<void> _restore(OutboxRow row) async {
    final payload = _decode(row.payload);
    switch (OutboxKind.fromWire(row.kind)) {
      case OutboxKind.createTask:
        await _local.delete(row.entityId);
      case OutboxKind.updateTask:
        final before = Map<String, Object?>.from(payload['before']! as Map);
        await _local.applyPatch(row.entityId, before, SyncState.synced);
      case OutboxKind.completeTask:
        final previous = TaskStatus.fromWire(
          payload['previousStatus'] as String? ?? TaskStatus.todo.wire,
        );
        await _local.setStatus(row.entityId, previous, SyncState.synced);
    }
  }

  Map<String, Object?> _decode(String json) {
    return Map<String, Object?>.from(jsonDecode(json) as Map);
  }

  Future<void> clearLocal() => _local.clearAll();
}

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart' show DioException;

import '../../core/api_problem.dart';
import '../generated/tasks_api.dart' as dto;
import '../local/database.dart';
import '../models/outbox_types.dart';
import '../models/sync_state.dart';
import '../models/task.dart';
import '../models/task_mapper.dart';
import '../services/api_service.dart';
import '../services/task_local_service.dart';
import 'backoff.dart';
import 'outbox_dao.dart';

/// Sends the queued writes to the server, oldest first, one task at a time.
/// It sits above the repositories: they write the queue, this class empties it.
class SyncEngine {
  SyncEngine({
    required AppDatabase db,
    required OutboxDao outbox,
    required TaskLocalService tasks,
    required ApiService api,
    required bool Function() canSync,
    Random? random,
  })  : _db = db,
        _outbox = outbox,
        _tasks = tasks,
        _api = api,
        _canSync = canSync,
        _random = random ?? Random();

  final AppDatabase _db;
  final OutboxDao _outbox;
  final TaskLocalService _tasks;
  final ApiService _api;
  final bool Function() _canSync;
  final Random _random;

  bool _running = false;
  bool _again = false;
  bool _recovered = false;
  Timer? _timer;

  /// Call once the person is signed in. The first call also rescues rows that a crash left in flight.
  Future<void> start() async {
    if (!_recovered) {
      _recovered = true;
      await _outbox.resetInFlight();
    }
    await drain();
  }

  /// Sends everything that is due. A call made while a drain runs only asks for another round.
  Future<void> drain() async {
    if (_running) {
      _again = true;
      return;
    }
    _running = true;
    try {
      do {
        _again = false;
        await _drainOnce();
      } while (_again);
    } finally {
      _running = false;
    }
    await _scheduleNext();
  }

  void dispose() {
    _timer?.cancel();
  }

  Future<void> _drainOnce() async {
    if (!_canSync()) {
      return;
    }
    while (true) {
      final row = await _outbox.nextDue(_nowMs());
      if (row == null) {
        return;
      }
      final keepGoing = await _send(row);
      if (!keepGoing) {
        return;
      }
    }
  }

  /// Returns false when sending should stop for now (no network, server trouble, signed out).
  Future<bool> _send(OutboxRow row) async {
    await _outbox.markInFlight(row.seq);
    try {
      final server = await _call(row);
      await _accept(row, server);
      return true;
    } on DioException catch (error) {
      return _handleFailure(row, ApiProblem.of(error));
    }
  }

  Future<dto.Task$Response> _call(OutboxRow row) {
    final payload = _decode(row.payload);
    switch (OutboxKind.fromWire(row.kind)) {
      case OutboxKind.createTask:
        final body = {...payload}..remove('projectId');
        return _api.createTask(
          payload['projectId']! as String,
          body: body,
          idempotencyKey: row.id,
        );
      case OutboxKind.updateTask:
        return _api.updateTask(
          row.entityId,
          row.baseVersion ?? 1,
          Map<String, Object?>.from(payload['patch']! as Map),
        );
      case OutboxKind.completeTask:
        return _api.completeTask(row.entityId, row.baseVersion ?? 1);
    }
  }

  /// One transaction: the server copy goes in, the queue row goes out, and the writes
  /// that are still queued for the same task are drawn on top again.
  Future<void> _accept(OutboxRow row, dto.Task$Response server) {
    return _db.transaction(() async {
      if (row.entityId != server.id) {
        // A create got its real id: forget the local id, point later writes at the new one.
        await _tasks.delete(row.entityId);
        await _outbox.moveEntity(row.entityId, server.id);
      }
      await _outbox.delete(row.seq);
      await _outbox.setBaseVersion(server.id, server.version);
      final later = await _outbox.forEntity(server.id);
      await _tasks.upsert(
        TaskMapper.toCompanion(
          server,
          syncState: later.isEmpty ? SyncState.synced : SyncState.pending,
        ),
      );
      for (final item in later) {
        await _overlay(server.id, item);
      }
    });
  }

  Future<void> _overlay(String taskId, OutboxRow item) async {
    switch (OutboxKind.fromWire(item.kind)) {
      case OutboxKind.createTask:
        break;
      case OutboxKind.updateTask:
        final patch = Map<String, Object?>.from(
          _decode(item.payload)['patch']! as Map,
        );
        await _tasks.applyPatch(taskId, patch, SyncState.pending);
      case OutboxKind.completeTask:
        await _tasks.setStatus(taskId, TaskStatus.done, SyncState.pending);
    }
  }

  Future<bool> _handleFailure(OutboxRow row, ApiProblem problem) async {
    final now = _nowMs();
    if (problem.status == 401) {
      // The session ended. The write stays; signing in starts the engine again.
      await _outbox.scheduleRetry(
        row.seq,
        attempts: row.attempts,
        nextAttemptAt: now + 30000,
        problemType: problem.kind,
      );
      return false;
    }
    if (problem.retryable) {
      final attempts = row.attempts + 1;
      final wait = backoffDelay(
        attempts,
        _random.nextDouble(),
        retryAfter: problem.retryAfter,
      );
      await _outbox.scheduleRetry(
        row.seq,
        attempts: attempts,
        nextAttemptAt: now + wait.inMilliseconds,
        problemType: problem.kind,
      );
      return false;
    }
    final conflict = problem.status == 412 || problem.status == 409;
    await _db.transaction(() async {
      await _outbox.park(
        row.seq,
        conflict ? OutboxState.conflict : OutboxState.failed,
        problem.kind,
      );
      await _tasks.setSyncState(
        row.entityId,
        conflict ? SyncState.conflict : SyncState.failed,
      );
    });
    return true;
  }

  /// Wakes the engine when the soonest backoff time arrives.
  Future<void> _scheduleNext() async {
    _timer?.cancel();
    final next = await _outbox.earliestRetryAfter(_nowMs());
    if (next == null) {
      return;
    }
    final wait = max(next - _nowMs(), 0) + 50;
    _timer = Timer(Duration(milliseconds: wait), () => unawaited(drain()));
  }

  Map<String, Object?> _decode(String json) {
    return Map<String, Object?>.from(jsonDecode(json) as Map);
  }

  int _nowMs() => DateTime.now().millisecondsSinceEpoch;
}

import 'package:drift/drift.dart';

import '../local/database.dart';
import '../models/outbox_types.dart';

/// A queued write plus the title of the task it is about, for the queue screen.
class QueueEntry {
  const QueueEntry(this.row, this.taskTitle);

  final OutboxRow row;
  final String? taskTitle;
}

/// Every query on the outbox table. The sync engine and the repository use it.
class OutboxDao {
  OutboxDao(this._db);

  final AppDatabase _db;

  Future<void> insert(OutboxCompanion row) {
    return _db.into(_db.outbox).insert(row);
  }

  /// How many writes the server has not accepted yet, whatever their state.
  Stream<int> watchCount() {
    final count = _db.outbox.seq.count();
    final query = _db.selectOnly(_db.outbox)..addColumns([count]);
    return query.map((row) => row.read(count) ?? 0).watchSingle();
  }

  Stream<List<QueueEntry>> watchEntries() {
    final query = _db.select(_db.outbox).join([
      leftOuterJoin(_db.tasks, _db.tasks.id.equalsExp(_db.outbox.entityId)),
    ])
      ..orderBy([OrderingTerm.asc(_db.outbox.seq)]);
    return query.watch().map(
          (rows) => [
            for (final row in rows)
              QueueEntry(
                row.readTable(_db.outbox),
                row.readTableOrNull(_db.tasks)?.title,
              ),
          ],
        );
  }

  Future<List<OutboxRow>> forEntity(String entityId) {
    final query = _db.select(_db.outbox)
      ..where((o) => o.entityId.equals(entityId))
      ..orderBy([(o) => OrderingTerm.asc(o.seq)]);
    return query.get();
  }

  /// The oldest row that may be sent now. A row that cannot go yet (waiting for its retry
  /// time, in flight, failed, in conflict) blocks every later row of the same task,
  /// so the writes of one task always arrive in the order they were made.
  Future<OutboxRow?> nextDue(int nowMs) async {
    final query = _db.select(_db.outbox)
      ..orderBy([(o) => OrderingTerm.asc(o.seq)]);
    final blocked = <String>{};
    for (final row in await query.get()) {
      final ready = row.state == OutboxState.pending.wire &&
          row.nextAttemptAt <= nowMs;
      if (ready && !blocked.contains(row.entityId)) {
        return row;
      }
      blocked.add(row.entityId);
    }
    return null;
  }

  /// The soonest retry time that lies in the future, or null when nothing waits.
  Future<int?> earliestRetryAfter(int nowMs) async {
    final soonest = _db.outbox.nextAttemptAt.min();
    final query = _db.selectOnly(_db.outbox)
      ..addColumns([soonest])
      ..where(
        _db.outbox.state.equals(OutboxState.pending.wire) &
            _db.outbox.nextAttemptAt.isBiggerThanValue(nowMs),
      );
    return query.map((row) => row.read(soonest)).getSingle();
  }

  Future<void> markInFlight(int seq) {
    return _write(seq, OutboxCompanion(state: Value(OutboxState.inFlight.wire)));
  }

  /// Back to pending with a later retry time. [problemType] is the last problem kind.
  Future<void> scheduleRetry(
    int seq, {
    required int attempts,
    required int nextAttemptAt,
    required String problemType,
  }) {
    return _write(
      seq,
      OutboxCompanion(
        state: Value(OutboxState.pending.wire),
        attempts: Value(attempts),
        nextAttemptAt: Value(nextAttemptAt),
        lastProblemType: Value(problemType),
      ),
    );
  }

  /// Stops retrying: the row waits for the person to retry or discard it.
  Future<void> park(int seq, OutboxState state, String problemType) {
    return _write(
      seq,
      OutboxCompanion(
        state: Value(state.wire),
        lastProblemType: Value(problemType),
      ),
    );
  }

  /// "Retry now": pending again, no waiting, attempts counted from zero.
  Future<void> reset(int seq) {
    return _write(
      seq,
      OutboxCompanion(
        state: Value(OutboxState.pending.wire),
        attempts: const Value(0),
        nextAttemptAt: const Value(0),
        lastProblemType: const Value(null),
      ),
    );
  }

  /// After a crash a row can be stuck "in flight". Sending it again is safe because
  /// a create carries the same Idempotency-Key.
  Future<void> resetInFlight() {
    final query = _db.update(_db.outbox)
      ..where((o) => o.state.equals(OutboxState.inFlight.wire));
    return query.write(
      OutboxCompanion(state: Value(OutboxState.pending.wire)),
    );
  }

  Future<void> setBaseVersion(String entityId, int version) {
    final query = _db.update(_db.outbox)
      ..where((o) => o.entityId.equals(entityId));
    return query.write(OutboxCompanion(baseVersion: Value(version)));
  }

  /// A created task gets its server id: later writes about it must use the new id.
  Future<void> moveEntity(String fromId, String toId) {
    final query = _db.update(_db.outbox)
      ..where((o) => o.entityId.equals(fromId));
    return query.write(OutboxCompanion(entityId: Value(toId)));
  }

  Future<void> delete(int seq) {
    return (_db.delete(_db.outbox)..where((o) => o.seq.equals(seq))).go();
  }

  Future<void> _write(int seq, OutboxCompanion values) {
    final query = _db.update(_db.outbox)..where((o) => o.seq.equals(seq));
    return query.write(values);
  }
}

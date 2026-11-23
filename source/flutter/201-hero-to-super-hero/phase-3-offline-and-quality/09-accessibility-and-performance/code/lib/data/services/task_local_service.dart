import 'package:drift/drift.dart';

import '../local/database.dart';
import '../models/sync_state.dart';
import '../models/task.dart';

/// The only file that runs queries on the tasks table. It returns drift rows.
class TaskLocalService {
  TaskLocalService(this._db);

  final AppDatabase _db;

  Stream<List<TaskRow>> watchProject(String projectId) {
    final query = _db.select(_db.tasks)
      ..where((t) => t.projectId.equals(projectId))
      ..orderBy([
        (t) => OrderingTerm.desc(t.createdAt),
        (t) => OrderingTerm.desc(t.id),
      ]);
    return query.watch();
  }

  Stream<TaskRow?> watchOne(String id) {
    final query = _db.select(_db.tasks)..where((t) => t.id.equals(id));
    return query.watchSingleOrNull();
  }

  Future<TaskRow?> find(String id) {
    final query = _db.select(_db.tasks)..where((t) => t.id.equals(id));
    return query.getSingleOrNull();
  }

  Future<void> upsert(TasksCompanion row) {
    return _db.into(_db.tasks).insertOnConflictUpdate(row);
  }

  Future<void> setStatus(String id, TaskStatus status, SyncState syncState) {
    final query = _db.update(_db.tasks)..where((t) => t.id.equals(id));
    return query.write(
      TasksCompanion(
        status: Value(status.wire),
        syncState: Value(syncState.name),
      ),
    );
  }

  Future<void> setSyncState(String id, SyncState syncState) {
    final query = _db.update(_db.tasks)..where((t) => t.id.equals(id));
    return query.write(TasksCompanion(syncState: Value(syncState.name)));
  }

  Future<void> delete(String id) {
    return (_db.delete(_db.tasks)..where((t) => t.id.equals(id))).go();
  }

  /// Pull-to-refresh rule: the server owns the synced rows, so replace them.
  /// A row that waits to sync is never touched.
  Future<void> replaceSynced(String projectId, List<TasksCompanion> rows) {
    final synced = SyncState.synced.name;
    return _db.transaction(() async {
      final waiting = await (_db.select(_db.tasks)
            ..where((t) => t.syncState.equals(synced).not()))
          .map((row) => row.id)
          .get();
      await (_db.delete(_db.tasks)
            ..where(
              (t) => t.projectId.equals(projectId) & t.syncState.equals(synced),
            ))
          .go();
      await _db.batch((batch) {
        batch.insertAllOnConflictUpdate(_db.tasks, [
          for (final row in rows)
            if (!waiting.contains(row.id.value)) row,
        ]);
      });
    });
  }

  Future<void> clearAll() => _db.clearAll();
}

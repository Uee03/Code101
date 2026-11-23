import 'package:drift/drift.dart' show Value;

import '../generated/tasks_api.dart' as dto;
import '../local/database.dart';
import 'sync_state.dart';
import 'task.dart';

/// Converts between the three shapes of a task: generated DTO, database row, domain model.
abstract final class TaskMapper {
  static Task fromRow(TaskRow row) {
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

  static TasksCompanion toCompanion(
    dto.Task$Response item, {
    SyncState syncState = SyncState.synced,
  }) {
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
      syncState: Value(syncState.name),
    );
  }
}

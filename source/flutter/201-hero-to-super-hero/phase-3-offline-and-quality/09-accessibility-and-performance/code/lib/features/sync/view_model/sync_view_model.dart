import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/api_problem.dart';
import '../../../core/problem_messages.dart';
import '../../../data/local/database.dart';
import '../../../data/models/outbox_types.dart';
import '../../../data/sync/outbox_dao.dart';

/// What the queue screen shows for one queued write.
class QueueLine {
  const QueueLine({
    required this.row,
    required this.title,
    required this.kind,
    required this.status,
  });

  final OutboxRow row;
  final String title;
  final String kind;
  final String status;
}

final syncQueueProvider = StreamProvider.autoDispose<List<QueueLine>>((ref) {
  return ref.watch(outboxDaoProvider).watchEntries().map(
        (entries) => [for (final entry in entries) _toLine(entry)],
      );
});

QueueLine _toLine(QueueEntry entry) {
  final row = entry.row;
  return QueueLine(
    row: row,
    title: entry.taskTitle ?? 'A task that is no longer on this phone',
    kind: OutboxKind.fromWire(row.kind).label,
    status: _status(row),
  );
}

String _status(OutboxRow row) {
  switch (OutboxState.fromWire(row.state)) {
    case OutboxState.pending:
      if (row.attempts == 0) {
        return 'Waiting to be sent.';
      }
      return 'Waiting to try again (attempt ${row.attempts + 1}). '
          '${_problem(row)}';
    case OutboxState.inFlight:
      return 'Sending now.';
    case OutboxState.failed:
      return 'The server refused it. ${_problem(row)}';
    case OutboxState.conflict:
      return 'Someone changed this task first. ${_problem(row)}';
  }
}

/// Only the problem kind is stored, so the message is built from it again.
String _problem(OutboxRow row) {
  final kind = row.lastProblemType;
  if (kind == null) {
    return '';
  }
  return problemMessage(
    ApiProblem(type: kind, title: 'The request failed.', status: 0),
  );
}

final syncViewModelProvider = Provider<SyncViewModel>(SyncViewModel.new);

class SyncViewModel {
  SyncViewModel(this._ref);

  final Ref _ref;

  Future<void> retry(OutboxRow row) async {
    await _ref.read(taskRepositoryProvider).retryQueued(row);
    await _ref.read(syncEngineProvider).drain();
  }

  Future<void> discard(OutboxRow row) {
    return _ref.read(taskRepositoryProvider).discardQueued(row);
  }

  Future<void> syncNow() => _ref.read(syncEngineProvider).drain();
}

import 'package:material_ui/material_ui.dart';

import '../../../data/models/sync_state.dart';
import '../../../data/models/task.dart';

/// One row of the task list. It is a separate widget so the list builder can keep and reuse it.
class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.onOpen,
    required this.onComplete,
  });

  final Task task;
  final VoidCallback onOpen;
  final VoidCallback onComplete;

  /// Status is always words. The sync state is added as words too, never only a colour.
  String get _subtitle {
    switch (task.syncState) {
      case SyncState.synced:
        return task.status.label;
      case SyncState.pending:
        return '${task.status.label}, waiting to sync';
      case SyncState.conflict:
        return '${task.status.label}, changed elsewhere (see the queue)';
      case SyncState.failed:
        return '${task.status.label}, not sent (see the queue)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: Text(task.title),
          subtitle: Text(_subtitle),
          onTap: onOpen,
        ),
        if (!task.isDone)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: TextButton(
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: onComplete,
              // Without the label a screen reader says "Complete" for every row.
              child: Text('Complete', semanticsLabel: 'Complete ${task.title}'),
            ),
          ),
        const Divider(height: 1),
      ],
    );
  }
}

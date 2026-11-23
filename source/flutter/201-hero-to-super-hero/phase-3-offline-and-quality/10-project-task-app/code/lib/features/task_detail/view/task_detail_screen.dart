import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/problem_messages.dart';
import '../../../data/models/sync_state.dart';
import '../../../data/models/task.dart';
import '../view_model/task_detail_view_model.dart';

class TaskDetailScreen extends ConsumerWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final task = ref.watch(taskDetailProvider(taskId));
    final refresh = ref.watch(taskDetailRefreshProvider(taskId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task'),
        actions: [
          if (task.value != null)
            TextButton(
              onPressed: () => context.push(
                '/tasks/${Uri.encodeComponent(taskId)}/edit',
              ),
              child: const Text('Edit'),
            ),
        ],
      ),
      body: task.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            const _Message('The saved task could not be read.'),
        data: (item) {
          if (item != null) {
            return _TaskBody(
              item: item,
              refreshNote: refresh.hasError && !refresh.isLoading
                  ? 'Showing the saved copy. ${describeError(refresh.error!)}'
                  : null,
            );
          }
          return refresh.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => _Message(describeError(error)),
            data: (_) => const _Message('That task is not available.'),
          );
        },
      ),
    );
  }
}

class _TaskBody extends StatelessWidget {
  const _TaskBody({required this.item, this.refreshNote});

  final Task item;
  final String? refreshNote;

  String get _syncText {
    switch (item.syncState) {
      case SyncState.synced:
        return 'On the server';
      case SyncState.pending:
        return 'Waiting to sync';
      case SyncState.conflict:
        return 'Changed elsewhere, see the sync queue';
      case SyncState.failed:
        return 'Not sent, see the sync queue';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (refreshNote != null) ...[
          Semantics(liveRegion: true, child: Text(refreshNote!)),
          const SizedBox(height: 12),
        ],
        // header: a screen reader user can jump from heading to heading.
        Semantics(
          header: true,
          child: Text(
            item.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: 8),
        _Field('Status', item.status.label),
        _Field('Priority', item.priority.name),
        _Field('Due', item.dueDate ?? 'no due date'),
        _Field('Sync', _syncText),
        _Field('Version', '${item.version}'),
        const SizedBox(height: 16),
        _Field(
          'Description',
          item.description.isEmpty ? 'No description.' : item.description,
        ),
      ],
    );
  }
}

/// A label and a value. MergeSemantics makes a screen reader say them as one item.
class _Field extends StatelessWidget {
  const _Field(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final styles = Theme.of(context).textTheme;
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: styles.labelMedium),
            Text(value, style: styles.bodyLarge),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(text, textAlign: TextAlign.center),
      ),
    );
  }
}

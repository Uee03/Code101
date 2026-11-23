import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/problem_messages.dart';
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
      appBar: AppBar(title: const Text('Task')),
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

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (refreshNote != null) ...[
          Text(refreshNote!),
          const SizedBox(height: 12),
        ],
        Text(item.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text('Status: ${item.status.label}'),
        Text('Priority: ${item.priority.name}'),
        Text('Due: ${item.dueDate ?? 'no due date'}'),
        Text('Version: ${item.version}'),
        const SizedBox(height: 16),
        Text(item.description.isEmpty ? 'No description.' : item.description),
      ],
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

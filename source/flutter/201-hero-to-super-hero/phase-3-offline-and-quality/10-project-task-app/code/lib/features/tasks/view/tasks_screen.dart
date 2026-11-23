import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/problem_messages.dart';
import '../../../core/widgets/refresh_status.dart';
import '../view_model/tasks_view_model.dart';
import 'task_tile.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key, required this.projectId});

  final String projectId;

  /// Waits for a view model command and shows its failure message, if any.
  Future<void> _run(BuildContext context, Future<Object?> command) async {
    final failure = await command;
    if (failure == null || !context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(describeError(failure))),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = tasksViewModelProvider(projectId);
    final refresh = tasksRefreshProvider(projectId);
    final tasks = ref.watch(provider);
    final viewModel = ref.read(provider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Tasks')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(
          '/projects/${Uri.encodeComponent(projectId)}/tasks/new',
        ),
        label: const Text('New task'),
      ),
      body: Column(
        children: [
          RefreshStatus(
            refresh: refresh,
            onRetry: () => ref.invalidate(refresh),
          ),
          Expanded(
            child: tasks.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'The saved tasks could not be read.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return EmptyMessage(refresh: refresh, text: 'No tasks yet.');
                }
                return ListView.builder(
                  // Room below the last task so the button never covers it.
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: items.length,
                  // A task keeps its widget (and its state) when the list reorders.
                  findChildIndexCallback: (key) {
                    if (key is! ValueKey<String>) {
                      return null;
                    }
                    final index = items.indexWhere((t) => t.id == key.value);
                    return index == -1 ? null : index;
                  },
                  itemBuilder: (context, index) {
                    final task = items[index];
                    return TaskTile(
                      key: ValueKey(task.id),
                      task: task,
                      onOpen: () => context.push(
                        '/tasks/${Uri.encodeComponent(task.id)}',
                      ),
                      onComplete: () =>
                          _run(context, viewModel.complete(task)),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

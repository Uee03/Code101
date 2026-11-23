import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/problem_messages.dart';
import '../view_model/tasks_view_model.dart';

/// The progress bar and the "could not refresh" line. Both watch only the one value they
/// draw (`select`), so the task list does not rebuild when the refresh starts or ends.
class RefreshStatus extends ConsumerWidget {
  const RefreshStatus({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = tasksRefreshProvider(projectId);
    final loading = ref.watch(provider.select((state) => state.isLoading));
    final error = ref.watch(
      provider.select((state) => state.isLoading ? null : state.error),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (loading)
          const LinearProgressIndicator(semanticsLabel: 'Refreshing tasks'),
        if (error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // A live region: a screen reader announces the failure when it appears.
                Semantics(
                  liveRegion: true,
                  child: Text('Could not refresh. ${describeError(error)}'),
                ),
                TextButton(
                  onPressed: () => ref.invalidate(provider),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The text shown when the list is empty. It says "loading" only while a refresh runs.
class EmptyTasksMessage extends ConsumerWidget {
  const EmptyTasksMessage({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loading = ref.watch(
      tasksRefreshProvider(projectId).select((state) => state.isLoading),
    );
    return Center(child: Text(loading ? 'Loading tasks...' : 'No tasks yet.'));
  }
}

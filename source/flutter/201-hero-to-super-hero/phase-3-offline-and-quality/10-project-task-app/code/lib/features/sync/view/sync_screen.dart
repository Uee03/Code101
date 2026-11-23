import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/problem_messages.dart';
import '../view_model/sync_view_model.dart';

class SyncScreen extends ConsumerWidget {
  const SyncScreen({super.key});

  Future<void> _retry(
    BuildContext context,
    SyncViewModel viewModel,
    QueueLine line,
  ) async {
    final failure = await viewModel.retry(line.row);
    if (failure == null || !context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(describeError(failure))),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lines = ref.watch(syncQueueProvider);
    final viewModel = ref.read(syncViewModelProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Sync queue')),
      body: lines.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => const Center(
          child: Text('The queue could not be read.'),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Nothing is waiting. Every change is on the server.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final line = items[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // One spoken item per card: title, kind and status together.
                      MergeSemantics(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              line.title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(line.kind),
                            Text(line.status),
                          ],
                        ),
                      ),
                      OverflowBar(
                        children: [
                          TextButton(
                            onPressed: () => _retry(context, viewModel, line),
                            child: Text(
                              line.isConflict ? 'Keep mine' : 'Retry now',
                              semanticsLabel: line.isConflict
                                  ? 'Keep my change to ${line.title}'
                                  : 'Retry sending ${line.title}',
                            ),
                          ),
                          TextButton(
                            onPressed: () => viewModel.discard(line.row),
                            child: Text(
                              line.isConflict ? 'Take theirs' : 'Discard',
                              semanticsLabel: line.isConflict
                                  ? 'Take the server version of ${line.title}'
                                  : 'Discard change to ${line.title}',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../problem_messages.dart';

/// The progress bar and the "could not refresh" line for any refresh provider.
/// Both watch only the one value they draw (`select`), so the list below does not rebuild
/// when a refresh starts or ends.
class RefreshStatus extends ConsumerWidget {
  const RefreshStatus({super.key, required this.refresh, required this.onRetry});

  final ProviderListenable<AsyncValue<void>> refresh;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loading = ref.watch(refresh.select((state) => state.isLoading));
    final error = ref.watch(
      refresh.select((state) => state.isLoading ? null : state.error),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (loading)
          const LinearProgressIndicator(semanticsLabel: 'Refreshing'),
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
                TextButton(onPressed: onRetry, child: const Text('Try again')),
              ],
            ),
          ),
      ],
    );
  }
}

/// The text shown when a list is empty. It says "loading" only while a refresh runs.
class EmptyMessage extends ConsumerWidget {
  const EmptyMessage({super.key, required this.refresh, required this.text});

  final ProviderListenable<AsyncValue<void>> refresh;
  final String text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loading = ref.watch(refresh.select((state) => state.isLoading));
    return Center(child: Text(loading ? 'Loading...' : text));
  }
}

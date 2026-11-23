import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';

/// Shows when the phone is offline or writes are still waiting. Hidden otherwise.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  static String _changes(int count) {
    return count == 1 ? '1 change' : '$count changes';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(onlineProvider).value ?? true;
    final pending = ref.watch(pendingCountProvider).value ?? 0;
    if (online && pending == 0) {
      return const SizedBox.shrink();
    }
    final String text;
    if (!online && pending == 0) {
      text = 'You are offline. Saved tasks are shown.';
    } else if (!online) {
      text = 'You are offline. ${_changes(pending)} not on the server yet.';
    } else {
      text = '${_changes(pending)} not on the server yet.';
    }
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        // Wrap instead of Row: at 200 percent text the buttons move to the next line.
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Only the message is a live region. The buttons are not read out on every change.
            Semantics(
              liveRegion: true,
              child: Text(
                text,
                style: TextStyle(color: scheme.onSecondaryContainer),
              ),
            ),
            if (online && pending > 0)
              TextButton(
                onPressed: () => ref.read(syncEngineProvider).drain(),
                child: const Text('Sync now'),
              ),
            TextButton(
              onPressed: () => context.push('/settings/sync'),
              child: const Text('Queue', semanticsLabel: 'Open the sync queue'),
            ),
          ],
        ),
      ),
    );
  }
}

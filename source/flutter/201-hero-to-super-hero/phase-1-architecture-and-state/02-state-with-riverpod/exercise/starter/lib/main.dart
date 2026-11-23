import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const ProviderScope(child: CounterApp()));
}

class CounterNotifier extends Notifier<int> {
  @override
  int build() => 0;

  // TODO 1: make increment() add one to state, and reset() set it back to 0
  void increment() {}

  void reset() {}
}

final counterProvider = NotifierProvider<CounterNotifier, int>(
  CounterNotifier.new,
);

// TODO 2: return true when the counter is even (use ref.watch(counterProvider))
final isEvenProvider = Provider<bool>((ref) => false);

class CounterApp extends StatelessWidget {
  const CounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Riverpod counter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const CounterScreen(),
    );
  }
}

class CounterScreen extends ConsumerWidget {
  const CounterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider);
    // TODO 3: also watch isEvenProvider and show 'even' or 'odd' under the number
    return Scaffold(
      appBar: AppBar(title: const Text('Riverpod counter')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$count', style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.read(counterProvider.notifier).increment(),
              child: const Text('Add one'),
            ),
            TextButton(
              onPressed: () => ref.read(counterProvider.notifier).reset(),
              child: const Text('Reset'),
            ),
          ],
        ),
      ),
    );
  }
}

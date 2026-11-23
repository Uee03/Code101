import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const StateLabApp());
}

class StateLabApp extends StatelessWidget {
  const StateLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'State lab',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const CounterScreen(),
    );
  }
}

class CounterScreen extends StatefulWidget {
  const CounterScreen({super.key});

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {
  int _count = 0;
  bool _showHint = true;

  void _increment() {
    setState(() {
      _count++;
    });
  }

  void _decrement() {
    if (_count > 0) {
      setState(() {
        _count--;
      });
    }
  }

  void _reset() {
    setState(() {
      _count = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('State lab')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Cups of tea today',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            CountDisplay(count: _count),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: _count > 0 ? _decrement : null,
                  child: const Text('-1'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _increment,
                  child: const Text('+1'),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: _reset,
                  child: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SwitchListTile(
                title: const Text('Show hint'),
                value: _showHint,
                onChanged: (value) {
                  setState(() {
                    _showHint = value;
                  });
                },
              ),
            ),
            if (_showHint) const Text('Tap +1 after every cup.'),
          ],
        ),
      ),
    );
  }
}

class CountDisplay extends StatelessWidget {
  const CountDisplay({super.key, required this.count});

  final int count;

  String get _message {
    if (count == 0) {
      return 'Start counting';
    } else if (count < 3) {
      return 'Nice and calm';
    } else {
      return 'Time for a break';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$count', style: Theme.of(context).textTheme.displayMedium),
        Text(_message),
      ],
    );
  }
}

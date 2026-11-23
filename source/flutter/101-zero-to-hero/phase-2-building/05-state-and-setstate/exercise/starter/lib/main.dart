import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const WaterApp());
}

class WaterApp extends StatelessWidget {
  const WaterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Water tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const WaterScreen(),
    );
  }
}

class WaterScreen extends StatefulWidget {
  const WaterScreen({super.key});

  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> {
  static const int goal = 8;
  int _glasses = 0;

  void _drink() {
    // TODO 1: increase _glasses by one inside setState
  }

  void _reset() {
    // TODO 2: set _glasses back to 0 inside setState
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Water tracker')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$_glasses of $goal glasses'),
            const SizedBox(height: 16),
            // TODO 3: add a LinearProgressIndicator whose value is _glasses divided by goal
            const SizedBox(height: 16),
            // TODO 4: show the text 'Goal reached!' only when _glasses is at least goal
            const SizedBox(height: 16),
            FilledButton(onPressed: _drink, child: const Text('Drink a glass')),
            TextButton(onPressed: _reset, child: const Text('Reset')),
          ],
        ),
      ),
    );
  }
}

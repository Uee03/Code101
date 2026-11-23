import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const MoodApp());
}

class MoodApp extends StatelessWidget {
  const MoodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mood picker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _mood = 'not chosen';

  Future<void> _pickMood() async {
    final mood = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (context) => const PickScreen()),
    );
    if (mood == null || !mounted) {
      return;
    }
    setState(() {
      _mood = mood;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mood picker')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Your mood: $_mood'),
            const SizedBox(height: 16),
            FilledButton(onPressed: _pickMood, child: const Text('Pick a mood')),
          ],
        ),
      ),
    );
  }
}

class PickScreen extends StatelessWidget {
  const PickScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const moods = ['happy', 'calm', 'tired'];
    return Scaffold(
      appBar: AppBar(title: const Text('How do you feel?')),
      body: ListView(
        children: [
          for (final mood in moods)
            ListTile(
              title: Text(mood),
              onTap: () => Navigator.of(context).pop(mood),
            ),
        ],
      ),
    );
  }
}

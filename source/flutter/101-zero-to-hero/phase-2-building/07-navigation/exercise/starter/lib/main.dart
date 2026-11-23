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
    // TODO 1: push a MaterialPageRoute that builds PickScreen and await the String? result
    // TODO 2: when the result is not null and the screen is still mounted,
    //         store it in _mood inside setState
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
              // TODO 3: close this screen and hand the mood back to the previous screen
              onTap: () {},
            ),
        ],
      ),
    );
  }
}

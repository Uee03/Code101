import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const VisitsApp());
}

class VisitsApp extends StatelessWidget {
  const VisitsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Visit counter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
      ),
      home: const VisitsScreen(),
    );
  }
}

class VisitsScreen extends StatefulWidget {
  const VisitsScreen({super.key});

  @override
  State<VisitsScreen> createState() => _VisitsScreenState();
}

class _VisitsScreenState extends State<VisitsScreen> {
  final _preferences = SharedPreferencesAsync();
  int? _visits;

  @override
  void initState() {
    super.initState();
    _countVisit();
  }

  Future<void> _countVisit() async {
    final previous = await _preferences.getInt('visits') ?? 0;
    final next = previous + 1;
    await _preferences.setInt('visits', next);
    if (!mounted) {
      return;
    }
    setState(() {
      _visits = next;
    });
  }

  Future<void> _reset() async {
    await _preferences.remove('visits');
    if (!mounted) {
      return;
    }
    setState(() {
      _visits = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Visit counter')),
      body: Center(
        child: _visits == null
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('You opened this app $_visits times'),
                  TextButton(onPressed: _reset, child: const Text('Reset')),
                ],
              ),
      ),
    );
  }
}

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
    // TODO 1: read the saved number with getInt('visits') (it can be null, use 0 then),
    //         add one, save it with setInt('visits', ...)
    // TODO 2: when the screen is still mounted, store the new number in _visits inside setState
  }

  Future<void> _reset() async {
    // TODO 3: remove the key 'visits', then (if mounted) set _visits to 0 inside setState
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

import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const ProfileApp());
}

class ProfileApp extends StatelessWidget {
  const ProfileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Adaptive profile',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const ProfileScreen(),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const tags = ['Flutter', 'Dart', 'Accessibility', 'Hiking', 'Tea'];
  int _likes = 0;

  void _like() {
    setState(() {
      _likes++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adaptive profile')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 600;
          final info = Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sam Lee', style: Theme.of(context).textTheme.headlineSmall),
                Text('Likes: $_likes'),
                // TODO 1: give this IconButton the tooltip 'Like this profile'
                IconButton(onPressed: _like, icon: const Text('+1')),
              ],
            ),
          );
          final skills = Padding(
            padding: const EdgeInsets.all(16),
            // TODO 2: this Row of fixed-width boxes overflows on narrow screens;
            //         replace it with a Wrap that has spacing 8 and runSpacing 8
            child: Row(
              children: [
                for (final tag in tags)
                  Container(
                    width: 120,
                    padding: const EdgeInsets.all(8),
                    child: Text(tag),
                  ),
              ],
            ),
          );
          // TODO 3: when wide is true show info and skills side by side in a Row,
          //         each in an Expanded; otherwise keep the Column
          return Column(children: [info, skills]);
        },
      ),
    );
  }
}

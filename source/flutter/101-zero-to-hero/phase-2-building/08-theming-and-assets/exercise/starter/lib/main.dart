import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const ThemeSwitcherApp());
}

class ThemeSwitcherApp extends StatefulWidget {
  const ThemeSwitcherApp({super.key});

  @override
  State<ThemeSwitcherApp> createState() => _ThemeSwitcherAppState();
}

class _ThemeSwitcherAppState extends State<ThemeSwitcherApp> {
  // TODO 1: add a bool field _dark that starts as false

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Theme switcher',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
      ),
      // TODO 2: use ThemeMode.dark when _dark is true, otherwise ThemeMode.light
      themeMode: ThemeMode.system,
      home: Scaffold(
        appBar: AppBar(title: const Text('Theme switcher')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Switch the theme below.'),
              // TODO 3: add a SwitchListTile titled 'Dark mode' whose value is _dark
              //         and whose onChanged stores the new value inside setState
            ],
          ),
        ),
      ),
    );
  }
}

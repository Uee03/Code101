import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const MyGreetingApp());
}

class MyGreetingApp extends StatelessWidget {
  const MyGreetingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Greeting',
      // TODO 2: change Colors.teal to another color, for example Colors.orange
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('My greeting')),
        // TODO 1: replace 'Hello, Flutter!' with a greeting that contains your own name
        body: const Center(child: Text('Hello, Flutter!')),
      ),
    );
  }
}

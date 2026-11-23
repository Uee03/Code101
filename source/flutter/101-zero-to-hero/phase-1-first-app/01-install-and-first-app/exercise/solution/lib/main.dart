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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('My greeting')),
        body: const Center(
          child: Text(
            'Hello, Sam!',
            style: TextStyle(fontSize: 32),
          ),
        ),
      ),
    );
  }
}

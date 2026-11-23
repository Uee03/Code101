import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const RecipeApp());
}

class RecipeApp extends StatelessWidget {
  const RecipeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recipe card',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('Recipe card')),
        body: const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TODO 1: add a Text with the dish name 'Pancakes' and a large bold style
              // TODO 2: add a SizedBox with height 8
              // TODO 3: add a Row with two Text widgets: 'Time: 20 min' and 'Serves: 4',
              //         spread apart with MainAxisAlignment.spaceBetween
            ],
          ),
        ),
      ),
    );
  }
}

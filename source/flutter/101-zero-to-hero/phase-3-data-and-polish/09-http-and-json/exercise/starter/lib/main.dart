import 'dart:convert';

import 'package:material_ui/material_ui.dart';

// A pretend server answer, so this exercise works without internet.
const String bookJson = '''
[
  {"id": 1, "title": "The Little Prince", "pages": 96, "read": true},
  {"id": 2, "title": "Dune", "pages": 612, "read": false},
  {"id": 3, "title": "Emma", "pages": 474, "read": false}
]
''';

class Book {
  const Book({
    required this.id,
    required this.title,
    required this.pages,
    required this.read,
  });

  // TODO 1: add a factory constructor Book.fromJson(Map<String, dynamic> json)
  //         that reads id, title, pages and read with the right casts

  final int id;
  final String title;
  final int pages;
  final bool read;
}

List<Book> parseBooks(String source) {
  // TODO 2: decode the text with jsonDecode, cast it to List<dynamic>
  //         and turn every entry into a Book
  return [];
}

void main() {
  runApp(const BookApp());
}

class BookApp extends StatelessWidget {
  const BookApp({super.key});

  @override
  Widget build(BuildContext context) {
    final books = parseBooks(bookJson);
    return MaterialApp(
      title: 'Books',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
      ),
      home: Scaffold(
        appBar: AppBar(title: Text('Books (${books.length})')),
        body: ListView(
          children: [
            for (final book in books)
              ListTile(
                title: Text(book.title),
                // TODO 3: show '<pages> pages, read' or '<pages> pages, not read yet'
                subtitle: const Text(''),
              ),
          ],
        ),
      ),
    );
  }
}

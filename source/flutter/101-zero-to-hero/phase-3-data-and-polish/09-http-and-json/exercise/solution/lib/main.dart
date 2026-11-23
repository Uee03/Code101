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

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as int,
      title: json['title'] as String,
      pages: json['pages'] as int,
      read: json['read'] as bool,
    );
  }

  final int id;
  final String title;
  final int pages;
  final bool read;
}

List<Book> parseBooks(String source) {
  final data = jsonDecode(source) as List<dynamic>;
  return [
    for (final entry in data) Book.fromJson(entry as Map<String, dynamic>),
  ];
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
                subtitle: Text(
                  book.read
                      ? '${book.pages} pages, read'
                      : '${book.pages} pages, not read yet',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

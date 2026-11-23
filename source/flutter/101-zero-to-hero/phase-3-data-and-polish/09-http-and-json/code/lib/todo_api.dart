import 'dart:convert';

import 'package:http/http.dart' as http;

import 'todo.dart';

class TodoApiException implements Exception {
  const TodoApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class TodoApi {
  TodoApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<Todo>> fetchTodos({int limit = 10}) async {
    final uri = Uri.https(
      'jsonplaceholder.typicode.com',
      '/todos',
      {'_limit': '$limit'},
    );
    final response = await _client.get(uri).timeout(
          const Duration(seconds: 10),
        );
    if (response.statusCode != 200) {
      throw TodoApiException('The server answered ${response.statusCode}.');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return [
      for (final entry in data) Todo.fromJson(entry as Map<String, dynamic>),
    ];
  }

  void close() => _client.close();
}

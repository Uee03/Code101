import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'task.dart';

class TaskStore {
  TaskStore({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  static const _key = 'tasks_v1';

  final SharedPreferencesAsync _preferences;

  Future<List<Task>> load() async {
    final raw = await _preferences.getString(_key);
    if (raw == null) {
      return [];
    }
    try {
      final data = jsonDecode(raw) as List<dynamic>;
      return [
        for (final entry in data) Task.fromJson(entry as Map<String, dynamic>),
      ];
    } on FormatException {
      return [];
    } on TypeError {
      return [];
    }
  }

  Future<void> save(List<Task> tasks) async {
    final raw = jsonEncode([for (final task in tasks) task.toJson()]);
    await _preferences.setString(_key, raw);
  }
}

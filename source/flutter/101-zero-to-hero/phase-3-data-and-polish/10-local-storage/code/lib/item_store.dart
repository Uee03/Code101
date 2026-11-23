import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'shopping_item.dart';

class ItemStore {
  ItemStore({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  static const _key = 'shopping_items';

  final SharedPreferencesAsync _preferences;

  Future<List<ShoppingItem>> load() async {
    final raw = await _preferences.getString(_key);
    if (raw == null) {
      return [];
    }
    try {
      final data = jsonDecode(raw) as List<dynamic>;
      return [
        for (final entry in data)
          ShoppingItem.fromJson(entry as Map<String, dynamic>),
      ];
    } on FormatException {
      return [];
    } on TypeError {
      return [];
    }
  }

  Future<void> save(List<ShoppingItem> items) async {
    final raw = jsonEncode([for (final item in items) item.toJson()]);
    await _preferences.setString(_key, raw);
  }
}

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/session.dart';

/// The only class that imports the secure storage package.
class TokenStore {
  const TokenStore();

  static const _key = 'session.v1';
  final _storage = const FlutterSecureStorage();

  Future<Session?> read() async {
    final value = await _storage.read(key: _key);
    if (value == null) {
      return null;
    }
    try {
      return Session.fromJson(jsonDecode(value) as Map<String, dynamic>);
    } on FormatException {
      await clear();
      return null;
    } on TypeError {
      await clear();
      return null;
    }
  }

  Future<void> write(Session session) {
    return _storage.write(key: _key, value: jsonEncode(session.toJson()));
  }

  Future<void> clear() => _storage.delete(key: _key);
}

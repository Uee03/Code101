import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import '../models/session.dart';

final class TokenStore {
  final _storage = const FlutterSecureStorage(aOptions: AndroidOptions());
  static const _key = 'session.v1';
  Future<Session?> read() async {
    final value = await _storage.read(key: _key);
    return value == null ? null : Session.fromJson(jsonDecode(value) as Map<String, dynamic>);
  }
  Future<void> write(Session session) =>
      _storage.write(key: _key, value: jsonEncode(session.toJson()));
  Future<void> clear() => _storage.delete(key: _key);

  // A file lock also serializes refresh across the WorkManager isolate.
  // The file contains no tokens. Read secure storage again inside the lock.
  Future<T> exclusive<T>(Future<T> Function() action) async {
    final folder = await getApplicationSupportDirectory();
    await folder.create(recursive: true);
    final file = await File('${folder.path}/auth.lock').open(mode: FileMode.append);
    try {
      await file.lock(FileLock.blockingExclusive);
      return await action();
    } finally {
      await file.unlock();
      await file.close();
    }
  }
}

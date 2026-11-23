import 'dart:async';
import '../models/session.dart';
import '../services/auth_service.dart';
import '../services/token_store.dart';

final class AuthExpired implements Exception {
  const AuthExpired();
}

final class AuthRepository {
  AuthRepository(this._service, this._store);
  final AuthService _service;
  final TokenStore _store;
  final _changes = StreamController<bool?>.broadcast();
  Stream<bool?> get changes => _changes.stream;
  bool? signedIn;
  String intendedRoute = '/teams';
  Future<Session>? _refreshing;
  void _notify(bool value) {
    signedIn = value;
    _changes.add(value);
  }
  Future<void> Function(String)? acceptSubject;
  Future<void> restore() async {
    final session = await _store.read();
    if (session != null) {
      try { await acceptSubject?.call(session.subject); } catch (_) { _notify(false); return; }
    }
    _notify(session != null);
  }
  Future<void> signIn() async {
    final value = await _service.signIn();
    if (value == null) return;
    await acceptSubject?.call(value.subject);
    await _store.exclusive(() => _store.write(value));
    _notify(true);
  }
  Future<Session> _refresh({String? rejected}) async {
    try {
      return await _store.exclusive(() async {
        final old = await _store.read();
        if (old == null) throw const AuthExpired();
        if (rejected != null && old.access != rejected) return old;
        if (rejected == null && old.expires.isAfter(DateTime.now().add(const Duration(seconds: 60)))) return old;
        final next = await _service.refresh(old);
        await _store.write(next); // Persist rotation before exposing the new token.
        return next;
      });
    } on AuthUnavailable {
      rethrow; // An unreachable issuer is not a revoked session. Keep cached screens open.
    } catch (_) {
      _notify(false); // A rejected refresh keeps the cache and queue.
      throw const AuthExpired();
    }
  }
  Future<String> accessToken({String? rejected}) async {
    final pending = _refreshing;
    if (pending != null) return (await pending).access;
    final job = _refresh(rejected: rejected);
    _refreshing = job;
    try {
      return (await job).access;
    } finally {
      _refreshing = null;
    }
  }
  Future<void> signOut() async {
    await _store.exclusive(() async {
      final session = await _store.read();
      if (session != null) await _service.signOut(session);
      await _store.clear(); // Browser logout must succeed before claiming logout.
    });
    intendedRoute = '/teams';
    intendedRoute = '/teams';
    _notify(false);
  }
  Future<void> dispose() => _changes.close();
}

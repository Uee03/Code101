import '../../core/auth_errors.dart';
import '../models/session.dart';
import '../services/auth_service.dart';
import '../services/token_store.dart';

class AuthRepository {
  AuthRepository(this._service, this._store);

  final AuthService _service;
  final TokenStore _store;

  Session? _session;
  Future<Session>? _refreshing;

  Future<bool> restore() async {
    _session = await _store.read();
    return _session != null;
  }

  /// Returns false when the user cancelled in the browser.
  Future<bool> signIn() async {
    final session = await _service.signIn();
    if (session == null) {
      return false;
    }
    await _store.write(session);
    _session = session;
    return true;
  }

  Future<void> signOut() async {
    final session = _session;
    try {
      if (session != null) {
        await _service.signOut(session);
      }
    } on Exception {
      // The browser step failed or was cancelled. We still forget the tokens below.
    } finally {
      _session = null;
      await _store.clear();
    }
  }

  /// A token that is valid now. All callers share one refresh.
  /// [rejected] is a token the API just refused with 401.
  Future<String> accessToken({String? rejected}) async {
    final session = _session;
    if (session == null) {
      throw const AuthExpired();
    }
    final refused = rejected != null && rejected == session.accessToken;
    if (!session.expiresSoon && !refused) {
      return session.accessToken;
    }
    final refreshed = await (_refreshing ??=
        _refresh(session).whenComplete(() => _refreshing = null));
    return refreshed.accessToken;
  }

  Future<Session> _refresh(Session old) async {
    try {
      final fresh = await _service.refresh(old);
      // Rotation: the old refresh token is now useless, so save the new one first.
      await _store.write(fresh);
      _session = fresh;
      return fresh;
    } on AuthRejected {
      _session = null;
      await _store.clear();
      throw const AuthExpired();
    }
  }
}

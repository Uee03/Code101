import 'package:flutter/foundation.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import '../../core/config.dart';
import '../../core/url_policy.dart';
import '../models/session.dart';

final class AuthService {
  final _appAuth = const FlutterAppAuth();
  AuthService() {
    UrlPolicy.validate(Config.issuer, debug: kDebugMode);
  }
  Session _session(TokenResponse result, [Session? old]) {
    final access = result.accessToken;
    final refresh = result.refreshToken ?? old?.refresh;
    final id = result.idToken ?? old?.idToken;
    final expires = result.accessTokenExpirationDateTime;
    if (access == null || refresh == null || id == null || expires == null) {
      throw StateError('incomplete_session');
    }
    return Session(access, refresh, id, expires);
  }
  Future<Session?> signIn() async {
    try {
      return _session(await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(Config.clientId, Config.redirect,
          issuer: Config.issuer, scopes: Config.scopes,
          allowInsecureConnections: kDebugMode),
      ));
    } on FlutterAppAuthUserCancelledException {
      return null;
    }
  }
  Future<Session> refresh(Session old) async {
    try {
      return _session(await _appAuth.token(TokenRequest(Config.clientId, Config.redirect,
        issuer: Config.issuer, refreshToken: old.refresh,
        scopes: Config.scopes, allowInsecureConnections: kDebugMode)), old);
    } on FlutterAppAuthPlatformException catch (error) {
      if (const ['invalid_grant','invalid_client','unauthorized_client','invalid_scope']
          .contains(error.platformErrorDetails.error)) { rethrow; }
      throw const AuthUnavailable();
    }
  }
  Future<void> signOut(Session old) async {
    await _appAuth.endSession(EndSessionRequest(
      issuer: Config.issuer, idTokenHint: old.idToken,
      postLogoutRedirectUrl: Config.logout,
      allowInsecureConnections: kDebugMode,
    ));
  }
}

final class AuthUnavailable implements Exception { const AuthUnavailable(); }

import 'package:flutter/foundation.dart';
import 'package:flutter_appauth/flutter_appauth.dart';

import '../../core/auth_errors.dart';
import '../../core/config.dart';
import '../../core/url_policy.dart';
import '../models/session.dart';

/// Wraps AppAuth: system browser, authorization code flow with PKCE (S256).
class AuthService {
  AuthService() {
    UrlPolicy.validate(Config.issuer, debug: kDebugMode);
  }

  final _appAuth = const FlutterAppAuth();

  static const _rejections = [
    'invalid_grant',
    'invalid_client',
    'unauthorized_client',
    'invalid_scope',
  ];

  /// Returns null when the user closes the browser without signing in.
  Future<Session?> signIn() async {
    try {
      final result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          Config.clientId,
          Config.redirect,
          issuer: Config.issuer,
          scopes: Config.scopes,
          allowInsecureConnections: kDebugMode,
        ),
      );
      return _toSession(result);
    } on FlutterAppAuthUserCancelledException {
      return null;
    }
  }

  Future<Session> refresh(Session old) async {
    try {
      final result = await _appAuth.token(
        TokenRequest(
          Config.clientId,
          Config.redirect,
          issuer: Config.issuer,
          refreshToken: old.refreshToken,
          scopes: Config.scopes,
          allowInsecureConnections: kDebugMode,
        ),
      );
      return _toSession(result, old);
    } on FlutterAppAuthPlatformException catch (error) {
      if (_rejections.contains(error.platformErrorDetails.error)) {
        throw const AuthRejected();
      }
      throw const AuthUnavailable();
    }
  }

  /// Ends the session at the identity provider in the browser.
  Future<void> signOut(Session session) async {
    await _appAuth.endSession(
      EndSessionRequest(
        issuer: Config.issuer,
        idTokenHint: session.idToken,
        postLogoutRedirectUrl: Config.logout,
        allowInsecureConnections: kDebugMode,
      ),
    );
  }

  Session _toSession(TokenResponse result, [Session? old]) {
    final access = result.accessToken;
    final refresh = result.refreshToken ?? old?.refreshToken;
    final id = result.idToken ?? old?.idToken;
    final expires = result.accessTokenExpirationDateTime;
    if (access == null || refresh == null || id == null || expires == null) {
      throw StateError('The identity provider sent an incomplete answer.');
    }
    return Session(
      accessToken: access,
      refreshToken: refresh,
      idToken: id,
      expiresAt: expires,
    );
  }
}

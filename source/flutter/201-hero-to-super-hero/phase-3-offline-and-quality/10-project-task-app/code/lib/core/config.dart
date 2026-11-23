abstract final class Config {
  static const apiBase = String.fromEnvironment('API_BASE_URL');

  static const issuer = String.fromEnvironment('OIDC_ISSUER');
  static const clientId = String.fromEnvironment('OIDC_CLIENT_ID');
  static const redirect = String.fromEnvironment('OIDC_REDIRECT_URI');
  static const logout = String.fromEnvironment('OIDC_LOGOUT_URI');

  // The only place that lists the scopes. No admin scope, no client secret.
  static const scopes = [
    'openid',
    'profile',
    'email',
    'offline_access',
    'tasks:read',
    'tasks:write',
  ];

  /// Debug aid: `--dart-define=TEXT_SCALE=2` draws the whole app with 200 percent text.
  /// It is ignored in profile and release builds.
  static const textScale = double.fromEnvironment(
    'TEXT_SCALE',
    defaultValue: 1,
  );
}

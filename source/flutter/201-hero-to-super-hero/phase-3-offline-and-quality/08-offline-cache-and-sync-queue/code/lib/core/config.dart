abstract final class Config {
  static const apiBase = String.fromEnvironment('API_BASE_URL');
  static const devProjectId = String.fromEnvironment('DEV_PROJECT_ID');

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
}

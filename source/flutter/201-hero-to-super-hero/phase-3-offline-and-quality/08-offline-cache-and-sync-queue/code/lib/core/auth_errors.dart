/// The session is over: there is no usable token and no way to get one.
class AuthExpired implements Exception {
  const AuthExpired();
}

/// The identity provider refused the refresh token (for example invalid_grant).
class AuthRejected implements Exception {
  const AuthRejected();
}

/// The identity provider could not be reached; the session may still be fine.
class AuthUnavailable implements Exception {
  const AuthUnavailable();
}

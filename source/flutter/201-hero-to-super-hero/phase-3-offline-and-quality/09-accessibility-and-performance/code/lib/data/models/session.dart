class Session {
  const Session({
    required this.accessToken,
    required this.refreshToken,
    required this.idToken,
    required this.expiresAt,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      idToken: json['idToken'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }

  final String accessToken;
  final String refreshToken;
  final String idToken;
  final DateTime expiresAt;

  /// True in the last 60 seconds before expiry, so we refresh before the server says 401.
  bool get expiresSoon {
    return DateTime.now().isAfter(expiresAt.subtract(const Duration(seconds: 60)));
  }

  Map<String, Object?> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'idToken': idToken,
      'expiresAt': expiresAt.toUtc().toIso8601String(),
    };
  }

  /// Never print tokens: this keeps them out of logs and error texts.
  @override
  String toString() => 'Session(expiresAt: $expiresAt)';
}

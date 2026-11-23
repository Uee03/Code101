import 'dart:convert';

final class Session {
  const Session(this.access, this.refresh, this.idToken, this.expires);
  final String access;
  final String refresh;
  final String idToken;
  final DateTime expires;
  String get subject {
    final payload = idToken.split('.')[1];
    final claims = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(payload)))) as Map;
    return claims['sub'] as String;
  }
  Map<String, Object?> toJson() => {
    'access': access, 'refresh': refresh, 'id': idToken,
    'expires': expires.toUtc().toIso8601String(),
  };
  factory Session.fromJson(Map<String, dynamic> json) => Session(
    json['access'] as String, json['refresh'] as String,
    json['id'] as String, DateTime.parse(json['expires'] as String),
  );
}

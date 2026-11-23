// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'me.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Me _$MeFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'id',
      'username',
      'email',
      'displayName',
      'roles',
      'scopes',
      'teams',
    ],
    disallowNullValues: const [
      'id',
      'username',
      'email',
      'displayName',
      'roles',
      'scopes',
      'teams',
    ],
  );
  return Me(
    id: json['id'] as String,
    username: json['username'] as String,
    email: json['email'] as String,
    displayName: json['displayName'] as String,
    roles: Me._read_roles(json['roles']),
    scopes: (json['scopes'] as List<dynamic>).map((e) => e as String).toList(),
    teams: (json['teams'] as List<dynamic>)
        .map((e) => MeTeamsItem.fromJson(e as Map<String, dynamic>))
        .toList(),
    additionalProperties: Me._extras(json, 'additionalProperties') == null
        ? const {}
        : Me._readExtras(Me._extras(json, 'additionalProperties')),
  );
}

Map<String, dynamic> _$MeToJson(Me instance) => <String, dynamic>{
  'id': instance.id,
  'username': instance.username,
  'email': instance.email,
  'displayName': instance.displayName,
  'roles': ?Me._write_roles(instance.roles),
  'scopes': instance.scopes,
  'teams': instance.teams.map((e) => e.toJson()).toList(),
};

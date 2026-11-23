// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Member _$MemberFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'userId',
      'username',
      'displayName',
      'role',
      'joinedAt',
    ],
    disallowNullValues: const [
      'userId',
      'username',
      'displayName',
      'role',
      'joinedAt',
    ],
  );
  return Member(
    userId: json['userId'] as String,
    username: json['username'] as String,
    displayName: json['displayName'] as String,
    role: Member._read_role(json['role']),
    joinedAt: Member._read_joinedAt(json['joinedAt']),
    additionalProperties: Member._extras(json, 'additionalProperties') == null
        ? const {}
        : Member._readExtras(Member._extras(json, 'additionalProperties')),
  );
}

Map<String, dynamic> _$MemberToJson(Member instance) => <String, dynamic>{
  'userId': instance.userId,
  'username': instance.username,
  'displayName': instance.displayName,
  'role': ?Member._write_role(instance.role),
  'joinedAt': ?Member._write_joinedAt(instance.joinedAt),
};

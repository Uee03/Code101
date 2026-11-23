// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Team$Response _$Team$ResponseFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'id',
      'name',
      'description',
      'memberCount',
      'createdBy',
      'version',
      'createdAt',
      'updatedAt',
    ],
    disallowNullValues: const [
      'id',
      'name',
      'description',
      'memberCount',
      'createdBy',
      'version',
      'createdAt',
      'updatedAt',
    ],
  );
  return Team$Response(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    memberCount: Team$Response._read_memberCount(json['memberCount']),
    createdBy: json['createdBy'] as String,
    version: Team$Response._read_version(json['version']),
    createdAt: Team$Response._read_createdAt(json['createdAt']),
    updatedAt: Team$Response._read_updatedAt(json['updatedAt']),
    additionalProperties:
        Team$Response._extras(json, 'additionalProperties') == null
        ? const {}
        : Team$Response._readExtras(
            Team$Response._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$Team$ResponseToJson(Team$Response instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'memberCount': ?Team$Response._write_memberCount(instance.memberCount),
      'createdBy': instance.createdBy,
      'version': ?Team$Response._write_version(instance.version),
      'createdAt': ?Team$Response._write_createdAt(instance.createdAt),
      'updatedAt': ?Team$Response._write_updatedAt(instance.updatedAt),
    };

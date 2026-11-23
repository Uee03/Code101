// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Project$Response _$Project$ResponseFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'id',
      'teamId',
      'key',
      'name',
      'description',
      'archived',
      'version',
      'createdAt',
      'updatedAt',
    ],
    disallowNullValues: const [
      'id',
      'teamId',
      'key',
      'name',
      'description',
      'archived',
      'version',
      'createdAt',
      'updatedAt',
    ],
  );
  return Project$Response(
    id: json['id'] as String,
    teamId: json['teamId'] as String,
    key: json['key'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    archived: json['archived'] as bool,
    version: Project$Response._read_version(json['version']),
    createdAt: Project$Response._read_createdAt(json['createdAt']),
    updatedAt: Project$Response._read_updatedAt(json['updatedAt']),
    additionalProperties:
        Project$Response._extras(json, 'additionalProperties') == null
        ? const {}
        : Project$Response._readExtras(
            Project$Response._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$Project$ResponseToJson(Project$Response instance) =>
    <String, dynamic>{
      'id': instance.id,
      'teamId': instance.teamId,
      'key': instance.key,
      'name': instance.name,
      'description': instance.description,
      'archived': instance.archived,
      'version': ?Project$Response._write_version(instance.version),
      'createdAt': ?Project$Response._write_createdAt(instance.createdAt),
      'updatedAt': ?Project$Response._write_updatedAt(instance.updatedAt),
    };

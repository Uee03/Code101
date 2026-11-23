// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_create.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProjectCreate _$ProjectCreateFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    allowedKeys: const ['key', 'name', 'description'],
    requiredKeys: const ['key', 'name'],
    disallowNullValues: const ['key', 'name', 'description'],
  );
  return ProjectCreate(
    key: json['key'] as String,
    name: json['name'] as String,
    description: ProjectCreate._presentValue(json, 'description') == null
        ? ""
        : ProjectCreate._read_description(
            ProjectCreate._presentValue(json, 'description') as Object,
          ),
  );
}

Map<String, dynamic> _$ProjectCreateToJson(ProjectCreate instance) =>
    <String, dynamic>{
      'key': instance.key,
      'name': instance.name,
      'description': ?ProjectCreate._write_description(instance.description),
    };

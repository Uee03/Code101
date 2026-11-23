// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Project$Request _$Project$RequestFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['key', 'name', 'description', 'archived'],
    disallowNullValues: const ['key', 'name', 'description', 'archived'],
  );
  return Project$Request(
    key: json['key'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    archived: json['archived'] as bool,
    additionalProperties:
        Project$Request._extras(json, 'additionalProperties') == null
        ? const {}
        : Project$Request._readExtras(
            Project$Request._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$Project$RequestToJson(Project$Request instance) =>
    <String, dynamic>{
      'key': instance.key,
      'name': instance.name,
      'description': instance.description,
      'archived': instance.archived,
    };

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_update.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProjectUpdate _$ProjectUpdateFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    allowedKeys: const ['name', 'description', 'archived'],
    disallowNullValues: const ['name', 'description', 'archived'],
  );
  return ProjectUpdate(
    name: json['name'] as String?,
    description: json['description'] as String?,
    archived: json['archived'] as bool?,
  );
}

Map<String, dynamic> _$ProjectUpdateToJson(ProjectUpdate instance) =>
    <String, dynamic>{
      'name': ?instance.name,
      'description': ?instance.description,
      'archived': ?instance.archived,
    };

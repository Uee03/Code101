// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_update.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TeamUpdate _$TeamUpdateFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    allowedKeys: const ['name', 'description'],
    disallowNullValues: const ['name', 'description'],
  );
  return TeamUpdate(
    name: json['name'] as String?,
    description: json['description'] as String?,
  );
}

Map<String, dynamic> _$TeamUpdateToJson(TeamUpdate instance) =>
    <String, dynamic>{
      'name': ?instance.name,
      'description': ?instance.description,
    };

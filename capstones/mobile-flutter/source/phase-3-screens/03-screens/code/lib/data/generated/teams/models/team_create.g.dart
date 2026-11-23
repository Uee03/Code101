// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_create.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TeamCreate _$TeamCreateFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    allowedKeys: const ['name', 'description', 'leadUserId'],
    requiredKeys: const ['name'],
    disallowNullValues: const ['name', 'description', 'leadUserId'],
  );
  return TeamCreate(
    name: json['name'] as String,
    description: TeamCreate._presentValue(json, 'description') == null
        ? ""
        : TeamCreate._read_description(
            TeamCreate._presentValue(json, 'description') as Object,
          ),
    leadUserId: json['leadUserId'] as String?,
  );
}

Map<String, dynamic> _$TeamCreateToJson(TeamCreate instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': ?TeamCreate._write_description(instance.description),
      'leadUserId': ?instance.leadUserId,
    };
